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
  static const String login = 'login';
  static const String signUp = 'sign_up';
  static const String register = 'register';
  static const String addToCart = 'add_to_cart';
  static const String addToWishlist = 'add_to_wishlist';
  static const String initiateCheckout = 'initiate_checkout';
  static const String levelStart = 'level_start';
  static const String levelComplete = 'level_complete';
  static const String tutorialComplete = 'tutorial_complete';
  static const String search = 'search';
  static const String viewItem = 'view_item';
  static const String viewContent = 'view_content';
  static const String share = 'share';
  static const String custom = 'custom';
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

  /// Pass EchoStack attribution data to RevenueCat for campaign-based paywall targeting.
  /// Call after both EchoStack and RevenueCat Purchases SDKs are configured.
  ///
  /// Sets subscriber attributes so RevenueCat can segment users by acquisition source:
  /// - `$echoStackId` — EchoStack device ID
  /// - `$mediaSource` — attributed ad network (e.g., "meta", "google")
  /// - `$campaign` — campaign name
  /// - `$adGroup` — ad set / ad group ID
  /// - `$ad` — ad creative ID
  /// - `$keyword` — search keyword (if applicable)
  ///
  /// Requires the `purchases_flutter` package as a dependency.
  /// The host app must pass the `setAttributes` function since Dart does not
  /// support optional dynamic imports.
  ///
  /// Example:
  /// ```dart
  /// import 'package:purchases_flutter/purchases_flutter.dart';
  ///
  /// await EchoStackPlugin.syncWithRevenueCat(
  ///   setAttributes: (attrs) => Purchases.setAttributes(attrs),
  /// );
  /// ```
  ///
  /// TODO(partnership): When EchoStack becomes a recognized RevenueCat integration partner,
  /// replace custom attributes with Purchases.setEchoStackAttributionParams()
  static Future<void> syncWithRevenueCat({
    required Future<void> Function(Map<String, String> attributes) setAttributes,
  }) async {
    try {
      final attributes = <String, String>{};

      final echoStackId = await getEchoStackId();
      if (echoStackId != null) {
        attributes[r'$echoStackId'] = echoStackId;
      }

      final attribution = await getAttributionParams();
      if (attribution != null) {
        if (attribution.network != null) {
          attributes[r'$mediaSource'] = attribution.network!;
        }
        if (attribution.campaignName != null) {
          attributes[r'$campaign'] = attribution.campaignName!;
        }
        if (attribution.adsetId != null) {
          attributes[r'$adGroup'] = attribution.adsetId!;
        }
        if (attribution.adId != null) {
          attributes[r'$ad'] = attribution.adId!;
        }
        if (attribution.keyword != null) {
          attributes[r'$keyword'] = attribution.keyword!;
        }
      }

      if (attributes.isEmpty) {
        return;
      }

      // TODO(partnership): Replace with Purchases.setEchoStackAttributionParams(attributes)
      await setAttributes(attributes);
    } catch (_) {
      // Never crash the host app — RevenueCat sync is best-effort
    }
  }

  /// Sync EchoStack attribution with Superwall for campaign-targeted paywalls.
  /// Call after both SDKs are configured, before the first
  /// `Superwall.shared.register()` call.
  ///
  /// Sets the following Superwall user attributes:
  /// - `echostack_id`: The unique device installation ID.
  /// - Attribution parameters (network, campaign_id, campaign_name, etc.)
  ///   when available.
  ///
  /// Requires the `superwallkit_flutter` package to be installed in the host
  /// app. The host app must pass the Superwall `setUserAttributes` function
  /// since Dart does not support optional dynamic imports.
  ///
  /// Example:
  /// ```dart
  /// import 'package:superwallkit_flutter/superwallkit_flutter.dart';
  ///
  /// await EchoStackPlugin.syncWithSuperwall(
  ///   setUserAttributes: (attrs) => Superwall.shared.setUserAttributes(attrs),
  /// );
  /// ```
  ///
  /// TODO(partnership): When EchoStack is a recognized Superwall partner,
  /// use `Superwall.shared.setIntegrationAttribute()` instead of
  /// `setUserAttributes()`.
  static Future<void> syncWithSuperwall({
    required void Function(Map<String, dynamic> attributes) setUserAttributes,
  }) async {
    try {
      final echoStackId = await getEchoStackId();
      if (echoStackId == null) {
        return;
      }

      // TODO(partnership): Replace with Superwall.shared.setIntegrationAttribute(IntegrationAttribute.echoStackId, echoStackId)
      setUserAttributes({'echostack_id': echoStackId});

      // Forward attribution parameters if available
      final attribution = await getAttributionParams();
      if (attribution != null) {
        // TODO(partnership): Replace with Superwall.shared.setIntegrationAttribute() calls
        final attrs = <String, dynamic>{};
        if (attribution.network != null) attrs['network'] = attribution.network;
        if (attribution.campaignId != null) {
          attrs['campaign_id'] = attribution.campaignId;
        }
        if (attribution.campaignName != null) {
          attrs['campaign_name'] = attribution.campaignName;
        }
        if (attribution.adsetId != null) attrs['adset_id'] = attribution.adsetId;
        if (attribution.adId != null) attrs['ad_id'] = attribution.adId;
        if (attribution.keyword != null) attrs['keyword'] = attribution.keyword;
        attrs['match_type'] = attribution.matchType;
        attrs['confidence'] = attribution.confidence;

        setUserAttributes(attrs);
      }
    } catch (_) {
      // Never crash the host app — Superwall sync is best-effort
    }
  }
}
