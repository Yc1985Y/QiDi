package com.vsa.visualsemanticagent.voice

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Build
import androidx.core.content.ContextCompat
import com.google.gson.Gson
import com.google.gson.JsonObject
import java.io.IOException
import java.net.URLEncoder
import java.nio.charset.StandardCharsets
import java.util.UUID
import java.util.concurrent.TimeUnit
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeout
import kotlinx.coroutines.withTimeoutOrNull
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Response
import okhttp3.WebSocket
import okhttp3.WebSocketListener
import okio.ByteString
import timber.log.Timber

class VivoRealtimeAsrClient(
    private val context: Context,
    private val apiKey: String,
    private val endpoint: String,
    private val engineId: String
) {

    private val gson = Gson()
    private val httpClient = OkHttpClient.Builder()
        .connectTimeout(8, TimeUnit.SECONDS)
        .readTimeout(70, TimeUnit.SECONDS)
        .writeTimeout(20, TimeUnit.SECONDS)
        .build()

    suspend fun listenOnce(
        maxRecordMillis: Long = 8_000L,
        languageTag: String = "zh-CN",
        stopSignal: CompletableDeferred<Unit>? = null
    ): String = withContext(Dispatchers.IO) {
        if (apiKey.isBlank()) {
            throw VivoAsrException("Vivo ASR AppKey is empty")
        }
        if (ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            throw VivoAsrException("Microphone permission is missing")
        }

        val requestId = UUID.randomUUID().toString().replace("-", "")
        val opened = CompletableDeferred<Unit>()
        val events = Channel<AsrEvent>(capacity = Channel.UNLIMITED)
        val webSocket = httpClient.newWebSocket(
            buildRequest(requestId),
            AsrWebSocketListener(opened, events)
        )

        val recorder = createRecorder()
        val segments = linkedMapOf<Int, String>()
        var finalText = ""
        var resultError: Throwable? = null

        try {
            withTimeout(maxRecordMillis + 15_000L) {
                opened.await()
                sendStartFrame(webSocket, requestId, languageTag)
                val recorderFinished = CompletableDeferred<Unit>()
                val recorderJob = launch {
                    try {
                        startRecordingAndSend(webSocket, recorder, maxRecordMillis, stopSignal)
                    } catch (e: Throwable) {
                        if (e is CancellationException) throw e
                        resultError = e
                        events.trySend(AsrEvent.Failed(e))
                    } finally {
                        recorderFinished.complete(Unit)
                    }
                }

                while (currentCoroutineContext().isActive) {
                    val event = withTimeoutOrNull(
                        if (recorderFinished.isCompleted) RESULT_IDLE_TIMEOUT_AFTER_RECORDING_MILLIS
                        else RESULT_IDLE_TIMEOUT_WHILE_RECORDING_MILLIS
                    ) {
                        events.receiveCatching().getOrNull()
                    } ?: if (recorderFinished.isCompleted) {
                        break
                    } else {
                        continue
                    }
                    when (event) {
                        is AsrEvent.Result -> {
                            if (event.text.isNotBlank()) {
                                if (event.resultId != null) {
                                    segments[event.resultId] = event.text
                                } else {
                                    finalText = event.text
                                }
                            }
                            if (event.isFinish) {
                                break
                            }
                        }
                        is AsrEvent.Failed -> throw event.throwable
                    }
                }
                recorderJob.cancelAndJoin()
            }
        } catch (e: Throwable) {
            if (e is CancellationException) throw e
            resultError = e
        } finally {
            runCatching { recorder.stop() }
            recorder.release()
            webSocket.send(ByteString.of(*"--close--".toByteArray(StandardCharsets.UTF_8)))
            webSocket.close(1000, "done")
            events.close()
        }

        val text = if (segments.isNotEmpty()) {
            segments.toSortedMap().values.joinToString("").trim()
        } else {
            finalText.trim()
        }
        if (text.isBlank()) {
            throw VivoAsrException(
                resultError?.message ?: "No speech text returned from Vivo ASR",
                resultError
            )
        }
        text
    }

    private fun buildRequest(requestId: String): Request {
        val url = buildString {
            append(endpoint)
            append("?")
            appendParam("client_version", "1.0.0")
            append("&")
            appendParam("model", Build.MODEL ?: "unknown")
            append("&")
            appendParam("system_version", Build.VERSION.RELEASE ?: "unknown")
            append("&")
            appendParam("package", context.packageName)
            append("&")
            appendParam("sdk_version", "unknown")
            append("&")
            appendParam("user_id", requestId.take(32).padEnd(32, '0'))
            append("&")
            appendParam("android_version", Build.VERSION.RELEASE ?: "unknown")
            append("&")
            appendParam("system_time", System.currentTimeMillis().toString())
            append("&")
            appendParam("net_type", "1")
            append("&")
            appendParam("engineid", engineId)
            append("&")
            appendParam("requestId", requestId)
        }
        return Request.Builder()
            .url(url)
            .header("Authorization", "Bearer $apiKey")
            .build()
    }

    private fun StringBuilder.appendParam(key: String, value: String) {
        append(key)
        append("=")
        append(URLEncoder.encode(value, "UTF-8"))
    }

    private fun sendStartFrame(webSocket: WebSocket, requestId: String, languageTag: String) {
        val payload = mapOf(
            "type" to "started",
            "request_id" to requestId,
            "asr_info" to mapOf(
                "end_vad_time" to 1200,
                "audio_type" to "pcm",
                "chinese2digital" to 1,
                "punctuation" to 1,
                "lang" to if (languageTag.startsWith("en", ignoreCase = true)) "en" else "cn"
            ),
            "business_info" to "TimeWeaver voice input"
        )
        webSocket.send(gson.toJson(payload))
    }

    private suspend fun startRecordingAndSend(
        webSocket: WebSocket,
        recorder: AudioRecord,
        maxRecordMillis: Long,
        stopSignal: CompletableDeferred<Unit>?
    ) {
        val frameBytes = BYTES_PER_40MS_FRAME
        val buffer = ByteArray(frameBytes)
        recorder.startRecording()
        val startAt = System.currentTimeMillis()
        while (System.currentTimeMillis() - startAt < maxRecordMillis && currentCoroutineContext().isActive) {
            if (stopSignal?.isCompleted == true) break
            val read = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                recorder.read(buffer, 0, buffer.size, AudioRecord.READ_BLOCKING)
            } else {
                recorder.read(buffer, 0, buffer.size)
            }
            if (read > 0) {
                val bytes = if (read == buffer.size) buffer else buffer.copyOf(read)
                webSocket.send(ByteString.of(*bytes))
            } else {
                delay(20L)
            }
        }
        webSocket.send(ByteString.of(*"--end--".toByteArray(StandardCharsets.UTF_8)))
    }

    private fun createRecorder(): AudioRecord {
        val minBufferSize = AudioRecord.getMinBufferSize(
            SAMPLE_RATE,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT
        )
        if (minBufferSize <= 0) {
            throw VivoAsrException("AudioRecord min buffer size is invalid")
        }
        val bufferSize = maxOf(minBufferSize, BYTES_PER_40MS_FRAME * 4)
        val audioSources = listOf(
            MediaRecorder.AudioSource.VOICE_RECOGNITION,
            MediaRecorder.AudioSource.MIC,
            MediaRecorder.AudioSource.DEFAULT
        )
        var lastError: Throwable? = null
        for (audioSource in audioSources) {
            runCatching {
                AudioRecord(
                    audioSource,
                    SAMPLE_RATE,
                    AudioFormat.CHANNEL_IN_MONO,
                    AudioFormat.ENCODING_PCM_16BIT,
                    bufferSize
                )
            }.onSuccess { recorder ->
                if (recorder.state == AudioRecord.STATE_INITIALIZED) {
                    Timber.d("Vivo ASR recorder initialized with source=%s", audioSource)
                    return recorder
                }
                recorder.release()
                lastError = IllegalStateException("AudioRecord state=${recorder.state} source=$audioSource")
            }.onFailure { throwable ->
                lastError = throwable
            }
        }
        throw VivoAsrException("AudioRecord initialization failed", lastError)
    }

    private inner class AsrWebSocketListener(
        private val opened: CompletableDeferred<Unit>,
        private val events: Channel<AsrEvent>
    ) : WebSocketListener() {
        override fun onOpen(webSocket: WebSocket, response: Response) {
            Timber.d("Vivo ASR websocket opened")
            opened.complete(Unit)
        }

        override fun onMessage(webSocket: WebSocket, text: String) {
            runCatching { parseMessage(text) }
                .onSuccess { events.trySend(it) }
                .onFailure { events.trySend(AsrEvent.Failed(it)) }
        }

        override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
            if (!opened.isCompleted) {
                opened.completeExceptionally(t)
            }
            events.trySend(AsrEvent.Failed(t))
        }

        override fun onClosed(webSocket: WebSocket, code: Int, reason: String) {
            Timber.d("Vivo ASR websocket closed: %s %s", code, reason)
        }
    }

    private fun parseMessage(text: String): AsrEvent {
        val json = gson.fromJson(text, JsonObject::class.java)
        val action = json.get("action")?.asString.orEmpty()
        val code = json.get("code")?.asInt ?: 0
        if (action == "error" || code !in setOf(0, 8, 9)) {
            val desc = json.get("desc")?.asString.orEmpty()
            return AsrEvent.Failed(VivoAsrException("Vivo ASR error $code: $desc"))
        }
        if (action == "started") {
            return AsrEvent.Result(null, "", isLast = false, isFinish = false)
        }

        val data = json.getAsJsonObject("data")
        val resultText = data?.get("text")?.asString
            ?: data?.get("onebest")?.asString
            ?: data?.get("var")?.asString
            ?: ""
        val resultId = data?.get("result_id")?.asInt
            ?: data?.get("bg")?.asInt
        val isLast = data?.get("is_last")?.asBoolean == true || code == 9
        val isFinish = json.get("is_finish")?.asBoolean == true || code == 9
        return AsrEvent.Result(resultId, resultText, isLast, isFinish)
    }

    private sealed interface AsrEvent {
        data class Result(
            val resultId: Int?,
            val text: String,
            val isLast: Boolean,
            val isFinish: Boolean
        ) : AsrEvent
        data class Failed(val throwable: Throwable) : AsrEvent
    }

    companion object {
        private const val SAMPLE_RATE = 16_000
        private const val BYTES_PER_SAMPLE = 2
        private const val BYTES_PER_40MS_FRAME = SAMPLE_RATE * BYTES_PER_SAMPLE * 40 / 1000
        private const val RESULT_IDLE_TIMEOUT_WHILE_RECORDING_MILLIS = 5_000L
        private const val RESULT_IDLE_TIMEOUT_AFTER_RECORDING_MILLIS = 1_500L
    }
}

class VivoAsrException(
    message: String,
    cause: Throwable? = null
) : IOException(message, cause)
