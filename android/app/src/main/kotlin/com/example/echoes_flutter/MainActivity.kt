package com.example.echoes_flutter

import android.Manifest
import android.content.pm.PackageManager
import android.media.MediaRecorder
import android.os.Build
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val channelName = "com.example.echoes_flutter/audio_recorder"
    private var mediaRecorder: MediaRecorder? = null
    private var currentRecordingPath: String? = null
    private var isRecording = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasPermission" -> {
                    val granted = ContextCompat.checkSelfPermission(
                        this,
                        Manifest.permission.RECORD_AUDIO
                    ) == PackageManager.PERMISSION_GRANTED
                    result.success(granted)
                }
                "startRecording" -> {
                    val path = call.argument<String>("path")
                    try {
                        val finalPath = startRecording(path)
                        result.success(finalPath)
                    } catch (e: Exception) {
                        result.error("RECORDING_ERROR", e.localizedMessage, null)
                    }
                }
                "stopRecording" -> {
                    try {
                        val path = stopRecording()
                        result.success(path)
                    } catch (e: Exception) {
                        result.error("STOP_ERROR", e.localizedMessage, null)
                    }
                }
                "getAmplitude" -> {
                    val amp = mediaRecorder?.maxAmplitude ?: 0
                    result.success(amp.toDouble())
                }
                "isRecording" -> {
                    result.success(isRecording)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startRecording(customPath: String?): String {
        val outputFile: File = if (!customPath.isNullOrEmpty()) {
            File(customPath).apply { parentFile?.mkdirs() }
        } else {
            File(cacheDir, "recording_${System.currentTimeMillis()}.m4a")
        }
        currentRecordingPath = outputFile.absolutePath

        val recorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            MediaRecorder(this)
        } else {
            @Suppress("DEPRECATION")
            MediaRecorder()
        }

        recorder.apply {
            setAudioSource(MediaRecorder.AudioSource.MIC)
            setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
            setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
            setAudioEncodingBitRate(128000)
            setAudioSamplingRate(44100)
            setOutputFile(outputFile.absolutePath)
            prepare()
            start()
        }

        mediaRecorder = recorder
        isRecording = true
        return outputFile.absolutePath
    }

    private fun stopRecording(): String? {
        if (!isRecording) return currentRecordingPath
        try {
            mediaRecorder?.apply {
                stop()
                reset()
                release()
            }
        } catch (e: Exception) {
            e.printStackTrace()
        } finally {
            mediaRecorder = null
            isRecording = false
        }
        return currentRecordingPath
    }

    override fun onDestroy() {
        stopRecording()
        super.onDestroy()
    }
}
