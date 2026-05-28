package com.melodyshare.melody_share

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.media.session.MediaSession
import android.media.session.PlaybackState
import android.os.Build
import android.os.IBinder
import android.os.SystemClock
import androidx.core.app.NotificationCompat
import androidx.media.app.NotificationCompat.MediaStyle
import io.flutter.plugin.common.MethodChannel

class MediaSessionService : Service() {

    companion object {
        const val CHANNEL_ID = "melody_share_media"
        const val NOTIFICATION_ID = 1
        const val METHOD_CHANNEL = "melody_share/media_session"

        var methodChannel: MethodChannel? = null
    }

    private var mediaSession: MediaSession? = null
    private var isPlaying = false
    private var title = ""
    private var artist = ""
    private var album = ""
    private var albumArtPath: String? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        createMediaSession()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.getStringExtra("action")) {
            "start" -> {
                title = intent.getStringExtra("title") ?: ""
                artist = intent.getStringExtra("artist") ?: ""
                album = intent.getStringExtra("album") ?: ""
                albumArtPath = intent.getStringExtra("albumArtPath")
                isPlaying = true
                updateMediaSession()
                startForeground(NOTIFICATION_ID, buildNotification())
            }
            "update" -> {
                title = intent.getStringExtra("title") ?: ""
                artist = intent.getStringExtra("artist") ?: ""
                album = intent.getStringExtra("album") ?: ""
                albumArtPath = intent.getStringExtra("albumArtPath")
                updateMediaSession()
                updateNotification()
            }
            "setPlaying" -> {
                isPlaying = intent.getBooleanExtra("playing", false)
                updateMediaSession()
                updateNotification()
                if (!isPlaying) {
                    stopForeground(STOP_FOREGROUND_DETACH)
                }
            }
            "stop" -> {
                isPlaying = false
                mediaSession?.isActive = false
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
            else -> {
                when (intent?.action) {
                    ACTION_PLAY -> sendToFlutter("play")
                    ACTION_PAUSE -> sendToFlutter("pause")
                    ACTION_NEXT -> sendToFlutter("next")
                    ACTION_PREVIOUS -> sendToFlutter("previous")
                    ACTION_STOP -> sendToFlutter("stop")
                }
            }
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        mediaSession?.release()
        mediaSession = null
        super.onDestroy()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Music Playback",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Music playback controls"
                setShowBadge(false)
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    private fun createMediaSession() {
        mediaSession = MediaSession(this, "MelodyShareMediaSession").apply {
            setCallback(object : MediaSession.Callback() {
                override fun onPlay() {
                    sendToFlutter("play")
                }
                override fun onPause() {
                    sendToFlutter("pause")
                }
                override fun onSkipToNext() {
                    sendToFlutter("next")
                }
                override fun onSkipToPrevious() {
                    sendToFlutter("previous")
                }
                override fun onStop() {
                    sendToFlutter("stop")
                }
            })
            isActive = true
        }
    }

    private fun updateMediaSession() {
        val session = mediaSession ?: return

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val metadata = android.media.MediaMetadata.Builder()
                .putString(android.media.MediaMetadata.METADATA_KEY_TITLE, title)
                .putString(android.media.MediaMetadata.METADATA_KEY_ARTIST, artist)
                .putString(android.media.MediaMetadata.METADATA_KEY_ALBUM, album)
                .build()
            session.setMetadata(metadata)
        }

        val state = PlaybackState.Builder()
            .setActions(
                PlaybackState.ACTION_PLAY or
                PlaybackState.ACTION_PAUSE or
                PlaybackState.ACTION_PLAY_PAUSE or
                PlaybackState.ACTION_SKIP_TO_NEXT or
                PlaybackState.ACTION_SKIP_TO_PREVIOUS or
                PlaybackState.ACTION_STOP
            )
            .setState(
                if (isPlaying) PlaybackState.STATE_PLAYING else PlaybackState.STATE_PAUSED,
                SystemClock.elapsedRealtime(),
                1.0f
            )
            .build()
        session.setPlaybackState(state)
    }

    @Suppress("DEPRECATION")
    private fun buildNotification(): Notification {
        val playPauseAction = if (isPlaying) ACTION_PAUSE else ACTION_PLAY
        val playPauseIcon = if (isPlaying)
            android.R.drawable.ic_media_pause else android.R.drawable.ic_media_play

        val pfFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
            PendingIntent.FLAG_IMMUTABLE else 0

        val prevIntent = Intent(this, MediaSessionService::class.java).apply {
            action = ACTION_PREVIOUS
        }
        val playPauseIntent = Intent(this, MediaSessionService::class.java).apply {
            action = playPauseAction
        }
        val nextIntent = Intent(this, MediaSessionService::class.java).apply {
            action = ACTION_NEXT
        }
        val stopIntent = Intent(this, MediaSessionService::class.java).apply {
            action = ACTION_STOP
        }

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_media_play)
            .setContentTitle(title)
            .setContentText(artist)
            .setSubText(album)
            .setOngoing(true)
            .setShowWhen(false)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setCategory(NotificationCompat.CATEGORY_TRANSPORT)
            .setStyle(
                MediaStyle()
                    .setShowActionsInCompactView(0, 1, 2)
            )
            .addAction(
                NotificationCompat.Action(
                    android.R.drawable.ic_media_previous,
                    "Previous",
                    PendingIntent.getService(this, 0, prevIntent, pfFlags)
                )
            )
            .addAction(
                NotificationCompat.Action(
                    playPauseIcon,
                    if (isPlaying) "Pause" else "Play",
                    PendingIntent.getService(this, 1, playPauseIntent, pfFlags)
                )
            )
            .addAction(
                NotificationCompat.Action(
                    android.R.drawable.ic_media_next,
                    "Next",
                    PendingIntent.getService(this, 2, nextIntent, pfFlags)
                )
            )
            .setDeleteIntent(
                PendingIntent.getService(this, 3, stopIntent, pfFlags)
            )

        if (!albumArtPath.isNullOrEmpty()) {
            try {
                val bitmap = BitmapFactory.decodeFile(albumArtPath)
                if (bitmap != null) builder.setLargeIcon(bitmap)
            } catch (_: Exception) {}
        }

        val contentIntent = packageManager.getLaunchIntentForPackage(packageName)
        if (contentIntent != null) {
            builder.setContentIntent(
                PendingIntent.getActivity(this, 4, contentIntent, pfFlags)
            )
        }

        return builder.build()
    }

    private fun updateNotification() {
        try {
            startForeground(NOTIFICATION_ID, buildNotification())
        } catch (_: Exception) {}
    }

    private fun sendToFlutter(action: String) {
        methodChannel?.invokeMethod(action, null)
    }
}

private const val ACTION_PLAY = "play"
private const val ACTION_PAUSE = "pause"
private const val ACTION_NEXT = "next"
private const val ACTION_PREVIOUS = "previous"
private const val ACTION_STOP = "stop"
