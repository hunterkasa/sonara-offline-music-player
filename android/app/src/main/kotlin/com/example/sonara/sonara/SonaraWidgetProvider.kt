package com.example.sonara.sonara

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.KeyEvent
import android.widget.RemoteViews

open class BaseSonaraWidgetProvider : AppWidgetProvider() {
    companion object {
        const val ACTION_PLAY_PAUSE = "com.example.sonara.widget.PLAY_PAUSE"
        const val ACTION_NEXT = "com.example.sonara.widget.NEXT"
        const val ACTION_PREV = "com.example.sonara.widget.PREV"

        const val PREFS_NAME = "sonara_widget_prefs"
        const val KEY_TITLE = "title"
        const val KEY_ARTIST = "artist"
        const val KEY_IS_PLAYING = "is_playing"

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

            // 1. Standard Widget
            val standardWidget = ComponentName(context, SonaraWidgetProvider::class.java)
            for (id in appWidgetManager.getAppWidgetIds(standardWidget)) {
                SonaraWidgetProvider.updateAppWidget(context, appWidgetManager, id, title, artist, isPlaying)
            }

            // 2. Pill Widget
            val pillWidget = ComponentName(context, SonaraPillWidgetProvider::class.java)
            for (id in appWidgetManager.getAppWidgetIds(pillWidget)) {
                SonaraPillWidgetProvider.updateAppWidget(context, appWidgetManager, id, title, artist, isPlaying)
            }

            // 3. Large Widget
            val largeWidget = ComponentName(context, SonaraLargeWidgetProvider::class.java)
            for (id in appWidgetManager.getAppWidgetIds(largeWidget)) {
                SonaraLargeWidgetProvider.updateAppWidget(context, appWidgetManager, id, title, artist, isPlaying)
            }
        }

        fun sendMediaKeyEvent(context: Context, keyCode: Int) {
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

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            ACTION_PLAY_PAUSE -> sendMediaKeyEvent(context, KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE)
            ACTION_NEXT -> sendMediaKeyEvent(context, KeyEvent.KEYCODE_MEDIA_NEXT)
            ACTION_PREV -> sendMediaKeyEvent(context, KeyEvent.KEYCODE_MEDIA_PREVIOUS)
        }
    }
}

/** Standard Medium Widget */
class SonaraWidgetProvider : BaseSonaraWidgetProvider() {
    companion object {
        fun updateWidgetState(
            context: Context,
            title: String,
            artist: String,
            isPlaying: Boolean
        ) {
            BaseSonaraWidgetProvider.updateWidgetState(context, title, artist, isPlaying)
        }

        fun updateAppWidget(
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

            val openAppIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            views.setOnClickPendingIntent(
                R.id.widget_container,
                PendingIntent.getActivity(context, 0, openAppIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            )

            views.setOnClickPendingIntent(
                R.id.widget_btn_play_pause,
                PendingIntent.getBroadcast(context, 1, Intent(context, SonaraWidgetProvider::class.java).apply { action = ACTION_PLAY_PAUSE }, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            )
            views.setOnClickPendingIntent(
                R.id.widget_btn_next,
                PendingIntent.getBroadcast(context, 2, Intent(context, SonaraWidgetProvider::class.java).apply { action = ACTION_NEXT }, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            )
            views.setOnClickPendingIntent(
                R.id.widget_btn_prev,
                PendingIntent.getBroadcast(context, 3, Intent(context, SonaraWidgetProvider::class.java).apply { action = ACTION_PREV }, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            )

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val title = prefs.getString(KEY_TITLE, "") ?: ""
        val artist = prefs.getString(KEY_ARTIST, "") ?: ""
        val isPlaying = prefs.getBoolean(KEY_IS_PLAYING, false)

        for (widgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, widgetId, title, artist, isPlaying)
        }
    }
}

/** 2x1 Minimalist Pill Widget */
class SonaraPillWidgetProvider : BaseSonaraWidgetProvider() {
    companion object {
        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
            title: String,
            artist: String,
            isPlaying: Boolean
        ) {
            val views = RemoteViews(context.packageName, R.layout.sonara_widget_pill_layout)

            views.setTextViewText(R.id.widget_pill_title, if (title.isNotEmpty()) title else context.getString(R.string.widget_no_track))
            views.setTextViewText(R.id.widget_pill_artist, if (artist.isNotEmpty()) artist else context.getString(R.string.widget_tap_to_open))

            val playPauseIcon = if (isPlaying) R.drawable.ic_widget_pause else R.drawable.ic_widget_play
            views.setImageViewResource(R.id.widget_pill_btn_play_pause, playPauseIcon)

            val openAppIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            views.setOnClickPendingIntent(
                R.id.widget_pill_container,
                PendingIntent.getActivity(context, 10, openAppIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            )

            views.setOnClickPendingIntent(
                R.id.widget_pill_btn_play_pause,
                PendingIntent.getBroadcast(context, 11, Intent(context, SonaraPillWidgetProvider::class.java).apply { action = ACTION_PLAY_PAUSE }, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            )

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val title = prefs.getString(KEY_TITLE, "") ?: ""
        val artist = prefs.getString(KEY_ARTIST, "") ?: ""
        val isPlaying = prefs.getBoolean(KEY_IS_PLAYING, false)

        for (widgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, widgetId, title, artist, isPlaying)
        }
    }
}

/** 4x2 Large Artwork & Controls Widget */
class SonaraLargeWidgetProvider : BaseSonaraWidgetProvider() {
    companion object {
        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
            title: String,
            artist: String,
            isPlaying: Boolean
        ) {
            val views = RemoteViews(context.packageName, R.layout.sonara_widget_large_layout)

            views.setTextViewText(R.id.widget_large_title, if (title.isNotEmpty()) title else context.getString(R.string.widget_no_track))
            views.setTextViewText(R.id.widget_large_artist, if (artist.isNotEmpty()) artist else context.getString(R.string.widget_tap_to_open))

            val playPauseIcon = if (isPlaying) R.drawable.ic_widget_pause else R.drawable.ic_widget_play
            views.setImageViewResource(R.id.widget_large_btn_play_pause, playPauseIcon)

            val openAppIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            views.setOnClickPendingIntent(
                R.id.widget_large_container,
                PendingIntent.getActivity(context, 20, openAppIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            )

            views.setOnClickPendingIntent(
                R.id.widget_large_btn_play_pause,
                PendingIntent.getBroadcast(context, 21, Intent(context, SonaraLargeWidgetProvider::class.java).apply { action = ACTION_PLAY_PAUSE }, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            )
            views.setOnClickPendingIntent(
                R.id.widget_large_btn_next,
                PendingIntent.getBroadcast(context, 22, Intent(context, SonaraLargeWidgetProvider::class.java).apply { action = ACTION_NEXT }, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            )
            views.setOnClickPendingIntent(
                R.id.widget_large_btn_prev,
                PendingIntent.getBroadcast(context, 23, Intent(context, SonaraLargeWidgetProvider::class.java).apply { action = ACTION_PREV }, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            )

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val title = prefs.getString(KEY_TITLE, "") ?: ""
        val artist = prefs.getString(KEY_ARTIST, "") ?: ""
        val isPlaying = prefs.getBoolean(KEY_IS_PLAYING, false)

        for (widgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, widgetId, title, artist, isPlaying)
        }
    }
}
