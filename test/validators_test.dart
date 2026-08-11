import 'package:flutter_test/flutter_test.dart';
import 'package:transporte_app/utils/validators.dart';

void main() {
  group('Validators - Email', () {
    test('Email válido retorna null', () {
      expect(Validators.validateEmail('test@example.com'), null);
      expect(Validators.validateEmail('usuario.nombre@dominio.cl'), null);
      expect(Validators.validateEmail('admin@empresa.com'), null);
    });

    test('Email inválido retorna mensaje de error', () {
      expect(Validators.validateEmail(''), isNotNull);
      expect(Validators.validateEmail('invalido'), isNotNull);
      expect(Validators.validateEmail('@dominio.com'), isNotNull);
      expect(Validators.validateEmail('usuario@'), isNotNull);
      expect(Validators.validateEmail('usuario@dominio'), isNotNull);
    });

    test('Email null retorna error', () {
      expect(Validators.validateEmail(null), 'El correo electrónico es requerido');
    });
  });

  group('Validators - Password', () {
    test('Password válido retorna null', () {
      expect(Validators.validatePassword('123456'), null);
      expect(Validators.validatePassword('password123'), null);
      expect(Validators.validatePassword('MiPassword!'), null);
    });

    test('Password muy corto retorna error', () {
      expect(Validators.validatePassword('12345'), 'La contraseña debe tener al menos 6 caracteres');
      expect(Validators.validatePassword('abc'), isNotNull);
    });

    test('Password vacío o null retorna error', () {
      expect(Validators.validatePassword(''), 'La contraseña es requerida');
      expect(Validators.validatePassword(null), 'La contraseña es requerida');
    });
  });

  group('Validators - Name', () {
    test('Nombre válido retorna null', () {
      expect(Validators.validateName('Juan Pérez'), null);
      expect(Validators.validateName('María'), null);
      expect(Validators.validateName('José Luis'), null);
    });

    test('Nombre muy corto retorna error', () {
      expect(Validators.validateName('A'), 'El nombre debe tener al menos 2 caracteres');
    });

    test('Nombre vacío o null retorna error', () {
      expect(Validators.validateName(''), 'El nombre es requerido');
      expect(Validators.validateName(null), 'El nombre es requerido');
    });
  });

  group('Validators - Number', () {
    test('Número válido retorna null', () {
      expect(Validators.validateNumber('100', 'Monto'), null);
      expect(Validators.validateNumber('50000', 'Valor'), null);
      expect(Validators.validateNumber('1', 'Cantidad'), null);
    });

    test('Número inválido retorna error', () {
      expect(Validators.validateNumber('abc', 'Monto'), 'Monto debe ser un número válido');
      expect(Validators.validateNumber('12.5.3', 'Precio'), isNotNull);
    });

    test('Número negativo o cero retorna error', () {
      expect(Validators.validateNumber('0', 'Valor'), 'Valor debe ser mayor a 0');
      expect(Validators.validateNumber('-100', 'Monto'), isNotNull);
    });

    test('Campo vacío o null retorna error', () {
      expect(Validators.validateNumber('', 'Monto'), 'Monto es requerido');
      expect(Validators.validateNumber(null, 'Valor'), 'Valor es requerido');
    });
  });

  group('Validators - Amount', () {
    test('Monto válido retorna null', () {
      expect(Validators.validateAmount('5000'), null);
      expect(Validators.validateAmount('100000'), null);
    });

    test('Monto inválido retorna error', () {
      expect(Validators.validateAmount('abc'), isNotNull);
      expect(Validators.validateAmount('0'), isNotNull);
      expect(Validators.validateAmount(''), isNotNull);
    });
  });

  group('Validators - Required', () {
    test('Campo con valor retorna null', () {
      expect(Validators.validateRequired('Texto', 'Campo'), null);
      expect(Validators.validateRequired('123', 'Número'), null);
    });

    test('Campo vacío retorna error', () {
      expect(Validators.validateRequired('', 'Campo'), 'Campo es requerido');
      expect(Validators.validateRequired('   ', 'Nombre'), isNotNull);
    });

    test('Campo null retorna error', () {
      expect(Validators.validateRequired(null, 'Campo'), 'Campo es requerido');
    });
  });
}
