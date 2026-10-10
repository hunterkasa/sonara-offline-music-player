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
import android.content.ContentValues
import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMuxer
import android.media.RingtoneManager
import android.provider.Settings
import androidx.core.content.FileProvider
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    private val METHOD_CHANNEL = "com.example.sonara/mediastore"
    private val CUTTER_CHANNEL = "com.example.sonara/audio_cutter"
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

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CUTTER_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "trimAudio" -> {
                    val sourcePath = call.argument<String>("sourcePath")
                    val destinationPath = call.argument<String>("destinationPath")
                    val startMs = (call.argument<Number>("startMs") ?: 0).toLong()
                    val endMs = (call.argument<Number>("endMs") ?: 0).toLong()
                    if (sourcePath == null || destinationPath == null || startMs < 0 || endMs <= startMs) {
                        result.error("INVALID_ARGUMENTS", "Invalid source/destination path or time range", null)
                    } else {
                        try {
                            val success = trimAudioFile(sourcePath, destinationPath, startMs, endMs)
                            result.success(success)
                        } catch (e: Exception) {
                            result.error("TRIM_ERROR", e.message, null)
                        }
                    }
                }
                "setAsRingtone" -> {
                    val filePath = call.argument<String>("filePath")
                    val title = call.argument<String>("title") ?: "Ringtone"
                    val type = call.argument<String>("type") ?: "ringtone"
                    if (filePath == null) {
                        result.error("INVALID_ARGUMENTS", "File path cannot be null", null)
                    } else {
                        try {
                            val success = setAsRingtone(filePath, title, type)
                            result.success(success)
                        } catch (e: Exception) {
                            result.error("RINGTONE_ERROR", e.message, null)
                        }
                    }
                }
                "canWriteSystemSettings" -> {
                    result.success(Settings.System.canWrite(applicationContext))
                }
                "openWriteSettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS).apply {
                            data = Uri.parse("package:$packageName")
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SETTINGS_INTENT_ERROR", e.message, null)
                    }
                }
                "shareAudio" -> {
                    val filePath = call.argument<String>("filePath")
                    val title = call.argument<String>("title") ?: "Audio Clip"
                    if (filePath == null) {
                        result.error("INVALID_ARGUMENTS", "File path cannot be null", null)
                    } else {
                        try {
                            shareAudio(filePath, title)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("SHARE_ERROR", e.message, null)
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
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

    private fun trimAudioFile(sourcePath: String, destPath: String, startMs: Long, endMs: Long): Boolean {
        if (sourcePath.endsWith(".wav", ignoreCase = true) && destPath.endsWith(".wav", ignoreCase = true)) {
            try {
                if (trimWav(sourcePath, destPath, startMs, endMs)) {
                    return true
                }
            } catch (_: Exception) {}
        }

        val extractor = MediaExtractor()
        try {
            extractor.setDataSource(sourcePath)
            var audioTrackIndex = -1
            var format: MediaFormat? = null
            for (i in 0 until extractor.trackCount) {
                val f = extractor.getTrackFormat(i)
                val mime = f.getString(MediaFormat.KEY_MIME) ?: ""
                if (mime.startsWith("audio/")) {
                    audioTrackIndex = i
                    format = f
                    break
                }
            }
            if (audioTrackIndex < 0 || format == null) {
                extractor.release()
                return false
            }
            extractor.selectTrack(audioTrackIndex)
            val startUs = startMs * 1000L
            val endUs = endMs * 1000L
            extractor.seekTo(startUs, MediaExtractor.SEEK_TO_CLOSEST_SYNC)

            val destFile = File(destPath)
            destFile.parentFile?.mkdirs()
            if (destFile.exists()) destFile.delete()

            val outputFormat = if (destPath.endsWith(".ogg", ignoreCase = true) && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                MediaMuxer.OutputFormat.MUXER_OUTPUT_OGG
            } else {
                MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4
            }

            val muxer = MediaMuxer(destPath, outputFormat)
            val muxerTrack = muxer.addTrack(format)
            muxer.start()

            val maxInputSize = if (format.containsKey(MediaFormat.KEY_MAX_INPUT_SIZE)) {
                format.getInteger(MediaFormat.KEY_MAX_INPUT_SIZE)
            } else {
                256 * 1024
            }
            val buffer = ByteBuffer.allocate(maxInputSize)
            val bufferInfo = MediaCodec.BufferInfo()

            var sawEOS = false
            var actualStartUs = -1L

            while (!sawEOS) {
                val sampleSize = extractor.readSampleData(buffer, 0)
                if (sampleSize < 0) {
                    sawEOS = true
                } else {
                    val presentationTimeUs = extractor.sampleTime
                    if (presentationTimeUs > endUs) {
                        sawEOS = true
                    } else {
                        if (actualStartUs == -1L) {
                            actualStartUs = presentationTimeUs
                        }
                        bufferInfo.offset = 0
                        bufferInfo.size = sampleSize
                        bufferInfo.presentationTimeUs = Math.max(0L, presentationTimeUs - actualStartUs)
                        bufferInfo.flags = extractor.sampleFlags
                        muxer.writeSampleData(muxerTrack, buffer, bufferInfo)
                        extractor.advance()
                    }
                }
            }
            try { muxer.stop() } catch (_: Exception) {}
            muxer.release()
            extractor.release()
            return true
        } catch (e: Exception) {
            try { extractor.release() } catch (_: Exception) {}
            return false
        }
    }

    private fun trimWav(sourcePath: String, destPath: String, startMs: Long, endMs: Long): Boolean {
        val src = File(sourcePath)
        if (!src.exists()) return false
        val dest = File(destPath)
        dest.parentFile?.mkdirs()

        FileInputStream(src).use { fis ->
            val header = ByteArray(44)
            if (fis.read(header) < 44) return false

            val riff = String(header, 0, 4)
            val wave = String(header, 8, 4)
            if (riff != "RIFF" || wave != "WAVE") return false

            val byteRate = ByteBuffer.wrap(header, 28, 4).order(ByteOrder.LITTLE_ENDIAN).int
            val blockAlign = ((header[32].toInt() and 0xFF) or ((header[33].toInt() and 0xFF) shl 8))

            if (byteRate <= 0 || blockAlign <= 0) return false

            var startByte = (startMs * byteRate) / 1000L
            startByte -= (startByte % blockAlign)
            var endByte = (endMs * byteRate) / 1000L
            endByte -= (endByte % blockAlign)

            val totalDataBytes = src.length() - 44
            if (startByte > totalDataBytes) return false
            if (endByte > totalDataBytes) endByte = totalDataBytes
            if (endByte <= startByte) return false

            val slicedBytes = (endByte - startByte).toInt()
            val totalFileSize = slicedBytes + 36

            ByteBuffer.wrap(header, 4, 4).order(ByteOrder.LITTLE_ENDIAN).putInt(totalFileSize)
            ByteBuffer.wrap(header, 40, 4).order(ByteOrder.LITTLE_ENDIAN).putInt(slicedBytes)

            FileOutputStream(dest).use { fos ->
                fos.write(header)
                fis.channel.position(44 + startByte)
                val buffer = ByteArray(8192)
                var remaining = slicedBytes
                while (remaining > 0) {
                    val toRead = Math.min(buffer.size, remaining)
                    val read = fis.read(buffer, 0, toRead)
                    if (read <= 0) break
                    fos.write(buffer, 0, read)
                    remaining -= read
                }
            }
        }
        return true
    }

    private fun setAsRingtone(filePath: String, title: String, type: String): Boolean {
        if (!Settings.System.canWrite(applicationContext)) {
            return false
        }
        val file = File(filePath)
        if (!file.exists()) return false

        val mimeType = when {
            filePath.endsWith(".m4a", ignoreCase = true) -> "audio/mp4"
            filePath.endsWith(".mp3", ignoreCase = true) -> "audio/mpeg"
            filePath.endsWith(".wav", ignoreCase = true) -> "audio/x-wav"
            filePath.endsWith(".ogg", ignoreCase = true) -> "audio/ogg"
            else -> "audio/mp4"
        }

        val isRingtone = type == "ringtone"
        val isNotification = type == "notification"
        val isAlarm = type == "alarm"

        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DATA, file.absolutePath)
            put(MediaStore.MediaColumns.TITLE, title)
            put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
            put(MediaStore.Audio.Media.IS_RINGTONE, isRingtone)
            put(MediaStore.Audio.Media.IS_NOTIFICATION, isNotification)
            put(MediaStore.Audio.Media.IS_ALARM, isAlarm)
            put(MediaStore.Audio.Media.IS_MUSIC, false)
        }

        val uri = contentResolver.insert(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, values)
            ?: MediaStore.Audio.Media.getContentUriForPath(file.absolutePath)

        if (uri != null) {
            val ringtoneType = when (type) {
                "notification" -> RingtoneManager.TYPE_NOTIFICATION
                "alarm" -> RingtoneManager.TYPE_ALARM
                else -> RingtoneManager.TYPE_RINGTONE
            }
            RingtoneManager.setActualDefaultRingtoneUri(applicationContext, ringtoneType, uri)
            return true
        }
        return false
    }

    private fun shareAudio(filePath: String, title: String) {
        val file = File(filePath)
        if (!file.exists()) return
        val contentUri = FileProvider.getUriForFile(applicationContext, "${packageName}.fileprovider", file)
        val shareIntent = Intent(Intent.ACTION_SEND).apply {
            type = "audio/*"
            putExtra(Intent.EXTRA_STREAM, contentUri)
            putExtra(Intent.EXTRA_SUBJECT, title)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        val chooser = Intent.createChooser(shareIntent, "Share Audio Clip").apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(chooser)
    }
}
