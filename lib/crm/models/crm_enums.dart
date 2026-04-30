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

// ═══════════════════════════════════════════════════════════
// NUEVOS ENUMS - PRIORIDAD Y TAMAÑO DE EMPRESA
// ═══════════════════════════════════════════════════════════

/// Prioridad del contacto/deal
enum ContactPriority {
  alta,
  media,
  baja,
}

extension ContactPriorityX on ContactPriority {
  String get value => switch (this) {
    ContactPriority.alta => 'alta',
    ContactPriority.media => 'media',
    ContactPriority.baja => 'baja',
  };

  String get label => switch (this) {
    ContactPriority.alta => 'Alta',
    ContactPriority.media => 'Media',
    ContactPriority.baja => 'Baja',
  };

  String get emoji => switch (this) {
    ContactPriority.alta => '🔴',
    ContactPriority.media => '🟡',
    ContactPriority.baja => '🟢',
  };

  int get colorValue => switch (this) {
    ContactPriority.alta => 0xFFE53935,
    ContactPriority.media => 0xFFFFA726,
    ContactPriority.baja => 0xFF66BB6A,
  };

  static ContactPriority from(String? v) => switch (v) {
    'alta' => ContactPriority.alta,
    'media' => ContactPriority.media,
    'baja' => ContactPriority.baja,
    _ => ContactPriority.media,
  };
}

/// Tamaño de empresa
enum CompanySize {
  micro,
  pequena,
  mediana,
  grande,
}

extension CompanySizeX on CompanySize {
  String get value => switch (this) {
    CompanySize.micro => 'micro',
    CompanySize.pequena => 'pequena',
    CompanySize.mediana => 'mediana',
    CompanySize.grande => 'grande',
  };

  String get label => switch (this) {
    CompanySize.micro => 'Micro (1-10)',
    CompanySize.pequena => 'Pequeña (11-50)',
    CompanySize.mediana => 'Mediana (51-250)',
    CompanySize.grande => 'Grande (250+)',
  };

  static CompanySize from(String? v) => switch (v) {
    'micro' => CompanySize.micro,
    'pequena' => CompanySize.pequena,
    'mediana' => CompanySize.mediana,
    'grande' => CompanySize.grande,
    _ => CompanySize.micro,
  };
}

// ═══════════════════════════════════════════════════════════
// CATÁLOGOS SAT - RÉGIMEN FISCAL Y USO CFDI
// ═══════════════════════════════════════════════════════════

/// Catálogo de regímenes fiscales del SAT (México) más comunes
class RegimenFiscalCatalog {
  static const List<Map<String, String>> values = [
    {'clave': '601', 'descripcion': 'General de Ley Personas Morales'},
    {'clave': '603', 'descripcion': 'Personas Morales con Fines no Lucrativos'},
    {'clave': '605', 'descripcion': 'Sueldos y Salarios e Ingresos Asimilados a Salarios'},
    {'clave': '606', 'descripcion': 'Arrendamiento'},
    {'clave': '607', 'descripcion': 'Régimen de Enajenación o Adquisición de Bienes'},
    {'clave': '608', 'descripcion': 'Demás ingresos'},
    {'clave': '610', 'descripcion': 'Residentes en el Extranjero sin Establecimiento Permanente en México'},
    {'clave': '611', 'descripcion': 'Ingresos por Dividendos (socios y accionistas)'},
    {'clave': '612', 'descripcion': 'Personas Físicas con Actividades Empresariales y Profesionales'},
    {'clave': '614', 'descripcion': 'Ingresos por intereses'},
    {'clave': '615', 'descripcion': 'Régimen de los ingresos por obtención de premios'},
    {'clave': '616', 'descripcion': 'Sin obligaciones fiscales'},
    {'clave': '620', 'descripcion': 'Sociedades Cooperativas de Producción que optan por diferir sus ingresos'},
    {'clave': '621', 'descripcion': 'Incorporación Fiscal'},
    {'clave': '622', 'descripcion': 'Actividades Agrícolas, Ganaderas, Silvícolas y Pesqueras'},
    {'clave': '623', 'descripcion': 'Opcional para Grupos de Sociedades'},
    {'clave': '624', 'descripcion': 'Coordinados'},
    {'clave': '625', 'descripcion': 'Régimen de las Actividades Empresariales con ingresos a través de Plataformas Tecnológicas'},
    {'clave': '626', 'descripcion': 'Régimen Simplificado de Confianza'},
  ];

  /// Devuelve la lista como opciones legibles: "601 - General de Ley..."
  static List<String> get options =>
      values.map((v) => '${v['clave']} - ${v['descripcion']}').toList();
}

/// Catálogo de usos de CFDI del SAT (México) más comunes
class UsoCfdiCatalog {
  static const List<Map<String, String>> values = [
    {'clave': 'G01', 'descripcion': 'Adquisición de mercancías'},
    {'clave': 'G02', 'descripcion': 'Devoluciones, descuentos o bonificaciones'},
    {'clave': 'G03', 'descripcion': 'Gastos en general'},
    {'clave': 'I01', 'descripcion': 'Construcciones'},
    {'clave': 'I02', 'descripcion': 'Mobiliario y equipo de oficina por inversiones'},
    {'clave': 'I03', 'descripcion': 'Equipo de transporte'},
    {'clave': 'I04', 'descripcion': 'Equipo de cómputo y accesorios'},
    {'clave': 'I05', 'descripcion': 'Dados, troqueles, moldes, matrices y herramental'},
    {'clave': 'I06', 'descripcion': 'Comunicaciones telefónicas'},
    {'clave': 'I07', 'descripcion': 'Comunicaciones satelitales'},
    {'clave': 'I08', 'descripcion': 'Otra maquinaria y equipo'},
    {'clave': 'D01', 'descripcion': 'Honorarios médicos, dentales y gastos hospitalarios'},
    {'clave': 'D02', 'descripcion': 'Gastos médicos por incapacidad o discapacidad'},
    {'clave': 'D03', 'descripcion': 'Gastos funerales'},
    {'clave': 'D04', 'descripcion': 'Donativos'},
    {'clave': 'D05', 'descripcion': 'Intereses reales efectivamente pagados por créditos hipotecarios (casa habitación)'},
    {'clave': 'D06', 'descripcion': 'Aportaciones voluntarias al SAR'},
    {'clave': 'D07', 'descripcion': 'Primas por seguros de gastos médicos'},
    {'clave': 'D08', 'descripcion': 'Gastos de transportación escolar obligatoria'},
    {'clave': 'D10', 'descripcion': 'Pagos por servicios educativos (colegiaturas)'},
    {'clave': 'P01', 'descripcion': 'Por definir'},
    {'clave': 'S01', 'descripcion': 'Sin efectos fiscales'},
    {'clave': 'CP01', 'descripcion': 'Pagos'},
    {'clave': 'CN01', 'descripcion': 'Nómina'},
  ];

  static List<String> get options =>
      values.map((v) => '${v['clave']} - ${v['descripcion']}').toList();
}
