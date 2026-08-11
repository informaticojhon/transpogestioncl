import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:typed_data';
import '../services/api_service.dart';
import '../repositories/servicios_repository.dart';
import '../utils/currency_formatter.dart';

class ReporteDiarioScreen extends StatefulWidget {
  const ReporteDiarioScreen({super.key});

  @override
  State<ReporteDiarioScreen> createState() => _ReporteDiarioScreenState();
}

class _ReporteDiarioScreenState extends State<ReporteDiarioScreen> {
  final _serviciosRepository = ServiciosRepository();
  List serviciosDelDia = [];
  bool cargando = true;
  String? error;

  @override
  void initState() {
    super.initState();
    cargarServiciosDelDia();
  }

  Future<void> cargarServiciosDelDia() async {
    setState(() {
      cargando = true;
      error = null;
    });
    
    try {
      final hoy = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final delDia = await _serviciosRepository.obtenerServiciosPorFecha(hoy);
      
      if (mounted) {
        setState(() {
          serviciosDelDia = delDia;
          cargando = false;
        });
      }
    } on TokenExpiredException {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          error = 'Error al obtener servicios: ${e.toString()}';
          cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = 'Error de conexión. Verifica tu internet.';
          cargando = false;
        });
      }
    }
  }

  Future<void> generarPDF() async {
    final pdf = pw.Document();
    final fechaHoy = DateFormat("yyyy-MM-dd").format(DateTime.now());
    final fechaFormateada = DateFormat("d 'de' MMMM 'de' y", 'es_CL').format(DateTime.now());
    
    // Agrupar servicios por empresa
    final Map<String, List<dynamic>> serviciosPorEmpresa = {};
    final Map<String, int> totalesPorEmpresa = {};
    
    for (var servicio in serviciosDelDia) {
      final empresa = servicio['empresa'] ?? 'Sin empresa';
      if (!serviciosPorEmpresa.containsKey(empresa)) {
        serviciosPorEmpresa[empresa] = [];
        totalesPorEmpresa[empresa] = 0;
      }
      serviciosPorEmpresa[empresa]!.add(servicio);
      totalesPorEmpresa[empresa] = totalesPorEmpresa[empresa]! + (servicio['valor'] as int? ?? 0);
    }
    
    // Calcular totales generales
    final totalServicios = serviciosDelDia.length;
    final totalValor = serviciosDelDia.fold<int>(
      0,
      (sum, s) => sum + (s['valor'] as int? ?? 0),
    );

    // ==========================================
    // PÁGINA 1: RESUMEN GENERAL
    // ==========================================
    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Encabezado
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(width: 2),
                color: PdfColors.blue50,
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'REPORTE DIARIO DE SERVICIOS',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Fecha: $fechaFormateada',
                    style: pw.TextStyle(fontSize: 16),
                  ),
                  pw.Text(
                    'Hora de generación: ${DateFormat("HH:mm").format(DateTime.now())}',
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                  ),
                ],
              ),
            ),
            
            pw.SizedBox(height: 20),
            
            // Resumen General
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColors.green100,
                border: pw.Border.all(width: 2, color: PdfColors.green),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'RESUMEN GENERAL',
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Total de servicios:', style: pw.TextStyle(fontSize: 14)),
                      pw.Text(
                        '$totalServicios',
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 5),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Total empresas:', style: pw.TextStyle(fontSize: 14)),
                      pw.Text(
                        '${serviciosPorEmpresa.length}',
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 5),
                  pw.Divider(),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('TOTAL GENERAL:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      pw.Text(
                        CurrencyFormatter.formatCLP(totalValor),
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.green900),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            pw.SizedBox(height: 20),
            
            // Tabla resumen por empresa
            pw.Text(
              'Resumen por Empresa:',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              children: [
                // Encabezado de tabla
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue100),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Empresa', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Servicios', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                    ),
                  ],
                ),
                // Filas de datos
                ...serviciosPorEmpresa.entries.map((entry) {
                  final empresa = entry.key;
                  final servicios = entry.value;
                  final total = totalesPorEmpresa[empresa] ?? 0;
                  
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(empresa),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('${servicios.length}', textAlign: pw.TextAlign.center),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          CurrencyFormatter.formatCLP(total),
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
            
            pw.Spacer(),
            
            // Pie de página
            pw.Divider(),
            pw.Text(
              'TranspoGestionCL - Página 1 de ${serviciosPorEmpresa.length + 1}',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
      ),
    );
    
    // ==========================================
    // PÁGINAS SIGUIENTES: UNA POR CADA EMPRESA
    // ==========================================
    int paginaActual = 2;
    for (var empresaEntry in serviciosPorEmpresa.entries) {
      final empresa = empresaEntry.key;
      final servicios = empresaEntry.value;
      final totalEmpresa = totalesPorEmpresa[empresa] ?? 0;
      
      // Generar una página completa para esta empresa
      pdf.addPage(
        pw.MultiPage(
          build: (context) => [
            // Encabezado de empresa
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue100,
                border: pw.Border.all(width: 2, color: PdfColors.blue),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    empresa.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Reporte del $fechaFormateada',
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey800),
                  ),
                ],
              ),
            ),
            
            pw.SizedBox(height: 15),
            
            // Resumen de la empresa
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              color: PdfColors.grey200,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Total de servicios: ${servicios.length}',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    'Total: ${CurrencyFormatter.formatCLP(totalEmpresa)}',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green900,
                    ),
                  ),
                ],
              ),
            ),
            
            pw.SizedBox(height: 15),
            
            // Título de servicios
            pw.Text(
              'Detalle de Servicios:',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            
            // Lista de servicios
            ...servicios.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final s = entry.value;
              
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 10),
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  color: index % 2 == 0 ? PdfColors.white : PdfColors.grey50,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Servicio #$index',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        pw.Text(
                          CurrencyFormatter.formatCLP(s['valor'] ?? 0),
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 14,
                            color: PdfColors.blue900,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Realizado por: ${s['quien'] ?? 'N/A'}',
                      style: pw.TextStyle(fontSize: 11),
                    ),
                    pw.Text(
                      'Tipo de servicio: ${s['tipo'] ?? 'N/A'}',
                      style: pw.TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              );
            }),
            
            pw.SizedBox(height: 15),
            
            // Subtotal final de la empresa
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColors.green50,
                border: pw.Border.all(width: 2, color: PdfColors.green),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL $empresa:',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    CurrencyFormatter.formatCLP(totalEmpresa),
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green900,
                    ),
                  ),
                ],
              ),
            ),
          ],
          footer: (context) => pw.Column(
            children: [
              pw.Divider(),
              pw.Text(
                'TranspoGestionCL - $empresa - Página $paginaActual de ${serviciosPorEmpresa.length + 1}',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                textAlign: pw.TextAlign.center,
              ),
            ],
          ),
        ),
      );
      
      paginaActual++;
    }

    final bytes = await pdf.save();
    await Printing.sharePdf(bytes: bytes, filename: 'reporte_diario_$fechaHoy.pdf');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reporte Diario')),
      body: cargando
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 800),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 0.5 + (value * 0.5),
                        child: Opacity(
                          opacity: value,
                          child: child,
                        ),
                      );
                    },
                    child: const CircularProgressIndicator(strokeWidth: 3),
                  ),
                  const SizedBox(height: 16),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 1000),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: child,
                      );
                    },
                    child: const Text('Generando reporte...'),
                  ),
                ],
              ),
            )
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: cargarServiciosDelDia,
                        icon: Icon(Icons.refresh),
                        label: Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : serviciosDelDia.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No hay servicios registrados hoy',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            itemCount: serviciosDelDia.length,
                            itemBuilder: (context, index) {
                              final s = serviciosDelDia[index];
                              return TweenAnimationBuilder<double>(
                                duration: Duration(milliseconds: 300 + (index * 50)),
                                tween: Tween(begin: 0.0, end: 1.0),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, child) {
                                  return Transform.translate(
                                    offset: Offset(0, 20 * (1 - value)),
                                    child: Opacity(
                                      opacity: value,
                                      child: child,
                                    ),
                                  );
                                },
                                child: Card(
                                  margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      child: Icon(
                                        s['tipo'] == 'Pasaje'
                                            ? Icons.confirmation_number
                                            : Icons.local_shipping,
                                      ),
                                    ),
                                    title: Text(
                                      CurrencyFormatter.formatCLP(s['valor'] ?? 0),
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(
                                      'Realizado por: ${s['quien'] ?? 'N/A'}\n'
                                      'Empresa: ${s['empresa'] ?? 'N/A'}\n'
                                      'Tipo de servicio: ${s['tipo'] ?? 'N/A'}',
                                    ),
                                    isThreeLine: true,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: ElevatedButton.icon(
                            onPressed: generarPDF,
                            icon: const Icon(Icons.picture_as_pdf),
                            label: const Text('Generar PDF'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                        )
                      ],
                    ),
    );
  }
}
