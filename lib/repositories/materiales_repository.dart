import '../main.dart';
import '../models/material_item.dart';
import '../models/movimiento_material.dart';
import 'supabase_repository.dart';

class MaterialesRepository {
  static final MaterialesRepository _instance = MaterialesRepository._internal();
  factory MaterialesRepository() => _instance;
  MaterialesRepository._internal();

  final _supabaseRepo = SupabaseRepository();

  String? _getCurrentUserId() {
    return supabase.auth.currentUser?.id;
  }

  Future<String> _getEmpresaId() async {
    final empresaId = await _supabaseRepo.getEmpresaId();
    if (empresaId == null) throw Exception('Usuario no autenticado');
    return empresaId;
  }

  // ============ MATERIALES ============

  Future<List<MaterialItem>> getMateriales({bool soloActivos = false}) async {
    final empresaId = await _getEmpresaId();

    var query = supabase
        .from('materiales')
        .select()
        .eq('empresa_id', empresaId);

    if (soloActivos) {
      query = query.eq('activo', true);
    }

    final response = await query.order('nombre', ascending: true);
    return (response as List).map((json) => MaterialItem.fromJson(json)).toList();
  }

  /// Stock actual de todos los materiales de la empresa, calculado en el
  /// servidor en una sola consulta (evita una consulta de movimientos por
  /// cada material al mostrar la lista completa).
  Future<Map<int, int>> getStockDeTodos() async {
    final response = await supabase.rpc('stock_materiales_empresa');
    final filas = response as List;
    return {
      for (final fila in filas) (fila['material_id'] as num).toInt(): (fila['stock_actual'] as num).toInt(),
    };
  }

  Future<MaterialItem?> getMaterial(int id) async {
    final empresaId = await _getEmpresaId();

    final response = await supabase
        .from('materiales')
        .select()
        .eq('id', id)
        .eq('empresa_id', empresaId)
        .maybeSingle();

    if (response == null) return null;
    return MaterialItem.fromJson(response);
  }

  Future<MaterialItem> crearMaterial(MaterialItem material) async {
    final userId = _getCurrentUserId();
    final empresaId = await _getEmpresaId();
    if (userId == null) throw Exception('Usuario no autenticado');

    final data = material.toJson();
    data['user_id'] = userId;
    data['empresa_id'] = empresaId;

    final response = await supabase
        .from('materiales')
        .insert(data)
        .select()
        .single();

    return MaterialItem.fromJson(response);
  }

  Future<MaterialItem> actualizarMaterial(MaterialItem material) async {
    final empresaId = await _getEmpresaId();

    final response = await supabase
        .from('materiales')
        .update(material.toJson())
        .eq('id', material.id!)
        .eq('empresa_id', empresaId)
        .select()
        .single();

    return MaterialItem.fromJson(response);
  }

  Future<void> eliminarMaterial(int id) async {
    final empresaId = await _getEmpresaId();

    await supabase
        .from('materiales')
        .delete()
        .eq('id', id)
        .eq('empresa_id', empresaId);
  }

  Future<void> cambiarEstadoMaterial(int id, bool activo) async {
    final empresaId = await _getEmpresaId();

    await supabase
        .from('materiales')
        .update({'activo': activo})
        .eq('id', id)
        .eq('empresa_id', empresaId);
  }

  // ============ MOVIMIENTOS DE STOCK ============

  Future<List<MovimientoMaterial>> getMovimientosPorMaterial(int materialId) async {
    final empresaId = await _getEmpresaId();

    final response = await supabase
        .from('movimientos_material')
        .select()
        .eq('material_id', materialId)
        .eq('empresa_id', empresaId)
        .order('fecha', ascending: false);

    return (response as List).map((json) => MovimientoMaterial.fromJson(json)).toList();
  }

  Future<MovimientoMaterial> registrarMovimiento(MovimientoMaterial movimiento) async {
    final userId = _getCurrentUserId();
    final empresaId = await _getEmpresaId();
    if (userId == null) throw Exception('Usuario no autenticado');

    final data = movimiento.toJson();
    data['user_id'] = userId;
    data['empresa_id'] = empresaId;

    final response = await supabase
        .from('movimientos_material')
        .insert(data)
        .select()
        .single();

    return MovimientoMaterial.fromJson(response);
  }

  Future<void> eliminarMovimiento(int id) async {
    final empresaId = await _getEmpresaId();

    await supabase
        .from('movimientos_material')
        .delete()
        .eq('id', id)
        .eq('empresa_id', empresaId);
  }

  // ============ ESTADÍSTICAS ============

  Future<Map<String, dynamic>> getEstadisticasMaterial(MaterialItem material) async {
    final movimientos = await getMovimientosPorMaterial(material.id!);

    final totalEntradas = movimientos
        .where((m) => m.tipo == 'entrada')
        .fold<int>(0, (sum, m) => sum + m.cantidad);
    final totalSalidas = movimientos
        .where((m) => m.tipo == 'salida')
        .fold<int>(0, (sum, m) => sum + m.cantidad);
    final stockActual = material.stockInicial + totalEntradas - totalSalidas;

    return {
      'stock_actual': stockActual,
      'total_entradas': totalEntradas,
      'total_salidas': totalSalidas,
    };
  }
}
