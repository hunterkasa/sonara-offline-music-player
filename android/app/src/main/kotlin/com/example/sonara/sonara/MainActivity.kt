package com.example.sonara.sonara

import android.content.ContentUris
import android.content.Intent
import android.database.ContentObserver
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    private val METHOD_CHANNEL = "com.example.sonara/mediastore"
    private val EVENT_CHANNEL = "com.example.sonara/mediastore_observer"

    private var contentObserver: ContentObserver? = null
    private var eventSink: EventChannel.EventSink? = null
    private var initialAudioUri: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
        initialAudioUri?.let { uri ->
            flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                MethodChannel(messenger, METHOD_CHANNEL).invokeMethod("onAudioIntent", uri)
            }
        }
    }

    private fun handleIntent(intent: Intent?) {
        if (intent?.action == Intent.ACTION_VIEW) {
            val uri = intent.data
            if (uri != null) {
                initialAudioUri = uri.toString()
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialAudioIntent" -> {
                    val uri = initialAudioUri
                    initialAudioUri = null
                    result.success(uri)
                }
                "queryAudioFiles" -> {
                    val minDurationMs = (call.argument<Number>("minDurationMs") ?: 30000).toLong()
                    val modifiedSinceSec = (call.argument<Number>("modifiedSinceSec") ?: 0).toLong()
                    try {
                        val tracks = queryAudio(minDurationMs, modifiedSinceSec)
                        result.success(tracks)
                    } catch (e: Exception) {
                        result.error("QUERY_ERROR", e.message, null)
                    }
                }
                "getKnownMediaIds" -> {
                    try {
                        val ids = queryMediaIds()
                        result.success(ids)
                    } catch (e: Exception) {
                        result.error("QUERY_ERROR", e.message, null)
                    }
                }
                "updateWidget" -> {
                    val title = call.argument<String>("title") ?: ""
                    val artist = call.argument<String>("artist") ?: ""
                    val isPlaying = call.argument<Boolean>("isPlaying") ?: false
                    SonaraWidgetProvider.updateWidgetState(applicationContext, title, artist, isPlaying)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    registerMediaStoreObserver()
                }

                override fun onCancel(arguments: Any?) {
                    unregisterMediaStoreObserver()
                    eventSink = null
                }
            }
        )
    }

    private fun registerMediaStoreObserver() {
        if (contentObserver == null) {
            contentObserver = object : ContentObserver(Handler(Looper.getMainLooper())) {
                override fun onChange(selfChange: Boolean, uri: Uri?) {
                    super.onChange(selfChange, uri)
                    eventSink?.success(mapOf("uri" to (uri?.toString() ?: "")))
                }
            }
            contentResolver.registerContentObserver(
                MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                true,
                contentObserver!!
            )
        }
    }

    private fun unregisterMediaStoreObserver() {
        contentObserver?.let {
            contentResolver.unregisterContentObserver(it)
            contentObserver = null
        }
    }

    private fun queryAudio(minDurationMs: Long, modifiedSinceSec: Long): List<Map<String, Any?>> {
        val trackList = mutableListOf<Map<String, Any?>>()
        val uri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI

        val projection = mutableListOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.ALBUM,
            MediaStore.Audio.Media.DURATION,
            MediaStore.Audio.Media.DATA,
            MediaStore.Audio.Media.SIZE,
            MediaStore.Audio.Media.DATE_ADDED,
            MediaStore.Audio.Media.DATE_MODIFIED,
            MediaStore.Audio.Media.ALBUM_ID,
            MediaStore.Audio.Media.TRACK,
            MediaStore.Audio.Media.MIME_TYPE
        )

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            projection.add(MediaStore.Audio.Media.YEAR)
        }

        val selectionList = mutableListOf<String>()
        val selectionArgs = mutableListOf<String>()

        selectionList.add("${MediaStore.Audio.Media.IS_MUSIC} != 0")
        selectionList.add("${MediaStore.Audio.Media.DURATION} >= ?")
        selectionArgs.add(minDurationMs.toString())

        if (modifiedSinceSec > 0) {
            selectionList.add("${MediaStore.Audio.Media.DATE_MODIFIED} > ?")
            selectionArgs.add(modifiedSinceSec.toString())
        }

        val selection = selectionList.joinToString(" AND ")
        val sortOrder = "${MediaStore.Audio.Media.TITLE} ASC"

        contentResolver.query(
            uri,
            projection.toTypedArray(),
            selection,
            selectionArgs.toTypedArray(),
            sortOrder
        )?.use { cursor ->
            val idCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
            val titleCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)
            val artistCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST)
            val albumCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM)
            val durCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)
            val dataCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA)
            val sizeCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.SIZE)
            val addedCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DATE_ADDED)
            val modCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DATE_MODIFIED)
            val albumIdCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM_ID)
            val trackCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.TRACK)
            val mimeCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.MIME_TYPE)
            val yearCol = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                cursor.getColumnIndex(MediaStore.Audio.Media.YEAR)
            } else -1

            while (cursor.moveToNext()) {
                val id = cursor.getLong(idCol)
                val albumId = cursor.getLong(albumIdCol)
                val contentUri = ContentUris.withAppendedId(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, id).toString()
                val albumArtUri = "content://media/external/audio/albumart/$albumId"

                val item = mapOf(
                    "id" to id,
                    "contentUri" to contentUri,
                    "albumArtUri" to albumArtUri,
                    "title" to (cursor.getString(titleCol) ?: ""),
                    "artist" to (cursor.getString(artistCol) ?: ""),
                    "album" to (cursor.getString(albumCol) ?: ""),
                    "durationMs" to cursor.getLong(durCol),
                    "path" to (cursor.getString(dataCol) ?: ""),
                    "sizeBytes" to cursor.getLong(sizeCol),
                    "dateAdded" to cursor.getLong(addedCol),
                    "dateModified" to cursor.getLong(modCol),
                    "albumId" to albumId,
                    "trackNumber" to cursor.getInt(trackCol),
                    "mimeType" to (cursor.getString(mimeCol) ?: ""),
                    "year" to if (yearCol >= 0 && !cursor.isNull(yearCol)) cursor.getInt(yearCol) else 0
                )
                trackList.add(item)
            }
        }
        return trackList
    }

    private fun queryMediaIds(): List<Long> {
        val ids = mutableListOf<Long>()
        val uri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        val projection = arrayOf(MediaStore.Audio.Media._ID)
        val selection = "${MediaStore.Audio.Media.IS_MUSIC} != 0"

        contentResolver.query(uri, projection, selection, null, null)?.use { cursor ->
            val idCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
            while (cursor.moveToNext()) {
                ids.add(cursor.getLong(idCol))
            }
        }
        return ids
    }

    override fun onDestroy() {
        super.onDestroy()
        unregisterMediaStoreObserver()
    }
}
