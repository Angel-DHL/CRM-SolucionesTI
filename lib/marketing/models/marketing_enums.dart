// lib/marketing/models/marketing_enums.dart

import 'package:flutter/material.dart';

/// Estado del ciclo de vida de una campaña
enum CampaignStatus { borrador, activa, pausada, completada, cancelada }

extension CampaignStatusX on CampaignStatus {
  String get value => name;

  String get label => switch (this) {
    CampaignStatus.borrador => 'Borrador',
    CampaignStatus.activa => 'Activa',
    CampaignStatus.pausada => 'Pausada',
    CampaignStatus.completada => 'Completada',
    CampaignStatus.cancelada => 'Cancelada',
  };

  String get emoji => switch (this) {
    CampaignStatus.borrador => '📝',
    CampaignStatus.activa => '🚀',
    CampaignStatus.pausada => '⏸️',
    CampaignStatus.completada => '✅',
    CampaignStatus.cancelada => '❌',
  };

  Color get color => switch (this) {
    CampaignStatus.borrador => Colors.grey,
    CampaignStatus.activa => const Color(0xFF52B788),
    CampaignStatus.pausada => const Color(0xFFE8A838),
    CampaignStatus.completada => const Color(0xFF4A90D9),
    CampaignStatus.cancelada => const Color(0xFFD94F4F),
  };

  Color get bgColor => switch (this) {
    CampaignStatus.borrador => Colors.grey.shade50,
    CampaignStatus.activa => const Color(0xFFE6F7EF),
    CampaignStatus.pausada => const Color(0xFFFFF4E0),
    CampaignStatus.completada => const Color(0xFFE8F0FB),
    CampaignStatus.cancelada => const Color(0xFFFDECEC),
  };

  static CampaignStatus from(String? v) =>
      CampaignStatus.values.where((e) => e.name == v).firstOrNull ?? CampaignStatus.borrador;
}

/// Tipo de campaña
enum CampaignType { email, redesSociales, contenido, evento, publicidadPagada, referido, seo, influencer }

extension CampaignTypeX on CampaignType {
  String get value => name;

  String get label => switch (this) {
    CampaignType.email => 'Email Marketing',
    CampaignType.redesSociales => 'Redes Sociales',
    CampaignType.contenido => 'Marketing de Contenido',
    CampaignType.evento => 'Evento',
    CampaignType.publicidadPagada => 'Publicidad Pagada',
    CampaignType.referido => 'Programa de Referidos',
    CampaignType.seo => 'SEO / Orgánico',
    CampaignType.influencer => 'Influencer',
  };

  IconData get icon => switch (this) {
    CampaignType.email => Icons.email_rounded,
    CampaignType.redesSociales => Icons.share_rounded,
    CampaignType.contenido => Icons.article_rounded,
    CampaignType.evento => Icons.event_rounded,
    CampaignType.publicidadPagada => Icons.ads_click_rounded,
    CampaignType.referido => Icons.people_rounded,
    CampaignType.seo => Icons.search_rounded,
    CampaignType.influencer => Icons.star_rounded,
  };

  static CampaignType from(String? v) =>
      CampaignType.values.where((e) => e.name == v).firstOrNull ?? CampaignType.redesSociales;
}

/// Canal específico de la campaña
enum CampaignChannel { facebook, instagram, youtube, tiktok, linkedin, googleAds, email, sitioWeb, whatsapp, otro }

extension CampaignChannelX on CampaignChannel {
  String get value => name;

  String get label => switch (this) {
    CampaignChannel.facebook => 'Facebook',
    CampaignChannel.instagram => 'Instagram',
    CampaignChannel.youtube => 'YouTube',
    CampaignChannel.tiktok => 'TikTok',
    CampaignChannel.linkedin => 'LinkedIn',
    CampaignChannel.googleAds => 'Google Ads',
    CampaignChannel.email => 'Email',
    CampaignChannel.sitioWeb => 'Sitio Web',
    CampaignChannel.whatsapp => 'WhatsApp',
    CampaignChannel.otro => 'Otro',
  };

  Color get color => switch (this) {
    CampaignChannel.facebook => const Color(0xFF1877F2),
    CampaignChannel.instagram => const Color(0xFFE4405F),
    CampaignChannel.youtube => const Color(0xFFFF0000),
    CampaignChannel.tiktok => const Color(0xFF000000),
    CampaignChannel.linkedin => const Color(0xFF0A66C2),
    CampaignChannel.googleAds => const Color(0xFF4285F4),
    CampaignChannel.email => const Color(0xFF44562C),
    CampaignChannel.sitioWeb => const Color(0xFFACC952),
    CampaignChannel.whatsapp => const Color(0xFF25D366),
    CampaignChannel.otro => Colors.grey,
  };

