package com.guangling.plugin

import android.content.Context
import android.content.Intent
import com.guangling.MediaSessionService
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MediaSessionPlugin(private val context: Context) : MethodChannel.MethodCallHandler {

    fun register(flutterEngine: FlutterEngine) {
        MediaSessionService.methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            MediaSessionService.METHOD_CHANNEL
        ).apply {
            setMethodCallHandler(this@MediaSessionPlugin)
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val serviceIntent = Intent(context, MediaSessionService::class.java)
        
        when (call.method) {
            "start" -> {
                serviceIntent.putExtra("action", "start")
                call.argument<String>("title")?.let { serviceIntent.putExtra("title", it) }
                call.argument<String>("artist")?.let { serviceIntent.putExtra("artist", it) }
                call.argument<String>("album")?.let { serviceIntent.putExtra("album", it) }
                call.argument<String>("albumArtPath")?.let { serviceIntent.putExtra("albumArtPath", it) }
                context.startForegroundService(serviceIntent)
                result.success(null)
            }
            "update" -> {
                serviceIntent.putExtra("action", "update")
                call.argument<String>("title")?.let { serviceIntent.putExtra("title", it) }
                call.argument<String>("artist")?.let { serviceIntent.putExtra("artist", it) }
                call.argument<String>("album")?.let { serviceIntent.putExtra("album", it) }
                call.argument<String>("albumArtPath")?.let { serviceIntent.putExtra("albumArtPath", it) }
                context.startService(serviceIntent)
                result.success(null)
            }
            "setPlaying" -> {
                serviceIntent.putExtra("action", "setPlaying")
                serviceIntent.putExtra("playing", call.arguments as? Boolean ?: false)
                context.startService(serviceIntent)
                result.success(null)
            }
            "stop" -> {
                serviceIntent.putExtra("action", "stop")
                context.startService(serviceIntent)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }
}