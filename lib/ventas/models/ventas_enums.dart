// lib/ventas/models/ventas_enums.dart

/// Estado de la cotización en el pipeline comercial
enum QuoteStatus {
  borrador,
  enviada,
  aceptada,
  rechazada,
  expirada,
  convertida,
}

extension QuoteStatusX on QuoteStatus {
  String get value => name;

  String get label => switch (this) {
    QuoteStatus.borrador => 'Borrador',
    QuoteStatus.enviada => 'Enviada',
    QuoteStatus.aceptada => 'Aceptada',
    QuoteStatus.rechazada => 'Rechazada',
    QuoteStatus.expirada => 'Expirada',
    QuoteStatus.convertida => 'Convertida a Orden',
  };

  String get emoji => switch (this) {
    QuoteStatus.borrador => '📝',
    QuoteStatus.enviada => '📤',
    QuoteStatus.aceptada => '✅',
    QuoteStatus.rechazada => '❌',
    QuoteStatus.expirada => '⏰',
    QuoteStatus.convertida => '🔄',
  };

  int get colorValue => switch (this) {
    QuoteStatus.borrador => 0xFF78909C,
    QuoteStatus.enviada => 0xFF42A5F5,
    QuoteStatus.aceptada => 0xFF66BB6A,
    QuoteStatus.rechazada => 0xFFEF5350,
    QuoteStatus.expirada => 0xFFFFA726,
    QuoteStatus.convertida => 0xFF7E57C2,
  };

  bool get canEdit => this == QuoteStatus.borrador;
  bool get canSend => this == QuoteStatus.borrador;
  bool get canAccept => this == QuoteStatus.enviada;
  bool get canConvert => this == QuoteStatus.aceptada;

  static QuoteStatus from(String? v) => switch (v) {
    'borrador' => QuoteStatus.borrador,
    'enviada' => QuoteStatus.enviada,
    'aceptada' => QuoteStatus.aceptada,
    'rechazada' => QuoteStatus.rechazada,
    'expirada' => QuoteStatus.expirada,
    'convertida' => QuoteStatus.convertida,
    _ => QuoteStatus.borrador,
  };
}

/// Estado de cumplimiento de la orden de venta
enum OrderStatus {
  pendiente,
  enProceso,
  completada,
  cancelada,
  parcial,
}

extension OrderStatusX on OrderStatus {
  String get value => switch (this) {
    OrderStatus.pendiente => 'pendiente',
    OrderStatus.enProceso => 'en_proceso',
    OrderStatus.completada => 'completada',
    OrderStatus.cancelada => 'cancelada',
    OrderStatus.parcial => 'parcial',
  };

  String get label => switch (this) {
    OrderStatus.pendiente => 'Pendiente',
    OrderStatus.enProceso => 'En Proceso',
    OrderStatus.completada => 'Completada',
    OrderStatus.cancelada => 'Cancelada',
    OrderStatus.parcial => 'Entrega Parcial',
  };

  String get emoji => switch (this) {
    OrderStatus.pendiente => '⏳',
    OrderStatus.enProceso => '🔧',
    OrderStatus.completada => '✅',
    OrderStatus.cancelada => '❌',
    OrderStatus.parcial => '📦',
  };

  int get colorValue => switch (this) {
    OrderStatus.pendiente => 0xFFFFA726,
    OrderStatus.enProceso => 0xFF42A5F5,
    OrderStatus.completada => 0xFF66BB6A,
    OrderStatus.cancelada => 0xFFEF5350,
    OrderStatus.parcial => 0xFF7E57C2,
  };

  static OrderStatus from(String? v) => switch (v) {
    'pendiente' => OrderStatus.pendiente,
    'en_proceso' => OrderStatus.enProceso,
    'completada' => OrderStatus.completada,
    'cancelada' => OrderStatus.cancelada,
    'parcial' => OrderStatus.parcial,
    _ => OrderStatus.pendiente,
  };
}

/// Estado de pago
enum PaymentStatus {
  pendiente,
  parcial,
  pagada,
  vencida,
  reembolsada,
}

extension PaymentStatusX on PaymentStatus {
  String get value => name;

  String get label => switch (this) {
    PaymentStatus.pendiente => 'Pendiente',
    PaymentStatus.parcial => 'Pago Parcial',
    PaymentStatus.pagada => 'Pagada',
    PaymentStatus.vencida => 'Vencida',
    PaymentStatus.reembolsada => 'Reembolsada',
  };

  int get colorValue => switch (this) {
    PaymentStatus.pendiente => 0xFFFFA726,
    PaymentStatus.parcial => 0xFF42A5F5,
    PaymentStatus.pagada => 0xFF66BB6A,
    PaymentStatus.vencida => 0xFFEF5350,
    PaymentStatus.reembolsada => 0xFF78909C,
  };

  static PaymentStatus from(String? v) => switch (v) {
    'pendiente' => PaymentStatus.pendiente,
    'parcial' => PaymentStatus.parcial,
    'pagada' => PaymentStatus.pagada,
    'vencida' => PaymentStatus.vencida,
    'reembolsada' => PaymentStatus.reembolsada,
    _ => PaymentStatus.pendiente,
  };
}

