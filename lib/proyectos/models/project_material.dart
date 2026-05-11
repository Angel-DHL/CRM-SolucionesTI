// lib/proyectos/models/project_material.dart

/// Material/item del inventario asignado a un proyecto.
/// Se almacena como un Map embebido dentro del documento del proyecto.
class ProjectMaterial {
  final String inventoryItemId;
  final String sku;
  final String nombre;
  final String? descripcion;
  final double cantidad;
  final double cantidadUsada;
  final String unidad;
  final double precioUnitario;
  final double subtotal;
  final String? notas;

  ProjectMaterial({
    required this.inventoryItemId,
    required this.sku,
    required this.nombre,
    this.descripcion,
    required this.cantidad,
    this.cantidadUsada = 0,
    this.unidad = 'pieza',
    required this.precioUnitario,
    required this.subtotal,
    this.notas,
  });

  /// Cantidad pendiente de usar
  double get cantidadPendiente => cantidad - cantidadUsada;

  /// ¿Se ha usado todo el material?
  bool get isFullyUsed => cantidadUsada >= cantidad;

  /// Costo total del material usado
  double get costoUsado => cantidadUsada * precioUnitario;

  factory ProjectMaterial.fromMap(Map<String, dynamic> m) => ProjectMaterial(
    inventoryItemId: m['inventoryItemId'] ?? '',
    sku: m['sku'] ?? '',
    nombre: m['nombre'] ?? '',
    descripcion: m['descripcion'],
    cantidad: (m['cantidad'] ?? 0).toDouble(),
    cantidadUsada: (m['cantidadUsada'] ?? 0).toDouble(),
    unidad: m['unidad'] ?? 'pieza',
    precioUnitario: (m['precioUnitario'] ?? 0).toDouble(),
    subtotal: (m['subtotal'] ?? 0).toDouble(),
    notas: m['notas'],
  );

  Map<String, dynamic> toMap() => {
    'inventoryItemId': inventoryItemId,
    'sku': sku,
    'nombre': nombre,
    'descripcion': descripcion,
    'cantidad': cantidad,
    'cantidadUsada': cantidadUsada,
    'unidad': unidad,
    'precioUnitario': precioUnitario,
    'subtotal': subtotal,
    'notas': notas,
  };

  ProjectMaterial copyWith({
    String? inventoryItemId,
    String? sku,
    String? nombre,
    String? descripcion,
    double? cantidad,
    double? cantidadUsada,
    String? unidad,
    double? precioUnitario,
    double? subtotal,
    String? notas,
  }) {
    return ProjectMaterial(
      inventoryItemId: inventoryItemId ?? this.inventoryItemId,
      sku: sku ?? this.sku,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      cantidad: cantidad ?? this.cantidad,
      cantidadUsada: cantidadUsada ?? this.cantidadUsada,
      unidad: unidad ?? this.unidad,
      precioUnitario: precioUnitario ?? this.precioUnitario,
      subtotal: subtotal ?? this.subtotal,
      notas: notas ?? this.notas,
    );
  }
}
