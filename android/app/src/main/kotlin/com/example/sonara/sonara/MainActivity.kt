package com.example.sonara.sonara

import android.app.Activity
import android.content.Context
import android.content.ContentUris
import android.content.Intent
import android.database.ContentObserver
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
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
    private val SENSOR_EVENT_CHANNEL = "com.example.sonara/sensors"
    private val REQUEST_CODE_WRITE = 1001
    private val REQUEST_CODE_DELETE = 1002

    private var contentObserver: ContentObserver? = null
    private var eventSink: EventChannel.EventSink? = null
    private var initialAudioUri: String? = null
    private var pendingWriteResult: MethodChannel.Result? = null
    private var pendingDeleteResult: MethodChannel.Result? = null

    private var sensorManager: SensorManager? = null
    private var sensorSink: EventChannel.EventSink? = null
    private var sensorListener: SensorEventListener? = null
    private var lastShakeTime = 0L
    private var isFaceDown = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.setDecorFitsSystemWindows(false)
        }
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
                "requestWritePermission" -> {
                    val uriString = call.argument<String>("uri")
                    if (uriString == null) {
                        result.success(false)
                    } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        try {
                            val uri = Uri.parse(uriString)
                            val pendingIntent = MediaStore.createWriteRequest(contentResolver, listOf(uri))
                            pendingWriteResult = result
                            startIntentSenderForResult(
                                pendingIntent.intentSender,
                                REQUEST_CODE_WRITE,
                                null,
                                0,
                                0,
                                0
                            )
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    } else {
                        result.success(true)
                    }
                }
                "requestDeletePermission" -> {
                    val uriString = call.argument<String>("uri")
                    if (uriString == null) {
                        result.success(false)
                    } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        try {
                            val uri = Uri.parse(uriString)
                            val pendingIntent = MediaStore.createDeleteRequest(contentResolver, listOf(uri))
                            pendingDeleteResult = result
                            startIntentSenderForResult(
                                pendingIntent.intentSender,
                                REQUEST_CODE_DELETE,
                                null,
                                0,
                                0,
                                0
                            )
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    } else {
                        try {
                            val uri = Uri.parse(uriString)
                            val count = contentResolver.delete(uri, null, null)
                            result.success(count > 0)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
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

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, SENSOR_EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    sensorSink = events
                    startSensorListening()
                }

                override fun onCancel(arguments: Any?) {
                    stopSensorListening()
                    sensorSink = null
                }
            }
        )
    }

    private fun startSensorListening() {
        if (sensorManager == null) {
            sensorManager = getSystemService(Context.SENSOR_SERVICE) as? SensorManager
        }
        val manager = sensorManager ?: return

        if (sensorListener == null) {
            sensorListener = object : SensorEventListener {
                override fun onSensorChanged(event: SensorEvent?) {
                    if (event?.sensor?.type == Sensor.TYPE_ACCELEROMETER) {
                        val x = event.values[0]
                        val y = event.values[1]
                        val z = event.values[2]

                        // Shake detection: g-force threshold ~ 2.3
                        val gX = x / SensorManager.GRAVITY_EARTH
                        val gY = y / SensorManager.GRAVITY_EARTH
                        val gZ = z / SensorManager.GRAVITY_EARTH
                        val gForce = Math.sqrt((gX * gX + gY * gY + gZ * gZ).toDouble()).toFloat()

                        val now = System.currentTimeMillis()
                        if (gForce > 2.3f && (now - lastShakeTime > 1500)) {
                            lastShakeTime = now
                            sensorSink?.success(mapOf("event" to "shake"))
                        }

                        // Flip face-down detection: z < -8.2 and flat in x/y
                        if (z < -8.2f && Math.abs(x) < 4.5f && Math.abs(y) < 4.5f) {
                            if (!isFaceDown) {
                                isFaceDown = true
                                sensorSink?.success(mapOf("event" to "flip_face_down"))
                            }
                        } else if (z > -3.0f) {
                            if (isFaceDown) {
                                isFaceDown = false
                                sensorSink?.success(mapOf("event" to "flip_restored"))
                            }
                        }
                    }
                }

                override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
            }

            val accelerometer = manager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
            accelerometer?.let {
                manager.registerListener(sensorListener, it, SensorManager.SENSOR_DELAY_NORMAL)
            }
        }
    }

    private fun stopSensorListening() {
        sensorListener?.let {
            sensorManager?.unregisterListener(it)
            sensorListener = null
        }
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
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            projection.add(MediaStore.Audio.Media.GENRE)
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
            val idCol = cursor.getColumnIndex(MediaStore.Audio.Media._ID)
            val titleCol = cursor.getColumnIndex(MediaStore.Audio.Media.TITLE)
            val artistCol = cursor.getColumnIndex(MediaStore.Audio.Media.ARTIST)
            val albumCol = cursor.getColumnIndex(MediaStore.Audio.Media.ALBUM)
            val durCol = cursor.getColumnIndex(MediaStore.Audio.Media.DURATION)
            val dataCol = cursor.getColumnIndex(MediaStore.Audio.Media.DATA)
            val sizeCol = cursor.getColumnIndex(MediaStore.Audio.Media.SIZE)
            val addedCol = cursor.getColumnIndex(MediaStore.Audio.Media.DATE_ADDED)
            val modCol = cursor.getColumnIndex(MediaStore.Audio.Media.DATE_MODIFIED)
            val albumIdCol = cursor.getColumnIndex(MediaStore.Audio.Media.ALBUM_ID)
            val trackCol = cursor.getColumnIndex(MediaStore.Audio.Media.TRACK)
            val mimeCol = cursor.getColumnIndex(MediaStore.Audio.Media.MIME_TYPE)
            val yearCol = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                cursor.getColumnIndex(MediaStore.Audio.Media.YEAR)
            } else -1
            val genreCol = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                cursor.getColumnIndex(MediaStore.Audio.Media.GENRE)
            } else -1

            if (idCol == -1) return trackList

            while (cursor.moveToNext()) {
                val id = cursor.getLong(idCol)
                val albumId = if (albumIdCol >= 0 && !cursor.isNull(albumIdCol)) cursor.getLong(albumIdCol) else 0L
                val contentUri = ContentUris.withAppendedId(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, id).toString()
                val albumArtUri = if (albumId > 0) "content://media/external/audio/albumart/$albumId" else ""

                val item = mapOf(
                    "id" to id,
                    "contentUri" to contentUri,
                    "albumArtUri" to albumArtUri,
                    "title" to if (titleCol >= 0 && !cursor.isNull(titleCol)) (cursor.getString(titleCol) ?: "") else "",
                    "artist" to if (artistCol >= 0 && !cursor.isNull(artistCol)) (cursor.getString(artistCol) ?: "") else "",
                    "album" to if (albumCol >= 0 && !cursor.isNull(albumCol)) (cursor.getString(albumCol) ?: "") else "",
                    "durationMs" to if (durCol >= 0 && !cursor.isNull(durCol)) cursor.getLong(durCol) else 0L,
                    "path" to if (dataCol >= 0 && !cursor.isNull(dataCol)) (cursor.getString(dataCol) ?: "") else "",
                    "sizeBytes" to if (sizeCol >= 0 && !cursor.isNull(sizeCol)) cursor.getLong(sizeCol) else 0L,
                    "dateAdded" to if (addedCol >= 0 && !cursor.isNull(addedCol)) cursor.getLong(addedCol) else 0L,
                    "dateModified" to if (modCol >= 0 && !cursor.isNull(modCol)) cursor.getLong(modCol) else 0L,
                    "albumId" to albumId,
                    "trackNumber" to if (trackCol >= 0 && !cursor.isNull(trackCol)) cursor.getInt(trackCol) else 0,
                    "mimeType" to if (mimeCol >= 0 && !cursor.isNull(mimeCol)) (cursor.getString(mimeCol) ?: "") else "",
                    "year" to if (yearCol >= 0 && !cursor.isNull(yearCol)) cursor.getInt(yearCol) else 0,
                    "genre" to if (genreCol >= 0 && !cursor.isNull(genreCol)) (cursor.getString(genreCol) ?: "") else ""
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
            val idCol = cursor.getColumnIndex(MediaStore.Audio.Media._ID)
            if (idCol >= 0) {
                while (cursor.moveToNext()) {
                    ids.add(cursor.getLong(idCol))
                }
            }
        }
        return ids
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CODE_WRITE) {
            pendingWriteResult?.success(resultCode == Activity.RESULT_OK)
            pendingWriteResult = null
        } else if (requestCode == REQUEST_CODE_DELETE) {
            pendingDeleteResult?.success(resultCode == Activity.RESULT_OK)
            pendingDeleteResult = null
        }
    }

    override fun onPause() {
        super.onPause()
        sensorListener?.let {
            sensorManager?.unregisterListener(it)
        }
    }

    override fun onResume() {
        super.onResume()
        if (sensorSink != null && sensorListener != null) {
            val accelerometer = sensorManager?.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
            accelerometer?.let {
                sensorManager?.registerListener(sensorListener, it, SensorManager.SENSOR_DELAY_NORMAL)
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        stopSensorListening()
        unregisterMediaStoreObserver()
    }
}
