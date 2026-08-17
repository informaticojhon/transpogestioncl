import 'package:flutter/material.dart';

/// Paleta categórica fija para identificar empresas cliente en toda la
/// app (chips de filtro, indicadores en listas). Se asigna por hash del
/// nombre: la misma empresa siempre obtiene el mismo color, sin
/// necesidad de guardar nada en la base de datos.
const List<Color> _paletaEmpresas = [
  Color(0xFF2563EB), // azul
  Color(0xFF16A34A), // verde
  Color(0xFFD97706), // ámbar
  Color(0xFFDC2626), // rojo
  Color(0xFF7C3AED), // violeta
  Color(0xFF0891B2), // cian
  Color(0xFFDB2777), // rosa
  Color(0xFF65A30D), // lima
];

Color colorParaEmpresaCliente(String? nombre) {
  final texto = nombre?.trim() ?? '';
  if (texto.isEmpty) return Colors.grey;
  final hash = texto.toLowerCase().codeUnits.fold<int>(0, (acc, c) => acc + c);
  return _paletaEmpresas[hash % _paletaEmpresas.length];
}
