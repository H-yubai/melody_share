package com.guangling

import android.app.Activity
import android.app.RecoverableSecurityException
import android.content.Intent
import android.content.IntentSender
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.MediaStore
import android.content.ContentUris
import androidx.activity.result.IntentSenderRequest
import androidx.activity.result.contract.ActivityResultContracts

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val DELETE_REQUEST_CODE = 2333
    private var pendingResult: MethodChannel.Result? = null
    private var pendingIntentSender: IntentSender? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "guangling/mediastore"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "scanAudio" -> scanAudio(result)
                "deleteAudioFile" -> deleteAudioFile(call, result)
                else -> result.notImplemented()
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

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == DELETE_REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK) {
                pendingResult?.success(true)
            } else {
                pendingResult?.success(false)
            }
            pendingResult = null
        }
    }

    private fun getAudioUriFromPathImproved(path: String): Uri? {
        val file = java.io.File(path)
        val displayName = file.name

        // 尝试通过 DISPLAY_NAME 匹配
        val cursor = contentResolver.query(
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
            arrayOf(MediaStore.Audio.Media._ID),
            "${MediaStore.Audio.Media.DISPLAY_NAME} = ?",
            arrayOf(displayName),
            null
        )

        cursor?.use {
            if (it.moveToFirst()) {
                val id = it.getLong(it.getColumnIndexOrThrow(MediaStore.Audio.Media._ID))
                return ContentUris.withAppendedId(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, id)
            }
        }

        // 如果上面查不到，再降级使用 DATA 字段（兼容低版本）
        val fallbackCursor = contentResolver.query(
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
            arrayOf(MediaStore.Audio.Media._ID),
            "${MediaStore.Audio.Media.DATA} = ?",
            arrayOf(path),
            null
        )
        fallbackCursor?.use {
            if (it.moveToFirst()) {
                val id = it.getLong(it.getColumnIndexOrThrow(MediaStore.Audio.Media._ID))
                return ContentUris.withAppendedId(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, id)
            }
        }

        return null
    }

    private fun deleteAudioFile(call: MethodCall, result: MethodChannel.Result) {
        val filePath = call.argument<String>("filePath") ?: ""
        if (filePath.isEmpty()) {
            result.success(false)
            return
        }

        pendingResult = result

        // 核心改进：调用媒体扫描器，强行让系统给这个物理文件登记户口
        MediaScannerConnection.scanFile(this, arrayOf(filePath), null) { _, _ ->
            // 扫描完成后（在子线程回调），重新在媒体库里查一次 Uri
            val mediaUri = getAudioUriFromPathImproved(filePath)
            
            // 切换回主线程来处理 UI 弹窗和结果返回
            runOnUiThread {
                if (mediaUri == null) {
                    // 此时如果还查不到，说明文件确实不归 MediaStore 管或者文件已经彻底没了
                    android.util.Log.d("MediaStoreScanner", "扫描后仍无法在媒体库中找到该文件的 Uri: $filePath")
                    
                    // 最后的挣扎：尝试物理删除
                    val file = java.io.File(filePath)
                    if (file.exists() && file.delete()) {
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                    pendingResult = null
                    return@runOnUiThread
                }
                
                // 顺利拿到 Uri！开始触发系统的删除确认弹窗
                executeMediaStoreDelete(mediaUri)
            }
        }
    }

    private fun executeMediaStoreDelete(mediaUri: Uri) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                // Android 11+ 标准弹窗
                val uriList = listOf(mediaUri)
                val pendingIntent = MediaStore.createDeleteRequest(contentResolver, uriList)
                pendingIntentSender = pendingIntent.intentSender
                startIntentSenderForResult(
                    pendingIntent.intentSender,
                    DELETE_REQUEST_CODE,
                    null, 0, 0, 0
                )
            } else {
                // Android 10 捕获异常触发弹窗
                try {
                    val rows = contentResolver.delete(mediaUri, null, null)
                    if (rows > 0) {
                        pendingResult?.success(true)
                        pendingResult = null
                    } else {
                        pendingResult?.success(false)
                        pendingResult = null
                    }
                } catch (securityException: SecurityException) {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        val recoverableSecurityException = securityException as? RecoverableSecurityException
                        val intentSender = recoverableSecurityException?.userAction?.actionIntent?.intentSender
                        if (intentSender != null) {
                            pendingIntentSender = intentSender
                            startIntentSenderForResult(intentSender, DELETE_REQUEST_CODE, null, 0, 0, 0)
                        } else {
                            pendingResult?.success(false)
                            pendingResult = null
                        }
                    } else {
                        pendingResult?.success(false)
                        pendingResult = null
                    }
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("MediaStoreScanner", "触发删除通道异常", e)
            pendingResult?.error("DELETE_FAILED", e.message, null)
            pendingResult = null
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

                     // Check if the file actually exists
                     val file = java.io.File(filePath)
                     if (!file.exists()) continue

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
