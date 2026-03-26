/// EchoStack Flutter SDK
///
/// Thin Dart wrapper over native iOS and Android SDKs via platform channels.
/// All attribution logic lives in the native layer.
///
/// Usage:
/// ```dart
/// import 'package:echostack_plugin/echostack_plugin.dart';
///
/// // In main() or initState():
/// await EchoStackPlugin.configure('es_live_...');
///
/// // Send events:
/// await EchoStackPlugin.sendEvent('purchase', parameters: {
///   'revenue': 29.99,
///   'currency': 'USD',
/// });
///
/// // Get attribution:
/// final attribution = await EchoStackPlugin.getAttributionParams();
/// ```
library echostack_plugin;

import 'dart:async';
import 'package:flutter/services.dart';

/// Predefined event types matching EchoStack backend conventions.
class EventType {
  static const String install = 'install';
  static const String trialStart = 'trial_start';
  static const String trialQualified = 'trial_qualified';
  static const String purchase = 'purchase';
  static const String subscribe = 'subscribe';
  static const String adImpression = 'ad_impression';
  static const String adClick = 'ad_click';
}

/// Attribution result from the matching engine.
class Attribution {
  final String? network;
  final String? campaignId;
  final String? campaignName;
  final String? adsetId;
  final String? adId;
  final String? keyword;
  final String matchType;
  final double confidence;

  Attribution({
    this.network,
    this.campaignId,
    this.campaignName,
    this.adsetId,
    this.adId,
    this.keyword,
    required this.matchType,
    required this.confidence,
  });

  factory Attribution.fromMap(Map<String, dynamic> map) {
    return Attribution(
      network: map['network'] as String?,
      campaignId: map['campaign_id'] as String?,
      campaignName: map['campaign_name'] as String?,
      adsetId: map['adset_id'] as String?,
      adId: map['ad_id'] as String?,
      keyword: map['keyword'] as String?,
      matchType: map['match_type'] as String? ?? 'unmatched',
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// EchoStack Flutter SDK — mobile attribution for ad networks.
class EchoStackPlugin {
  static const MethodChannel _channel = MethodChannel('echostack_plugin');

  /// Initialize the SDK. Call once at app startup.
  ///
  /// [apiKey] - Your EchoStack API key (starts with 'es_live_').
  /// [serverURL] - Override server URL (default: https://api.echostack.app).
  /// [logLevel] - 'none', 'error', 'warning', 'debug'.
  static Future<void> configure(
    String apiKey, {
    String serverURL = 'https://api.echostack.app',
    String logLevel = 'none',
  }) async {
    await _channel.invokeMethod('configure', {
      'apiKey': apiKey,
      'serverURL': serverURL,
      'logLevel': logLevel,
    });
  }

  /// Enable Apple Search Ads attribution (iOS only).
  /// Returns false on Android.
  static Future<bool> enableAppleAdsAttribution() async {
    final result = await _channel.invokeMethod<bool>('enableAppleAdsAttribution');
    return result ?? false;
  }

  /// Get the unique device installation ID.
  static Future<String?> getEchoStackId() async {
    return await _channel.invokeMethod<String>('getEchoStackId');
  }

  /// Get attribution parameters after matching completes.
  /// Returns null if not yet available or unmatched.
  static Future<Attribution?> getAttributionParams() async {
    final result = await _channel.invokeMethod<Map>('getAttributionParams');
    if (result == null) return null;
    return Attribution.fromMap(Map<String, dynamic>.from(result));
  }

  /// Check if the SDK is disabled (invalid key, fatal error).
  static Future<bool> isSdkDisabled() async {
    final result = await _channel.invokeMethod<bool>('isSdkDisabled');
    return result ?? false;
  }

  /// Send an in-app event. Events are queued and flushed in batches.
  ///
  /// [eventType] - Event type string (use [EventType] constants or custom).
  /// [parameters] - Optional event parameters (revenue, currency, etc.).
  static Future<void> sendEvent(
    String eventType, {
    Map<String, dynamic>? parameters,
  }) async {
    await _channel.invokeMethod('sendEvent', {
      'eventType': eventType,
      'parameters': parameters ?? {},
    });
  }
}