/// Método de pago
enum PaymentMethod {
  transferencia,
  efectivo,
  tarjeta,
  cheque,
  otro,
}

extension PaymentMethodX on PaymentMethod {
  String get value => name;

  String get label => switch (this) {
    PaymentMethod.transferencia => 'Transferencia',
    PaymentMethod.efectivo => 'Efectivo',
    PaymentMethod.tarjeta => 'Tarjeta',
    PaymentMethod.cheque => 'Cheque',
    PaymentMethod.otro => 'Otro',
  };

  static PaymentMethod from(String? v) => switch (v) {
    'transferencia' => PaymentMethod.transferencia,
    'efectivo' => PaymentMethod.efectivo,
    'tarjeta' => PaymentMethod.tarjeta,
    'cheque' => PaymentMethod.cheque,
    _ => PaymentMethod.otro,
  };
}

// ═══════════════════════════════════════════════════════════
// OPORTUNIDADES DE VENTA
// ═══════════════════════════════════════════════════════════

/// Estado de la oportunidad en el pipeline comercial
enum OpportunityStatus {
  nueva,
  calificada,
  propuesta,
  negociacion,
  ganada,
  perdida,
}

extension OpportunityStatusX on OpportunityStatus {
  String get value => name;

  String get label => switch (this) {
    OpportunityStatus.nueva => 'Nueva',
    OpportunityStatus.calificada => 'Calificada',
    OpportunityStatus.propuesta => 'Propuesta',
    OpportunityStatus.negociacion => 'Negociación',
    OpportunityStatus.ganada => 'Ganada',
    OpportunityStatus.perdida => 'Perdida',
  };

  String get emoji => switch (this) {
    OpportunityStatus.nueva => '🌱',
    OpportunityStatus.calificada => '🎯',
    OpportunityStatus.propuesta => '📋',
    OpportunityStatus.negociacion => '🤝',
    OpportunityStatus.ganada => '🏆',
    OpportunityStatus.perdida => '❌',
  };

  int get colorValue => switch (this) {
    OpportunityStatus.nueva => 0xFF42A5F5,
    OpportunityStatus.calificada => 0xFFFFA726,
    OpportunityStatus.propuesta => 0xFF7E57C2,
    OpportunityStatus.negociacion => 0xFF26C6DA,
    OpportunityStatus.ganada => 0xFF66BB6A,
    OpportunityStatus.perdida => 0xFFEF5350,
  };

  int get pipelineOrder => switch (this) {
    OpportunityStatus.nueva => 0,
    OpportunityStatus.calificada => 1,
    OpportunityStatus.propuesta => 2,
    OpportunityStatus.negociacion => 3,
    OpportunityStatus.ganada => 4,
    OpportunityStatus.perdida => 5,
  };

  bool get isActive =>
      this != OpportunityStatus.ganada && this != OpportunityStatus.perdida;

  bool get canAdvance => switch (this) {
    OpportunityStatus.nueva => true,
    OpportunityStatus.calificada => true,
    OpportunityStatus.propuesta => true,
    OpportunityStatus.negociacion => true,
    _ => false,
  };

  OpportunityStatus? get nextStatus => switch (this) {
    OpportunityStatus.nueva => OpportunityStatus.calificada,
    OpportunityStatus.calificada => OpportunityStatus.propuesta,
    OpportunityStatus.propuesta => OpportunityStatus.negociacion,
    OpportunityStatus.negociacion => OpportunityStatus.ganada,
    _ => null,
  };

  static OpportunityStatus from(String? v) => switch (v) {
    'nueva' => OpportunityStatus.nueva,
    'calificada' => OpportunityStatus.calificada,
    'propuesta' => OpportunityStatus.propuesta,
    'negociacion' => OpportunityStatus.negociacion,
    'ganada' => OpportunityStatus.ganada,
    'perdida' => OpportunityStatus.perdida,
    _ => OpportunityStatus.nueva,
  };
}

/// Fuente de la oportunidad
enum OpportunitySource {
  formularioWeb,
  llamada,
  referido,
  redSocial,
  evento,
  email,
  otro,
}

extension OpportunitySourceX on OpportunitySource {
  String get value => switch (this) {
    OpportunitySource.formularioWeb => 'formulario_web',
    OpportunitySource.llamada => 'llamada',
    OpportunitySource.referido => 'referido',
    OpportunitySource.redSocial => 'red_social',
    OpportunitySource.evento => 'evento',
    OpportunitySource.email => 'email',
    OpportunitySource.otro => 'otro',
  };

  String get label => switch (this) {
    OpportunitySource.formularioWeb => 'Formulario Web',
    OpportunitySource.llamada => 'Llamada',
    OpportunitySource.referido => 'Referido',
    OpportunitySource.redSocial => 'Red Social',
    OpportunitySource.evento => 'Evento',
    OpportunitySource.email => 'Email',
    OpportunitySource.otro => 'Otro',
  };

  static OpportunitySource from(String? v) => switch (v) {
    'formulario_web' => OpportunitySource.formularioWeb,
    'llamada' => OpportunitySource.llamada,
    'referido' => OpportunitySource.referido,
    'red_social' => OpportunitySource.redSocial,
    'evento' => OpportunitySource.evento,
    'email' => OpportunitySource.email,
    _ => OpportunitySource.otro,
  };
}
