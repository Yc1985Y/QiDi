package com.vsa.visualsemanticagent.ui.profile

import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.CameraAlt
import androidx.compose.material.icons.rounded.ManageAccounts
import androidx.compose.material.icons.rounded.NotificationsActive
import androidx.compose.material.icons.rounded.Psychology
import androidx.compose.material.icons.rounded.Search
import androidx.compose.material.icons.rounded.Speed
import androidx.compose.material.icons.rounded.Storage
import androidx.compose.material.icons.rounded.Tune

internal enum class CheckupLevel {
    Ready,
    Watch,
    Action
}

internal data class AgentCheckupItem(
    val icon: ImageVector,
    val title: String,
    val summary: String,
    val level: CheckupLevel,
    val route: ProfileRoute
)

internal data class RuntimeStatusRowSpec(
    val icon: ImageVector,
    val title: String,
    val summary: String,
    val ready: Boolean
)

data class AgentRuntimeStatusData(
    val modelName: String,
    val appIdReady: Boolean,
    val apiKeyReady: Boolean,
    val chatEndpoint: String,
    val ocrEndpoint: String,
    val dataStoreReady: Boolean,
    val accountReady: Boolean,
    val cameraReady: Boolean,
    val voiceReady: Boolean,
    val agendaCount: Int,
    val inboxCount: Int,
    val reminderCount: Int
)

internal fun runtimeReadyCount(runtimeStatus: AgentRuntimeStatusData): Int {
    return listOf(
        runtimeStatus.appIdReady,
        runtimeStatus.apiKeyReady,
        runtimeStatus.dataStoreReady,
        runtimeStatus.accountReady,
        runtimeStatus.cameraReady,
        runtimeStatus.voiceReady
    ).count { it }
}

internal fun runtimeStatusRows(
    runtimeStatus: AgentRuntimeStatusData,
    performanceLiteMode: Boolean
): List<RuntimeStatusRowSpec> {
    return listOf(
        RuntimeStatusRowSpec(Icons.Rounded.Psychology, "大模型引擎", runtimeStatus.modelName, runtimeStatus.appIdReady && runtimeStatus.apiKeyReady),
        RuntimeStatusRowSpec(Icons.Rounded.Search, "图文 OCR", endpointTail(runtimeStatus.ocrEndpoint), runtimeStatus.ocrEndpoint.isNotBlank()),
        RuntimeStatusRowSpec(Icons.Rounded.Storage, "本地 DataStore", "${runtimeStatus.agendaCount} 条资产 / ${runtimeStatus.inboxCount} 条消息", runtimeStatus.dataStoreReady),
        RuntimeStatusRowSpec(Icons.Rounded.NotificationsActive, "提醒调度", "${runtimeStatus.reminderCount} 条提醒策略", runtimeStatus.reminderCount >= 0),
        RuntimeStatusRowSpec(Icons.Rounded.ManageAccounts, "账号会话", if (runtimeStatus.accountReady) "已登录" else "未登录", runtimeStatus.accountReady),
        RuntimeStatusRowSpec(Icons.Rounded.CameraAlt, "相机入口", if (runtimeStatus.cameraReady) "可用" else "待授权", runtimeStatus.cameraReady),
        RuntimeStatusRowSpec(Icons.Rounded.Tune, "语音入口", if (runtimeStatus.voiceReady) "可用" else "待授权", runtimeStatus.voiceReady),
        RuntimeStatusRowSpec(Icons.Rounded.Speed, "动效负载", if (performanceLiteMode) "轻量模式" else "完整动效", true)
    )
}
