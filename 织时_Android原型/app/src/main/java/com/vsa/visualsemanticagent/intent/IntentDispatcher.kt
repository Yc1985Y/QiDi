package com.vsa.visualsemanticagent.intent

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.CalendarContract
import android.provider.CalendarContract.Events
import com.vsa.visualsemanticagent.decision.ExecutableIntent
import com.vsa.visualsemanticagent.model.ModelConstants
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.OffsetDateTime
import java.time.ZoneId
import java.time.format.DateTimeParseException
import java.net.URLEncoder
import timber.log.Timber

class IntentDispatcher(private val context: Context) {

    data class DispatchResult(
        val launchedIntent: Boolean,
        val summary: String
    )

    fun dispatchIntent(
        intent: ExecutableIntent,
        preferredMapProvider: String? = null
    ): DispatchResult {
        return try {
            when (intent.action) {
                ModelConstants.ACTION_CREATE_EVENT -> createCalendarEvent(intent)
                ModelConstants.ACTION_NAVIGATE -> navigateToLocation(intent, preferredMapProvider)
                ModelConstants.ACTION_TTS_FEEDBACK -> {
                    DispatchResult(
                        launchedIntent = false,
                        summary = intent.answer ?: intent.description ?: "已生成语音反馈"
                    )
                }

                ModelConstants.ACTION_SEND_SMS -> {
                    DispatchResult(
                        launchedIntent = false,
                        summary = "当前版本聚焦校园通知转日程，短信不作为主流程。"
                    )
                }
                else -> {
                    DispatchResult(
                        launchedIntent = false,
                        summary = intent.answer ?: intent.description ?: "当前动作暂不支持直接执行"
                    )
                }
            }
        } catch (e: Exception) {
            Timber.e(e, "Failed to dispatch intent")
            throw e
        }
    }

    private fun createCalendarEvent(intentData: ExecutableIntent): DispatchResult {
        val intent = Intent(Intent.ACTION_INSERT).apply {
            data = Events.CONTENT_URI
            intentData.time?.let { parseEventTimeMillis(it) }?.let { timeMillis ->
                putExtra(CalendarContract.EXTRA_EVENT_BEGIN_TIME, timeMillis)
            }
            intentData.title?.let { putExtra(Events.TITLE, it) }
            intentData.location?.let { putExtra(Events.EVENT_LOCATION, it) }
            intentData.description?.let { putExtra(Events.DESCRIPTION, it) }
        }

        if (intent.resolveActivity(context.packageManager) != null) {
            context.startActivity(intent)
            val title = intentData.title ?: "新提醒"
            return DispatchResult(
                launchedIntent = true,
                summary = "已打开日历确认页面：$title"
            )
        } else {
            throw ActivityNotFoundException("Calendar app not found")
        }
    }

    private fun navigateToLocation(
        intentData: ExecutableIntent,
        preferredMapProvider: String?
    ): DispatchResult {
        val location = intentData.location ?: throw IllegalArgumentException("Missing location")
        val finalIntent = buildDomesticMapIntents(location, preferredMapProvider)
            .firstOrNull { it.resolveActivity(context.packageManager) != null }

        if (finalIntent != null) {
            context.startActivity(finalIntent)
            return DispatchResult(
                launchedIntent = true,
                summary = "已打开地图，准备导航到：$location"
            )
        } else {
            throw ActivityNotFoundException("Map app not found")
        }
    }

    private fun buildDomesticMapIntents(
        location: String,
        preferredMapProvider: String?
    ): List<Intent> {
        val encodedLocation = URLEncoder.encode(location, Charsets.UTF_8.name())
        val amap = Intent(Intent.ACTION_VIEW).apply {
                data = Uri.parse("androidamap://route/plan/?sourceApplication=织时&dname=$encodedLocation&dev=0&t=0")
                setPackage("com.autonavi.minimap")
            }
        val baidu = Intent(Intent.ACTION_VIEW).apply {
                data = Uri.parse("baidumap://map/direction?destination=$encodedLocation&mode=driving&src=织时")
                setPackage("com.baidu.BaiduMap")
            }
        val tencent = Intent(Intent.ACTION_VIEW).apply {
                data = Uri.parse("qqmap://map/routeplan?type=drive&to=$encodedLocation&referer=织时")
                setPackage("com.tencent.map")
            }
        val fallbacks = listOf(
            Intent(Intent.ACTION_VIEW).apply {
                data = Uri.parse("geo:0,0?q=$encodedLocation")
            },
            Intent(Intent.ACTION_VIEW).apply {
                data = Uri.parse("https://uri.amap.com/search?keyword=$encodedLocation")
            },
            Intent(Intent.ACTION_VIEW).apply {
                data = Uri.parse("https://apis.map.qq.com/uri/v1/search?keyword=$encodedLocation")
            }
        )
        val domestic = when (preferredMapProvider) {
            "amap" -> listOf(amap, baidu, tencent)
            "baidu" -> listOf(baidu, amap, tencent)
            "tencent" -> listOf(tencent, amap, baidu)
            else -> listOf(amap, baidu, tencent)
        }
        return domestic + fallbacks
    }

    private fun parseEventTimeMillis(timeStr: String): Long? {
        val trimmed = timeStr.trim()
        if (trimmed.isEmpty()) return null

        trimmed.toLongOrNull()?.let { value ->
            return if (value < 1_000_000_000_000L) value * 1000 else value
        }

        parseIsoDateTime(trimmed)?.let { return it }

        return try {
            LocalDate.parse(trimmed)
                .atTime(9, 0)
                .atZone(ZoneId.systemDefault())
                .toInstant()
                .toEpochMilli()
        } catch (_: DateTimeParseException) {
            Timber.w("Invalid time format: %s", timeStr)
            null
        }
    }

    private fun parseIsoDateTime(value: String): Long? {
        return try {
            OffsetDateTime.parse(value)
                .toInstant()
                .toEpochMilli()
        } catch (_: DateTimeParseException) {
            try {
                LocalDateTime.parse(value)
                    .atZone(ZoneId.systemDefault())
                    .toInstant()
                    .toEpochMilli()
            } catch (_: DateTimeParseException) {
                null
            }
        }
    }
}

class ActivityNotFoundException(message: String) : Exception(message)