  IconData get icon => switch (this) {
    CampaignChannel.facebook => Icons.facebook_rounded,
    CampaignChannel.instagram => Icons.camera_alt_rounded,
    CampaignChannel.youtube => Icons.play_circle_rounded,
    CampaignChannel.tiktok => Icons.music_note_rounded,
    CampaignChannel.linkedin => Icons.business_rounded,
    CampaignChannel.googleAds => Icons.ads_click_rounded,
    CampaignChannel.email => Icons.email_rounded,
    CampaignChannel.sitioWeb => Icons.language_rounded,
    CampaignChannel.whatsapp => Icons.chat_rounded,
    CampaignChannel.otro => Icons.more_horiz_rounded,
  };

  static CampaignChannel from(String? v) =>
      CampaignChannel.values.where((e) => e.name == v).firstOrNull ?? CampaignChannel.otro;
}

/// Plataforma de redes sociales (para métricas)
enum SocialPlatform { facebook, instagram, youtube, tiktok, whatsapp, linkedin, sitioWeb }

extension SocialPlatformX on SocialPlatform {
  String get value => name;

  String get label => switch (this) {
    SocialPlatform.facebook => 'Facebook',
    SocialPlatform.instagram => 'Instagram',
    SocialPlatform.youtube => 'YouTube',
    SocialPlatform.tiktok => 'TikTok',
    SocialPlatform.whatsapp => 'WhatsApp',
    SocialPlatform.linkedin => 'LinkedIn',
    SocialPlatform.sitioWeb => 'Sitio Web',
  };

  Color get color => switch (this) {
    SocialPlatform.facebook => const Color(0xFF1877F2),
    SocialPlatform.instagram => const Color(0xFFE4405F),
    SocialPlatform.youtube => const Color(0xFFFF0000),
    SocialPlatform.tiktok => const Color(0xFF000000),
    SocialPlatform.whatsapp => const Color(0xFF25D366),
    SocialPlatform.linkedin => const Color(0xFF0A66C2),
    SocialPlatform.sitioWeb => const Color(0xFFACC952),
  };

  IconData get icon => switch (this) {
    SocialPlatform.facebook => Icons.facebook_rounded,
    SocialPlatform.instagram => Icons.camera_alt_rounded,
    SocialPlatform.youtube => Icons.play_circle_rounded,
    SocialPlatform.tiktok => Icons.music_note_rounded,
    SocialPlatform.whatsapp => Icons.chat_rounded,
    SocialPlatform.linkedin => Icons.business_rounded,
    SocialPlatform.sitioWeb => Icons.language_rounded,
  };

  bool get hasApi => switch (this) {
    SocialPlatform.youtube => true,
    _ => false, // Meta pendiente, TikTok/WhatsApp manual
  };

  static SocialPlatform from(String? v) =>
      SocialPlatform.values.where((e) => e.name == v).firstOrNull ?? SocialPlatform.facebook;
}

/// Segmento de audiencia
enum AudienceSegment { nuevosLeads, prospectos, clientesActivos, clientesInactivos, todos, personalizado }

extension AudienceSegmentX on AudienceSegment {
  String get value => name;

  String get label => switch (this) {
    AudienceSegment.nuevosLeads => 'Nuevos Leads',
    AudienceSegment.prospectos => 'Prospectos',
    AudienceSegment.clientesActivos => 'Clientes Activos',
    AudienceSegment.clientesInactivos => 'Clientes Inactivos',
    AudienceSegment.todos => 'Todos',
    AudienceSegment.personalizado => 'Personalizado',
  };

  static AudienceSegment from(String? v) =>
      AudienceSegment.values.where((e) => e.name == v).firstOrNull ?? AudienceSegment.todos;
}

/// Periodo de métricas
enum MetricPeriod { diario, semanal, mensual, trimestral, anual }

extension MetricPeriodX on MetricPeriod {
  String get value => name;

  String get label => switch (this) {
    MetricPeriod.diario => 'Diario',
    MetricPeriod.semanal => 'Semanal',
    MetricPeriod.mensual => 'Mensual',
    MetricPeriod.trimestral => 'Trimestral',
    MetricPeriod.anual => 'Anual',
  };

  static MetricPeriod from(String? v) =>
      MetricPeriod.values.where((e) => e.name == v).firstOrNull ?? MetricPeriod.mensual;
}
