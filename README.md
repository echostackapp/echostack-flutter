# EchoStack Flutter Plugin

Flutter plugin for EchoStack mobile attribution. Thin Dart wrapper over native iOS and Android SDKs via platform channels.

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  echostack_plugin: ^1.0.0
```

Then run:
```bash
flutter pub get
```

### Requirements

- Flutter 3.10+
- Dart 3.0+
- iOS 14.0+ / Android API 21+

## Quick Start

```dart
import 'package:echostack_plugin/echostack_plugin.dart';

// 1. Configure at app startup
await EchoStackPlugin.configure('es_live_...');

// 2. Track events
await EchoStackPlugin.sendEvent('purchase', parameters: {
  'revenue': 29.99,
  'currency': 'USD',
});

// 3. Get attribution
final attribution = await EchoStackPlugin.getAttributionParams();
```

## API

```dart
EchoStackPlugin.configure(String apiKey, {String serverURL, String logLevel})
EchoStackPlugin.sendEvent(String eventType, {Map<String, dynamic>? parameters})
EchoStackPlugin.getEchoStackId() → Future<String?>
EchoStackPlugin.getAttributionParams() → Future<Attribution?>
EchoStackPlugin.isSdkDisabled() → Future<bool>
EchoStackPlugin.enableAppleAdsAttribution() → Future<bool>
```

## License

MIT
