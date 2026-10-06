package com.example.sonara.sonara

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.KeyEvent
import android.widget.RemoteViews

class SonaraWidgetProvider : AppWidgetProvider() {

    companion object {
        const val ACTION_PLAY_PAUSE = "com.example.sonara.widget.PLAY_PAUSE"
        const val ACTION_NEXT = "com.example.sonara.widget.NEXT"
        const val ACTION_PREV = "com.example.sonara.widget.PREV"

        private const val PREFS_NAME = "sonara_widget_prefs"
        private const val KEY_TITLE = "title"
        private const val KEY_ARTIST = "artist"
        private const val KEY_IS_PLAYING = "is_playing"

        fun updateWidgetState(
            context: Context,
            title: String,
            artist: String,
            isPlaying: Boolean
        ) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit()
                .putString(KEY_TITLE, title)
                .putString(KEY_ARTIST, artist)
                .putBoolean(KEY_IS_PLAYING, isPlaying)
                .apply()

            val appWidgetManager = AppWidgetManager.getInstance(context)
            val thisWidget = ComponentName(context, SonaraWidgetProvider::class.java)
            val allWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)

            for (widgetId in allWidgetIds) {
                updateAppWidget(context, appWidgetManager, widgetId, title, artist, isPlaying)
            }
        }

        private fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
            title: String,
            artist: String,
            isPlaying: Boolean
        ) {
            val views = RemoteViews(context.packageName, R.layout.sonara_widget_layout)

            views.setTextViewText(R.id.widget_title, if (title.isNotEmpty()) title else context.getString(R.string.widget_no_track))
            views.setTextViewText(R.id.widget_artist, if (artist.isNotEmpty()) artist else context.getString(R.string.widget_tap_to_open))

            val playPauseIcon = if (isPlaying) R.drawable.ic_widget_pause else R.drawable.ic_widget_play
            views.setImageViewResource(R.id.widget_btn_play_pause, playPauseIcon)

            // Intent to open app when tapping widget body
            val openAppIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            val openAppPendingIntent = PendingIntent.getActivity(
                context,
                0,
                openAppIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_container, openAppPendingIntent)

            // Play/Pause intent
            val playPauseIntent = Intent(context, SonaraWidgetProvider::class.java).apply {
                action = ACTION_PLAY_PAUSE
            }
            val playPausePendingIntent = PendingIntent.getBroadcast(
                context,
                1,
                playPauseIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_btn_play_pause, playPausePendingIntent)

            // Next intent
            val nextIntent = Intent(context, SonaraWidgetProvider::class.java).apply {
                action = ACTION_NEXT
            }
            val nextPendingIntent = PendingIntent.getBroadcast(
                context,
                2,
                nextIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_btn_next, nextPendingIntent)

            // Previous intent
            val prevIntent = Intent(context, SonaraWidgetProvider::class.java).apply {
                action = ACTION_PREV
            }
            val prevPendingIntent = PendingIntent.getBroadcast(
                context,
                3,
                prevIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_btn_prev, prevPendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val title = prefs.getString(KEY_TITLE, "") ?: ""
        val artist = prefs.getString(KEY_ARTIST, "") ?: ""
        val isPlaying = prefs.getBoolean(KEY_IS_PLAYING, false)

        for (widgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, widgetId, title, artist, isPlaying)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            ACTION_PLAY_PAUSE -> sendMediaKeyEvent(context, KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE)
            ACTION_NEXT -> sendMediaKeyEvent(context, KeyEvent.KEYCODE_MEDIA_NEXT)
            ACTION_PREV -> sendMediaKeyEvent(context, KeyEvent.KEYCODE_MEDIA_PREVIOUS)
        }
    }

    private fun sendMediaKeyEvent(context: Context, keyCode: Int) {
        val mediaIntent = Intent(Intent.ACTION_MEDIA_BUTTON).apply {
            setClassName(context, "com.ryanheise.audioservice.MediaButtonReceiver")
            putExtra(Intent.EXTRA_KEY_EVENT, KeyEvent(KeyEvent.ACTION_DOWN, keyCode))
        }
        context.sendBroadcast(mediaIntent)

        val mediaUpIntent = Intent(Intent.ACTION_MEDIA_BUTTON).apply {
            setClassName(context, "com.ryanheise.audioservice.MediaButtonReceiver")
            putExtra(Intent.EXTRA_KEY_EVENT, KeyEvent(KeyEvent.ACTION_UP, keyCode))
        }
        context.sendBroadcast(mediaUpIntent)
    }
}
