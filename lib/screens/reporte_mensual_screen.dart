import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:typed_data';
import '../services/api_service.dart';
import '../repositories/servicios_repository.dart';
import '../utils/currency_formatter.dart';
import 'registro_servicio_screen.dart';

class ReporteMensualScreen extends StatefulWidget {
  const ReporteMensualScreen({super.key});

  @override
  State<ReporteMensualScreen> createState() => _ReporteMensualScreenState();
}

class _ReporteMensualScreenState extends State<ReporteMensualScreen> {
  final _serviciosRepository = ServiciosRepository();
  List serviciosDelMes = [];
  bool cargando = false;
  String? error;
  DateTime mesSeleccionado = DateTime.now();

  @override
  void initState() {
    super.initState();
    cargarServiciosDelMes();
  }

  Future<void> cargarServiciosDelMes() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final primerDia = DateTime(mesSeleccionado.year, mesSeleccionado.month, 1);
      final ultimoDia = DateTime(mesSeleccionado.year, mesSeleccionado.month + 1, 0);
      final formato = DateFormat('yyyy-MM-dd');

      final servicios = await _serviciosRepository.obtenerServiciosPorRangoFecha(
        formato.format(primerDia),
        formato.format(ultimoDia),
      );

      setState(() {
        serviciosDelMes = servicios;
        cargando = false;
      });
    } on TokenExpiredException {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } on ApiException catch (e) {
      setState(() {
        error = 'Error al obtener servicios: ${e.toString()}';
        cargando = false;
      });
    } catch (e) {
      setState(() {
        error = 'Error de conexión. Verifica tu internet.';
        cargando = false;
      });
    }
  }

  Future<void> seleccionarMes(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: mesSeleccionado,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('es', 'CL'),
      helpText: 'Selecciona una fecha del mes',
    );
    if (picked != null) {
      setState(() => mesSeleccionado = picked);
      cargarServiciosDelMes();
    }
  }

  Future<void> generarPDF() async {
    final pdf = pw.Document();
    final titulo = DateFormat("MMMM 'de' y", 'es_CL').format(mesSeleccionado);
    
    // Agrupar servicios por empresa
    final Map<String, List<dynamic>> serviciosPorEmpresa = {};
    final Map<String, int> totalesPorEmpresa = {};
    
    for (var servicio in serviciosDelMes) {
      final empresa = servicio['empresa'] ?? 'Sin empresa';
      if (!serviciosPorEmpresa.containsKey(empresa)) {
        serviciosPorEmpresa[empresa] = [];
        totalesPorEmpresa[empresa] = 0;
      }
      serviciosPorEmpresa[empresa]!.add(servicio);
      totalesPorEmpresa[empresa] = totalesPorEmpresa[empresa]! + (servicio['valor'] as int? ?? 0);
    }
    
    // Calcular totales generales
    final totalServicios = serviciosDelMes.length;
    final totalValor = serviciosDelMes.fold<int>(
      0, 
      (sum, s) => sum + (s['valor'] as int? ?? 0)
    );

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
            // Encabezado
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(width: 2),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'REPORTE MENSUAL DE SERVICIOS',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Mes: $titulo',
                    style: pw.TextStyle(fontSize: 16),
                  ),
                  pw.Text(
                    'Fecha de generación: ${DateFormat("dd/MM/yyyy HH:mm").format(DateTime.now())}',
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                  ),
                ],
              ),
            ),
            
            pw.SizedBox(height: 20),
            
            // Resumen
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              color: PdfColors.grey300,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Total Servicios: $totalServicios',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    'Total: ${CurrencyFormatter.formatCLP(totalValor)}',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ),
            
            pw.SizedBox(height: 20),
            
            // Servicios agrupados por empresa
            pw.Text(
              'Detalle de Servicios por Empresa:',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            
            ...serviciosPorEmpresa.entries.map((empresaEntry) {
              final empresa = empresaEntry.key;
              final servicios = empresaEntry.value;
              final totalEmpresa = totalesPorEmpresa[empresa] ?? 0;
              
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Encabezado de empresa
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(8),
                    color: PdfColors.blue100,
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          empresa,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          '${servicios.length} servicio${servicios.length != 1 ? 's' : ''}',
                          style: pw.TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  
                  // Servicios de esta empresa
                  ...servicios.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final s = entry.value;
                    final fecha = DateTime.parse(s['fecha']);
                    
                    return pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 8, left: 10, right: 10, top: 8),
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey400),
                        color: PdfColors.grey50,
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                'Servicio #$index - ${DateFormat("dd/MM/yyyy").format(fecha)}',
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
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
                          pw.SizedBox(height: 4),
                          pw.Text('Realizado por: ${s['quien'] ?? 'N/A'}'),
                          pw.Text('Tipo de servicio: ${s['tipo'] ?? 'N/A'}'),
                        ],
                      ),
                    );
                  }),
                  
                  // Subtotal de empresa
                  pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 15, left: 10, right: 10),
                    padding: const pw.EdgeInsets.all(8),
                    color: PdfColors.blue50,
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Subtotal $empresa:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          CurrencyFormatter.formatCLP(totalEmpresa),
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
        ],
        footer: (context) => pw.Column(
          children: [
            pw.Divider(),
            pw.Text(
              'TranspoGestionCL - Sistema de Gestión de Transporte - Página ${context.pageNumber} de ${context.pagesCount}',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          ],
        ),
      ),
    );

    final nombreArchivo = 'reporte_mensual_${DateFormat('yyyy-MM').format(mesSeleccionado)}.pdf';
    final bytes = await pdf.save();
    await guardarYCompartirPDF(bytes, nombreArchivo);
  }

  Future<void> guardarYCompartirPDF(Uint8List pdfBytes, String nombreArchivo) async {
    await Printing.sharePdf(bytes: pdfBytes, filename: nombreArchivo);
  }

  @override
  Widget build(BuildContext context) {
    final mesLabel = DateFormat("MMMM 'de' y", 'es_CL').format(mesSeleccionado);

    return Scaffold(
      appBar: AppBar(title: const Text('Reporte Mensual')),
      body: Center(
        child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text('Mes seleccionado: $mesLabel'),
                const Spacer(),
                TextButton(
                  onPressed: () => seleccionarMes(context),
                  child: const Text('Cambiar'),
                ),
              ],
            ),
          ),
          if (cargando)
            const Center(child: CircularProgressIndicator())
          else if (error != null)
            Center(child: Text(error!, style: const TextStyle(color: Colors.red)))
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: serviciosDelMes.length,
                itemBuilder: (context, index) {
                  final s = serviciosDelMes[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(CurrencyFormatter.formatCLP(s['valor'] ?? 0)),
                      subtitle: Text('Realizado por: ${s['quien'] ?? 'N/A'}'),
                      trailing: const Icon(Icons.edit, size: 20),
                      onTap: () async {
                        final recargar = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RegistroServicioScreen(servicioEditar: s),
                          ),
                        );
                        if (recargar == true) {
                          cargarServiciosDelMes();
                        }
                      },
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
            ),
          )
        ],
        ),
        ),
      ),
    );
  }
}
