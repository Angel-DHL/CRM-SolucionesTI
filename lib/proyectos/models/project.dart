// lib/proyectos/models/project.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'project_enums.dart';
import 'project_material.dart';

/// Modelo principal del Proyecto.
/// Colección Firestore: `projects`
class Project {
  // ═══════════════════════════════════════════════════════════
  // IDENTIFICACIÓN
  // ═══════════════════════════════════════════════════════════
  final String id;
  final String folio; // PRY-000001
  final ProjectStatus status;
  final ProjectType type;
  final ProjectPriority priority;

  // ═══════════════════════════════════════════════════════════
  // INFORMACIÓN BÁSICA
  // ═══════════════════════════════════════════════════════════
  final String nombre;
  final String descripcion;
  final String? descripcionDetallada;
  final List<String> tags;

  // ═══════════════════════════════════════════════════════════
  // CLIENTE (desnormalizado desde CRM)
  // ═══════════════════════════════════════════════════════════
  final String clienteId;
  final String clienteNombre;
  final String? clienteEmpresa;
  final String? clienteEmail;
  final String? clienteTelefono;

  // ═══════════════════════════════════════════════════════════
  // FECHAS
  // ═══════════════════════════════════════════════════════════
  final DateTime? fechaInicio;
  final DateTime? fechaFinEstimada;
  final DateTime? fechaFinReal;
  final DateTime? fechaUltimaActividad;

  // ═══════════════════════════════════════════════════════════
  // RECURRENCIA
  // ═══════════════════════════════════════════════════════════
  final bool esRecurrente;
  final RecurrenceFrequency? frecuenciaRecurrencia;
  final DateTime? fechaProximaRecurrencia;
  final String? proyectoPadreId; // ID del proyecto padre (para instancias recurrentes)

  // ═══════════════════════════════════════════════════════════
  // FINANCIERO
  // ═══════════════════════════════════════════════════════════
  final double valorProyecto;     // Monto total del proyecto (lo que cobra al cliente)
  final double costoEstimado;     // Costo estimado de inversión
  final double costoReal;         // Costo real acumulado
  final double presupuesto;       // Presupuesto asignado
  final double totalIngresos;     // Total de ingresos registrados
  final double totalEgresos;      // Total de egresos registrados
  final double totalAdelantos;    // Total de adelantos recibidos
  final String moneda;

  // ═══════════════════════════════════════════════════════════
  // MATERIALES (embebidos)
  // ═══════════════════════════════════════════════════════════
  final List<ProjectMaterial> materiales;

  // ═══════════════════════════════════════════════════════════
  // EQUIPO
  // ═══════════════════════════════════════════════════════════
  final String? responsableId;
  final String? responsableNombre;
  final List<Map<String, dynamic>> miembrosEquipo;
  // Cada miembro: {'uid': '...', 'nombre': '...', 'rol': '...', 'email': '...'}

  // ═══════════════════════════════════════════════════════════
  // RELACIONES CON OTROS MÓDULOS (trazabilidad)
  // ═══════════════════════════════════════════════════════════
  final String? oportunidadVentaId;
  final String? ordenVentaId;
  final String? cotizacionId;
  final String? campaniaMarketingId;

  // ═══════════════════════════════════════════════════════════
  // PROGRESO
  // ═══════════════════════════════════════════════════════════
  final int progreso; // 0-100
  final int tareasTotal;
  final int tareasCompletadas;

  // ═══════════════════════════════════════════════════════════
  // DOCUMENTOS E IMÁGENES
  // ═══════════════════════════════════════════════════════════
  final List<String> documentUrls;
  final List<String> imagenes;

  // ═══════════════════════════════════════════════════════════
  // NOTAS
  // ═══════════════════════════════════════════════════════════
  final String? notasInternas;
  final String? notasCliente;

  // ═══════════════════════════════════════════════════════════
  // AUDITORÍA
  // ═══════════════════════════════════════════════════════════
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String? lastModifiedBy;
  final Map<String, dynamic>? customFields;

