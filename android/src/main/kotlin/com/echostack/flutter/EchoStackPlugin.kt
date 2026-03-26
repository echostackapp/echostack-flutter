package com.echostack.flutter

import android.content.Context
import com.echostack.sdk.EchoStack
import com.echostack.sdk.LogLevel
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * Flutter plugin bridge to native EchoStack Android SDK.
 */
class EchoStackPlugin : FlutterPlugin, MethodCallHandler {

    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "echostack_plugin")
        channel.setMethodCallHandler(this)
        context = binding.applicationContext
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "configure" -> {
                val apiKey = call.argument<String>("apiKey") ?: ""
                val serverURL = call.argument<String>("serverURL") ?: "https://api.echostack.app"
                val logLevelStr = call.argument<String>("logLevel") ?: "none"

                val logLevel = when (logLevelStr) {
                    "debug" -> LogLevel.DEBUG
                    "warning" -> LogLevel.WARNING
                    "error" -> LogLevel.ERROR
                    else -> LogLevel.NONE
                }

                EchoStack.configure(context, apiKey, serverURL, logLevel)
                result.success(null)
            }

            "enableAppleAdsAttribution" -> {
                // Not available on Android
                result.success(false)
            }

            "getEchoStackId" -> {
                result.success(EchoStack.getEchoStackId())
            }

            "getAttributionParams" -> {
                val params = EchoStack.getAttributionParams()
                result.success(params)
            }

            "isSdkDisabled" -> {
                result.success(EchoStack.isSdkDisabled())
            }

            "sendEvent" -> {
                val eventType = call.argument<String>("eventType") ?: ""
                val parameters = call.argument<Map<String, Any>>("parameters")
                EchoStack.sendEvent(eventType, parameters)
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }
}
