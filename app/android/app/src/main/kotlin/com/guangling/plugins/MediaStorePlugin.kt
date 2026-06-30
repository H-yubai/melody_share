package com.guangling.plugin

import android.app.Activity
import android.app.RecoverableSecurityException
import android.content.ContentUris
import android.content.Intent
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MediaStorePlugin(private val activity: Activity) : MethodChannel.MethodCallHandler {
    
    companion object {
        private const val CHANNEL_NAME = "guangling/mediastore"
        private const val DELETE_REQUEST_CODE = 2333
    }

    private var pendingResult: MethodChannel.Result? = null

    fun register(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME).setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "scanAudio" -> scanAudio(result)
            "deleteAudioFile" -> deleteAudioFile(call, result)
            else -> result.notImplemented()
        }
    }

    fun handleActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == DELETE_REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK) {
                pendingResult?.success(true)
            } else {
                pendingResult?.success(false)
            }
            pendingResult = null
        }
    }

    private fun deleteAudioFile(call: MethodCall, result: MethodChannel.Result) {
        val filePath = call.argument<String>("filePath") ?: ""
        if (filePath.isEmpty()) {
            result.success(false)
            return
        }

        pendingResult = result

        MediaScannerConnection.scanFile(activity, arrayOf(filePath), null) { _, _ ->
            val mediaUri = getAudioUriFromPathImproved(filePath)
            
            activity.runOnUiThread {
                if (mediaUri == null) {
                    val file = File(filePath)
                    if (file.exists() && file.delete()) {
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                    pendingResult = null
                    return@runOnUiThread
                }
                
                executeMediaStoreDelete(mediaUri)
            }
        }
    }

    private fun executeMediaStoreDelete(mediaUri: Uri) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                val uriList = listOf(mediaUri)
                val pendingIntent = MediaStore.createDeleteRequest(activity.contentResolver, uriList)
                activity.startIntentSenderForResult(
                    pendingIntent.intentSender,
                    DELETE_REQUEST_CODE,
                    null, 0, 0, 0
                )
            } else {
                try {
                    val rows = activity.contentResolver.delete(mediaUri, null, null)
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
                            activity.startIntentSenderForResult(intentSender, DELETE_REQUEST_CODE, null, 0, 0, 0)
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
            android.util.Log.e("MediaStorePlugin", "触发删除通道异常", e)
            pendingResult?.error("DELETE_FAILED", e.message, null)
            pendingResult = null
        }
    }

    private fun getAudioUriFromPathImproved(path: String): Uri? {
        val file = File(path)
        val displayName = file.name

        val cursor = activity.contentResolver.query(
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

        val fallbackCursor = activity.contentResolver.query(
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

    private fun scanAudio(result: MethodChannel.Result) {
        val audioList = mutableListOf<Map<String, Any?>>()
        val projection = arrayOf(
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
            val cursor = activity.contentResolver.query(
                MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                projection,
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

                    val file = File(filePath)
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