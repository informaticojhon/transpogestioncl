import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class CurrencyFormatter {
  // Formateador para pesos chilenos (CLP)
  // Formato: $50.000 (con punto como separador de miles, sin decimales)
  static final NumberFormat _clpFormatter = NumberFormat.currency(
    locale: 'es_CL',
    symbol: '\$',
    decimalDigits: 0,
  );

  /// Formatea un valor numérico a formato CLP
  /// Ejemplo: 50000 -> $50.000
  static String formatCLP(dynamic value) {
    if (value == null) return '\$0';
    
    // Convertir a int si es necesario
    int amount;
    if (value is int) {
      amount = value;
    } else if (value is double) {
      amount = value.toInt();
    } else if (value is String) {
      amount = int.tryParse(value) ?? 0;
    } else {
      amount = 0;
    }
    
    return _clpFormatter.format(amount);
  }

  /// Convierte un string con formato CLP a int
  /// Ejemplo: "$50.000" -> 50000
  static int? parseCLP(String value) {
    // Remover símbolos y puntos
    final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');
    return int.tryParse(cleaned);
  }
}

/// TextInputFormatter para campos de entrada de valores CLP
/// Formatea automáticamente el valor mientras el usuario escribe
class CLPInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remover todo excepto números
    final numericValue = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    if (numericValue.isEmpty) {
      return const TextEditingValue(text: '');
    }

    // Convertir a número y formatear
    final intValue = int.tryParse(numericValue);
    if (intValue == null) {
      return oldValue;
    }

    // Formatear con puntos como separadores de miles
    final formatter = NumberFormat('#,###', 'es_CL');
    final formatted = formatter.format(intValue);

    // Mantener el cursor al final
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