  // ═══════════════════════════════════════════════════════════
  // CONSTRUCTOR
  // ═══════════════════════════════════════════════════════════
  Project({
    required this.id,
    required this.folio,
    required this.status,
    required this.type,
    required this.priority,
    required this.nombre,
    required this.descripcion,
    this.descripcionDetallada,
    this.tags = const [],
    required this.clienteId,
    required this.clienteNombre,
    this.clienteEmpresa,
    this.clienteEmail,
    this.clienteTelefono,
    this.fechaInicio,
    this.fechaFinEstimada,
    this.fechaFinReal,
    this.fechaUltimaActividad,
    this.esRecurrente = false,
    this.frecuenciaRecurrencia,
    this.fechaProximaRecurrencia,
    this.proyectoPadreId,
    this.valorProyecto = 0,
    this.costoEstimado = 0,
    this.costoReal = 0,
    this.presupuesto = 0,
    this.totalIngresos = 0,
    this.totalEgresos = 0,
    this.totalAdelantos = 0,
    this.moneda = 'MXN',
    this.materiales = const [],
    this.responsableId,
    this.responsableNombre,
    this.miembrosEquipo = const [],
    this.oportunidadVentaId,
    this.ordenVentaId,
    this.cotizacionId,
    this.campaniaMarketingId,
    this.progreso = 0,
    this.tareasTotal = 0,
    this.tareasCompletadas = 0,
    this.documentUrls = const [],
    this.imagenes = const [],
    this.notasInternas,
    this.notasCliente,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.lastModifiedBy,
    this.customFields,
  });

  // ═══════════════════════════════════════════════════════════
  // PROPIEDADES CALCULADAS — FINANCIERAS
  // ═══════════════════════════════════════════════════════════

  /// Ganancia neta del proyecto
  double get rentabilidad => totalIngresos - totalEgresos;

  /// Margen de rentabilidad (%)
  double get margenRentabilidad =>
      totalIngresos > 0 ? (rentabilidad / totalIngresos) * 100 : 0;

  /// Saldo pendiente de cobrar al cliente
  double get saldoPendiente => valorProyecto - totalIngresos;

  /// Variación del presupuesto (positivo = sobrecosto)
  double get variacionPresupuesto => costoReal - presupuesto;

  /// ¿Está dentro del presupuesto?
  bool get estaEnPresupuesto => presupuesto <= 0 || costoReal <= presupuesto;

  /// Total de materiales (costo)
  double get costoMateriales =>
      materiales.fold(0.0, (sum, m) => sum + m.subtotal);

  /// Porcentaje de cobro
  double get porcentajeCobro =>
      valorProyecto > 0 ? (totalIngresos / valorProyecto) * 100 : 0;

  // ═══════════════════════════════════════════════════════════
  // PROPIEDADES CALCULADAS — TIEMPO
  // ═══════════════════════════════════════════════════════════

  /// Días transcurridos desde el inicio
  int get diasTranscurridos {
    if (fechaInicio == null) return 0;
    return DateTime.now().difference(fechaInicio!).inDays;
  }

  /// Días restantes hasta la fecha estimada
  int get diasRestantes {
    if (fechaFinEstimada == null) return 0;
    return fechaFinEstimada!.difference(DateTime.now()).inDays;
  }

  /// ¿El proyecto está atrasado?
  bool get estaAtrasado =>
      fechaFinEstimada != null &&
      fechaFinEstimada!.isBefore(DateTime.now()) &&
      status != ProjectStatus.completado &&
      status != ProjectStatus.cancelado;

  /// Duración estimada en días
  int get duracionEstimadaDias {
    if (fechaInicio == null || fechaFinEstimada == null) return 0;
    return fechaFinEstimada!.difference(fechaInicio!).inDays;
  }

  /// Duración real en días (si completado)
  int? get duracionRealDias {
    if (fechaInicio == null || fechaFinReal == null) return null;
    return fechaFinReal!.difference(fechaInicio!).inDays;
  }

  // ═══════════════════════════════════════════════════════════
  // SALUD DEL PROYECTO (indicador calculado)
  // ═══════════════════════════════════════════════════════════

