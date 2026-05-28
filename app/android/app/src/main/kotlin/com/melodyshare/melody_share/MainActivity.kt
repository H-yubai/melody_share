package com.melodyshare.melody_share

import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "melody_share/mediastore"
        ).setMethodCallHandler { call, result ->
            if (call.method == "scanAudio") {
                scanAudio(result)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun scanAudio(result: MethodChannel.Result) {
        val audioList = mutableListOf<Map<String, Any?>>()
        val projection = arrayOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.DATA,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.ALBUM,
            MediaStore.Audio.Media.DURATION,
        )

        try {
            val cursor = contentResolver.query(
                MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                projection,
                "${MediaStore.Audio.Media.IS_MUSIC} = 1",
                null,
                null
            )

            cursor?.use {
                val idCol = it.getColumnIndex(MediaStore.Audio.Media._ID)
                val dataCol = it.getColumnIndex(MediaStore.Audio.Media.DATA)
                val titleCol = it.getColumnIndex(MediaStore.Audio.Media.TITLE)
                val artistCol = it.getColumnIndex(MediaStore.Audio.Media.ARTIST)
                val albumCol = it.getColumnIndex(MediaStore.Audio.Media.ALBUM)
                val durationCol = it.getColumnIndex(MediaStore.Audio.Media.DURATION)

                while (it.moveToNext()) {
                    val filePath = if (dataCol >= 0) it.getString(dataCol) else null
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
