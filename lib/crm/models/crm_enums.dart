// lib/crm/models/crm_enums.dart

/// Estatus del contacto en el embudo de conversión
enum ContactStatus {
  lead,
  prospecto,
  clientePotencial,
  cliente,
  inactivo,
}

extension ContactStatusX on ContactStatus {
  String get value => switch (this) {
    ContactStatus.lead => 'lead',
    ContactStatus.prospecto => 'prospecto',
    ContactStatus.clientePotencial => 'cliente_potencial',
    ContactStatus.cliente => 'cliente',
    ContactStatus.inactivo => 'inactivo',
  };

  String get label => switch (this) {
    ContactStatus.lead => 'Lead',
    ContactStatus.prospecto => 'Prospecto',
    ContactStatus.clientePotencial => 'Cliente Potencial',
    ContactStatus.cliente => 'Cliente',
    ContactStatus.inactivo => 'Inactivo',
  };

  String get emoji => switch (this) {
    ContactStatus.lead => '📥',
    ContactStatus.prospecto => '👤',
    ContactStatus.clientePotencial => '⭐',
    ContactStatus.cliente => '✅',
    ContactStatus.inactivo => '❌',
  };

  /// Orden en el pipeline (menor = más temprano)
  int get pipelineOrder => switch (this) {
    ContactStatus.lead => 0,
    ContactStatus.prospecto => 1,
    ContactStatus.clientePotencial => 2,
    ContactStatus.cliente => 3,
    ContactStatus.inactivo => 4,
  };

  /// ¿Puede avanzar al siguiente estatus?
  bool get canAdvance => this != ContactStatus.cliente && this != ContactStatus.inactivo;

  /// Siguiente estatus en el pipeline
  ContactStatus? get nextStatus => switch (this) {
    ContactStatus.lead => ContactStatus.prospecto,
    ContactStatus.prospecto => ContactStatus.clientePotencial,
    ContactStatus.clientePotencial => ContactStatus.cliente,
    ContactStatus.cliente => null,
    ContactStatus.inactivo => null,
  };

  static ContactStatus from(String? v) => switch (v) {
    'lead' => ContactStatus.lead,
    'prospecto' => ContactStatus.prospecto,
    'cliente_potencial' => ContactStatus.clientePotencial,
    'cliente' => ContactStatus.cliente,
    'inactivo' => ContactStatus.inactivo,
    _ => ContactStatus.lead,
  };
}

/// Fuente de donde llegó el contacto
enum ContactSource {
  formularioWeb,
  llamada,
  referido,
  redSocial,
  email,
  otro,
}

extension ContactSourceX on ContactSource {
  String get value => switch (this) {
    ContactSource.formularioWeb => 'formulario_web',
    ContactSource.llamada => 'llamada',
    ContactSource.referido => 'referido',
    ContactSource.redSocial => 'red_social',
    ContactSource.email => 'email',
    ContactSource.otro => 'otro',
  };

  String get label => switch (this) {
    ContactSource.formularioWeb => 'Formulario Web',
    ContactSource.llamada => 'Llamada',
    ContactSource.referido => 'Referido',
    ContactSource.redSocial => 'Red Social',
    ContactSource.email => 'Email',
    ContactSource.otro => 'Otro',
  };

  static ContactSource from(String? v) => switch (v) {
    'formulario_web' || 'formulario-contacto' => ContactSource.formularioWeb,
    'llamada' => ContactSource.llamada,
    'referido' => ContactSource.referido,
    'red_social' => ContactSource.redSocial,
    'email' => ContactSource.email,
    _ => ContactSource.otro,
  };
}

/// Tipo de actividad registrada en el historial
enum CrmActivityType {
  nota,
  llamada,
  email,
  reunion,
  cambioEstatus,
  conversion,
}

extension CrmActivityTypeX on CrmActivityType {
  String get value => switch (this) {
    CrmActivityType.nota => 'nota',
    CrmActivityType.llamada => 'llamada',
    CrmActivityType.email => 'email',
    CrmActivityType.reunion => 'reunion',
    CrmActivityType.cambioEstatus => 'cambio_estatus',
    CrmActivityType.conversion => 'conversion',
  };

  String get label => switch (this) {
    CrmActivityType.nota => 'Nota',
    CrmActivityType.llamada => 'Llamada',
    CrmActivityType.email => 'Email',
    CrmActivityType.reunion => 'Reunión',
    CrmActivityType.cambioEstatus => 'Cambio de estatus',
    CrmActivityType.conversion => 'Conversión',
  };

  static CrmActivityType from(String? v) => switch (v) {
    'nota' => CrmActivityType.nota,
    'llamada' => CrmActivityType.llamada,
    'email' => CrmActivityType.email,
    'reunion' => CrmActivityType.reunion,
    'cambio_estatus' => CrmActivityType.cambioEstatus,
    'conversion' => CrmActivityType.conversion,
    _ => CrmActivityType.nota,
  };
}