  ProjectHealth get salud {
    if (status == ProjectStatus.completado) return ProjectHealth.excelente;
    if (status == ProjectStatus.cancelado) return ProjectHealth.critica;

    int score = 0;
    int factors = 0;

    // Factor: progreso vs tiempo
    if (fechaInicio != null && fechaFinEstimada != null) {
      factors++;
      final totalDays = duracionEstimadaDias;
      final elapsed = diasTranscurridos;
      if (totalDays > 0) {
        final expectedProgress = (elapsed / totalDays * 100).clamp(0, 100);
        if (progreso >= expectedProgress - 10) {
          score += 2;
        } else if (progreso >= expectedProgress - 25) {
          score += 1;
        }
      }
    }

    // Factor: presupuesto
    if (presupuesto > 0) {
      factors++;
      if (costoReal <= presupuesto * 0.9) {
        score += 2;
      } else if (costoReal <= presupuesto) {
        score += 1;
      }
    }

    // Factor: tareas vencidas
    if (tareasTotal > 0) {
      factors++;
      final completionRate = tareasCompletadas / tareasTotal;
      if (completionRate >= 0.7) {
        score += 2;
      } else if (completionRate >= 0.4) {
        score += 1;
      }
    }

    if (factors == 0) return ProjectHealth.buena;

    final avg = score / (factors * 2);
    if (avg >= 0.75) return ProjectHealth.excelente;
    if (avg >= 0.5) return ProjectHealth.buena;
    if (avg >= 0.25) return ProjectHealth.enRiesgo;
    return ProjectHealth.critica;
  }

  // ═══════════════════════════════════════════════════════════
  // CONVERSIÓN DESDE FIRESTORE
  // ═══════════════════════════════════════════════════════════

  static Project fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;

    DateTime parseTs(dynamic t) {
      if (t == null) return DateTime.now();
      if (t is Timestamp) return t.toDate().toLocal();
      return DateTime.now();
    }

    DateTime? parseTsNull(dynamic t) {
      if (t == null) return null;
      if (t is Timestamp) return t.toDate().toLocal();
      return null;
    }

