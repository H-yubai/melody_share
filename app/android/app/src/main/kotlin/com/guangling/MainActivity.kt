package com.guangling

import android.content.Intent
import android.os.Bundle
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "guangling/mediastore"
        ).setMethodCallHandler { call, result ->
            if (call.method == "scanAudio") {
                scanAudio(result)
            } else {
                result.notImplemented()
            }
        }

        val serviceIntent = Intent(this, MediaSessionService::class.java)
        MediaSessionService.methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            MediaSessionService.METHOD_CHANNEL
        ).apply {
            setMethodCallHandler { call, _ ->
                when (call.method) {
                    "start" -> {
                        val args = call.arguments as? Map<*, *>
                        serviceIntent.putExtra("action", "start")
                        call.argument<String>("title")?.let { serviceIntent.putExtra("title", it) }
                        call.argument<String>("artist")?.let { serviceIntent.putExtra("artist", it) }
                        call.argument<String>("album")?.let { serviceIntent.putExtra("album", it) }
                        call.argument<String>("albumArtPath")?.let { serviceIntent.putExtra("albumArtPath", it) }
                        startForegroundService(serviceIntent)
                    }
                    "update" -> {
                        val args = call.arguments as? Map<*, *>
                        serviceIntent.putExtra("action", "update")
                        call.argument<String>("title")?.let { serviceIntent.putExtra("title", it) }
                        call.argument<String>("artist")?.let { serviceIntent.putExtra("artist", it) }
                        call.argument<String>("album")?.let { serviceIntent.putExtra("album", it) }
                        call.argument<String>("albumArtPath")?.let { serviceIntent.putExtra("albumArtPath", it) }
                        startService(serviceIntent)
                    }
                    "setPlaying" -> {
                        serviceIntent.putExtra("action", "setPlaying")
                        serviceIntent.putExtra("playing", call.arguments as? Boolean ?: false)
                        startService(serviceIntent)
                    }
                    "stop" -> {
                        serviceIntent.putExtra("action", "stop")
                        startService(serviceIntent)
                    }
                }
            }
        }
    }

    private fun scanAudio(result: MethodChannel.Result) {
        val audioList = mutableListOf<Map<String, Any?>>()
        val projection = mutableListOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.DATA,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.ALBUM,
            MediaStore.Audio.Media.DURATION,
            MediaStore.Audio.Media.RELATIVE_PATH,
            MediaStore.Audio.Media.DISPLAY_NAME,
        )

        try {
            val cursor = contentResolver.query(
                MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                projection.toTypedArray(),
                null,
                null,
                null
            )

            val storageRoot = android.os.Environment.getExternalStorageDirectory().absolutePath

            cursor?.use {
                val idCol = it.getColumnIndex(MediaStore.Audio.Media._ID)
                val dataCol = it.getColumnIndex(MediaStore.Audio.Media.DATA)
                val titleCol = it.getColumnIndex(MediaStore.Audio.Media.TITLE)
                val artistCol = it.getColumnIndex(MediaStore.Audio.Media.ARTIST)
                val albumCol = it.getColumnIndex(MediaStore.Audio.Media.ALBUM)
                val durationCol = it.getColumnIndex(MediaStore.Audio.Media.DURATION)
                val relativePathCol = it.getColumnIndex(MediaStore.Audio.Media.RELATIVE_PATH)
                val displayNameCol = it.getColumnIndex(MediaStore.Audio.Media.DISPLAY_NAME)

                while (it.moveToNext()) {
                    // Try DATA column first; fall back to RELATIVE_PATH + DISPLAY_NAME
                    // (DATA is deprecated on API 29+ and may be null)
                    var filePath = if (dataCol >= 0) it.getString(dataCol) else null
                    if (filePath.isNullOrEmpty() && relativePathCol >= 0 && displayNameCol >= 0) {
                        val relPath = it.getString(relativePathCol) ?: ""
                        val dispName = it.getString(displayNameCol) ?: ""
                        if (relPath.isNotEmpty() && dispName.isNotEmpty()) {
                            filePath = "$storageRoot/$relPath/$dispName"
                        }
                    }
                    if (filePath.isNullOrEmpty()) continue

                    val ext = filePath.substringAfterLast('.', "").lowercase()
                    if (ext !in listOf("mp3", "wav", "flac", "aac", "ogg", "m4a", "wma")) continue

                    audioList.add(mapOf(
                        "id" to (if (idCol >= 0) it.getLong(idCol).toString() else ""),
                        "filePath" to filePath,
                        "title" to (if (titleCol >= 0) it.getString(titleCol) ?: "" else ""),
                        "artist" to (if (artistCol >= 0) it.getString(artistCol) ?: "" else ""),
                        "album" to (if (albumCol >= 0) it.getString(albumCol) ?: "" else ""),
                        "durationMs" to (if (durationCol >= 0) it.getInt(durationCol) else 0),
                        "extension" to ext,
                    ))
                }
            }
            result.success(audioList)
        } catch (e: Exception) {
            result.success(audioList)
        }
    }
}