    return Project(
      id: doc.id,
      folio: d['folio'] ?? '',
      status: ProjectStatusX.from(d['status']),
      type: ProjectTypeX.from(d['type']),
      priority: ProjectPriorityX.from(d['priority']),
      nombre: d['nombre'] ?? '',
      descripcion: d['descripcion'] ?? '',
      descripcionDetallada: d['descripcionDetallada'],
      tags: List<String>.from(d['tags'] ?? []),
      clienteId: d['clienteId'] ?? '',
      clienteNombre: d['clienteNombre'] ?? '',
      clienteEmpresa: d['clienteEmpresa'],
      clienteEmail: d['clienteEmail'],
      clienteTelefono: d['clienteTelefono'],
      fechaInicio: parseTsNull(d['fechaInicio']),
      fechaFinEstimada: parseTsNull(d['fechaFinEstimada']),
      fechaFinReal: parseTsNull(d['fechaFinReal']),
      fechaUltimaActividad: parseTsNull(d['fechaUltimaActividad']),
      esRecurrente: d['esRecurrente'] ?? false,
      frecuenciaRecurrencia: d['frecuenciaRecurrencia'] != null
          ? RecurrenceFrequencyX.from(d['frecuenciaRecurrencia'])
          : null,
      fechaProximaRecurrencia: parseTsNull(d['fechaProximaRecurrencia']),
      proyectoPadreId: d['proyectoPadreId'],
      valorProyecto: (d['valorProyecto'] ?? 0).toDouble(),
      costoEstimado: (d['costoEstimado'] ?? 0).toDouble(),
      costoReal: (d['costoReal'] ?? 0).toDouble(),
      presupuesto: (d['presupuesto'] ?? 0).toDouble(),
      totalIngresos: (d['totalIngresos'] ?? 0).toDouble(),
      totalEgresos: (d['totalEgresos'] ?? 0).toDouble(),
      totalAdelantos: (d['totalAdelantos'] ?? 0).toDouble(),
      moneda: d['moneda'] ?? 'MXN',
      materiales: (d['materiales'] as List<dynamic>?)
              ?.map((m) => ProjectMaterial.fromMap(m as Map<String, dynamic>))
              .toList() ??
          [],
      responsableId: d['responsableId'],
      responsableNombre: d['responsableNombre'],
      miembrosEquipo: (d['miembrosEquipo'] as List<dynamic>?)
              ?.map((m) => Map<String, dynamic>.from(m as Map))
              .toList() ??
          [],
      oportunidadVentaId: d['oportunidadVentaId'],
      ordenVentaId: d['ordenVentaId'],
      cotizacionId: d['cotizacionId'],
      campaniaMarketingId: d['campaniaMarketingId'],
      progreso: d['progreso'] ?? 0,
      tareasTotal: d['tareasTotal'] ?? 0,
      tareasCompletadas: d['tareasCompletadas'] ?? 0,
      documentUrls: List<String>.from(d['documentUrls'] ?? []),
      imagenes: List<String>.from(d['imagenes'] ?? []),
      notasInternas: d['notasInternas'],
      notasCliente: d['notasCliente'],
      createdAt: parseTs(d['createdAt']),
      updatedAt: parseTs(d['updatedAt']),
      createdBy: d['createdBy'] ?? '',
      lastModifiedBy: d['lastModifiedBy'],
      customFields: d['customFields'] != null
          ? Map<String, dynamic>.from(d['customFields'])
          : null,
    );
  }

  // ═══════════════════════════════════════════════════════════
  // CONVERSIÓN A MAP PARA FIRESTORE
  // ═══════════════════════════════════════════════════════════

  Map<String, dynamic> toMap() => {
    'folio': folio,
    'status': status.value,
    'type': type.value,
    'priority': priority.value,
    'nombre': nombre,
    'descripcion': descripcion,
    'descripcionDetallada': descripcionDetallada,
    'tags': tags,
    'clienteId': clienteId,
    'clienteNombre': clienteNombre,
    'clienteEmpresa': clienteEmpresa,
    'clienteEmail': clienteEmail,
    'clienteTelefono': clienteTelefono,
    'fechaInicio': fechaInicio != null ? Timestamp.fromDate(fechaInicio!) : null,
    'fechaFinEstimada': fechaFinEstimada != null ? Timestamp.fromDate(fechaFinEstimada!) : null,
    'fechaFinReal': fechaFinReal != null ? Timestamp.fromDate(fechaFinReal!) : null,
    'fechaUltimaActividad': fechaUltimaActividad != null ? Timestamp.fromDate(fechaUltimaActividad!) : null,
    'esRecurrente': esRecurrente,
    'frecuenciaRecurrencia': frecuenciaRecurrencia?.value,
    'fechaProximaRecurrencia': fechaProximaRecurrencia != null ? Timestamp.fromDate(fechaProximaRecurrencia!) : null,
    'proyectoPadreId': proyectoPadreId,
    'valorProyecto': valorProyecto,
    'costoEstimado': costoEstimado,
    'costoReal': costoReal,
    'presupuesto': presupuesto,
    'totalIngresos': totalIngresos,
    'totalEgresos': totalEgresos,
    'totalAdelantos': totalAdelantos,
    'moneda': moneda,
    'materiales': materiales.map((m) => m.toMap()).toList(),
    'responsableId': responsableId,
    'responsableNombre': responsableNombre,
    'miembrosEquipo': miembrosEquipo,
    'oportunidadVentaId': oportunidadVentaId,
    'ordenVentaId': ordenVentaId,
    'cotizacionId': cotizacionId,
    'campaniaMarketingId': campaniaMarketingId,
    'progreso': progreso,
    'tareasTotal': tareasTotal,
    'tareasCompletadas': tareasCompletadas,
    'documentUrls': documentUrls,
    'imagenes': imagenes,
    'notasInternas': notasInternas,
    'notasCliente': notasCliente,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
    'createdBy': createdBy,
    'lastModifiedBy': lastModifiedBy,
    'customFields': customFields,
  };

  /// Map para actualización (no sobreescribe createdAt)
  Map<String, dynamic> toUpdateMap() {
    final map = toMap();
    map.remove('createdAt');
    map['updatedAt'] = FieldValue.serverTimestamp();
    return map;
  }

  // ═══════════════════════════════════════════════════════════
  // COPYWITH
  // ═══════════════════════════════════════════════════════════

  Project copyWith({
    String? id,
    String? folio,
    ProjectStatus? status,
    ProjectType? type,
    ProjectPriority? priority,
    String? nombre,
    String? descripcion,
    String? descripcionDetallada,
    List<String>? tags,
    String? clienteId,
    String? clienteNombre,
    String? clienteEmpresa,
    String? clienteEmail,
    String? clienteTelefono,
    DateTime? fechaInicio,
    DateTime? fechaFinEstimada,
    DateTime? fechaFinReal,
    DateTime? fechaUltimaActividad,
    bool? esRecurrente,
    RecurrenceFrequency? frecuenciaRecurrencia,
    DateTime? fechaProximaRecurrencia,
    String? proyectoPadreId,
    double? valorProyecto,
    double? costoEstimado,
    double? costoReal,
    double? presupuesto,
    double? totalIngresos,
    double? totalEgresos,
    double? totalAdelantos,
    String? moneda,
    List<ProjectMaterial>? materiales,
    String? responsableId,
    String? responsableNombre,
    List<Map<String, dynamic>>? miembrosEquipo,
    String? oportunidadVentaId,
    String? ordenVentaId,
    String? cotizacionId,
    String? campaniaMarketingId,
    int? progreso,
    int? tareasTotal,
    int? tareasCompletadas,
    List<String>? documentUrls,
    List<String>? imagenes,
    String? notasInternas,
    String? notasCliente,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? lastModifiedBy,
    Map<String, dynamic>? customFields,
  }) {
    return Project(
      id: id ?? this.id,
      folio: folio ?? this.folio,
      status: status ?? this.status,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      descripcionDetallada: descripcionDetallada ?? this.descripcionDetallada,
      tags: tags ?? this.tags,
      clienteId: clienteId ?? this.clienteId,
      clienteNombre: clienteNombre ?? this.clienteNombre,
      clienteEmpresa: clienteEmpresa ?? this.clienteEmpresa,
      clienteEmail: clienteEmail ?? this.clienteEmail,
      clienteTelefono: clienteTelefono ?? this.clienteTelefono,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFinEstimada: fechaFinEstimada ?? this.fechaFinEstimada,
      fechaFinReal: fechaFinReal ?? this.fechaFinReal,
      fechaUltimaActividad: fechaUltimaActividad ?? this.fechaUltimaActividad,
      esRecurrente: esRecurrente ?? this.esRecurrente,
      frecuenciaRecurrencia: frecuenciaRecurrencia ?? this.frecuenciaRecurrencia,
      fechaProximaRecurrencia: fechaProximaRecurrencia ?? this.fechaProximaRecurrencia,
      proyectoPadreId: proyectoPadreId ?? this.proyectoPadreId,
      valorProyecto: valorProyecto ?? this.valorProyecto,
      costoEstimado: costoEstimado ?? this.costoEstimado,
      costoReal: costoReal ?? this.costoReal,
      presupuesto: presupuesto ?? this.presupuesto,
      totalIngresos: totalIngresos ?? this.totalIngresos,
      totalEgresos: totalEgresos ?? this.totalEgresos,
      totalAdelantos: totalAdelantos ?? this.totalAdelantos,
      moneda: moneda ?? this.moneda,
      materiales: materiales ?? this.materiales,
      responsableId: responsableId ?? this.responsableId,
      responsableNombre: responsableNombre ?? this.responsableNombre,
      miembrosEquipo: miembrosEquipo ?? this.miembrosEquipo,
      oportunidadVentaId: oportunidadVentaId ?? this.oportunidadVentaId,
      ordenVentaId: ordenVentaId ?? this.ordenVentaId,
      cotizacionId: cotizacionId ?? this.cotizacionId,
      campaniaMarketingId: campaniaMarketingId ?? this.campaniaMarketingId,
      progreso: progreso ?? this.progreso,
      tareasTotal: tareasTotal ?? this.tareasTotal,
      tareasCompletadas: tareasCompletadas ?? this.tareasCompletadas,
      documentUrls: documentUrls ?? this.documentUrls,
      imagenes: imagenes ?? this.imagenes,
      notasInternas: notasInternas ?? this.notasInternas,
      notasCliente: notasCliente ?? this.notasCliente,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
      customFields: customFields ?? this.customFields,
    );
  }
}
