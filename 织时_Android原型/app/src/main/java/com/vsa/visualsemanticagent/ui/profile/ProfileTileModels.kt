package com.vsa.visualsemanticagent.ui.profile

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import com.vsa.visualsemanticagent.ui.AppColors
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.CheckCircle
import androidx.compose.material.icons.rounded.Download
import androidx.compose.material.icons.rounded.EmojiEvents
import androidx.compose.material.icons.rounded.History
import androidx.compose.material.icons.rounded.NotificationsActive
import androidx.compose.material.icons.rounded.Psychology
import androidx.compose.material.icons.rounded.QueryStats
import androidx.compose.material.icons.rounded.Security
import androidx.compose.material.icons.rounded.Settings
import androidx.compose.material.icons.rounded.Shield
import androidx.compose.material.icons.rounded.Speed
import androidx.compose.material.icons.rounded.Storage
import androidx.compose.material.icons.rounded.Timeline
import androidx.compose.material.icons.rounded.Tune
import androidx.compose.material.icons.rounded.ManageAccounts
import androidx.compose.material.icons.rounded.Map
import androidx.compose.material.icons.rounded.Delete
import androidx.compose.material.icons.rounded.Replay
import androidx.compose.material.icons.rounded.HomeWork
import androidx.compose.material.icons.rounded.Badge
import androidx.compose.material.icons.rounded.CalendarMonth
import androidx.compose.material.icons.rounded.CameraAlt
import androidx.compose.material.icons.rounded.Person
import androidx.compose.material.icons.rounded.LocationOn
import androidx.compose.material.icons.rounded.Logout
import androidx.compose.material.icons.rounded.DriveFileRenameOutline
import androidx.compose.material.icons.rounded.PhotoLibrary

internal data class DetailTileSpec(
    val icon: ImageVector,
    val title: String,
    val summary: String,
    val background: Color = AppColors.SurfaceContainerLowest,
    val testTag: String? = null,
    val onClick: (() -> Unit)? = null
)

internal data class ProfileFieldSpec(
    val icon: ImageVector,
    val label: String,
    val value: String,
    val placeholder: String,
    val singleLine: Boolean = true,
    val maxLines: Int = 1,
    val onValueChange: (String) -> Unit
)

internal fun profileFeatureMapTiles(onNavigate: (ProfileRoute) -> Unit): List<DetailTileSpec> {
    return listOf(
        DetailTileSpec(Icons.Rounded.CheckCircle, "一键体检", "校验待办、提醒、冲突和策略", AppColors.GoldSoft) {
            onNavigate(ProfileRoute.AgentCheckup)
        },
        DetailTileSpec(Icons.Rounded.Timeline, "日程表", "查看沉淀规模与今日资产", AppColors.MintAccent) {
            onNavigate(ProfileRoute.TimelineAssets)
        },
        DetailTileSpec(Icons.Rounded.NotificationsActive, "通知中心", "回看待处理与系统消息", AppColors.CoralSoft) {
            onNavigate(ProfileRoute.NotificationInbox)
        },
        DetailTileSpec(Icons.Rounded.EmojiEvents, "我的成就", "徽章、里程碑与使用激励", AppColors.GoldSoft) {
            onNavigate(ProfileRoute.Achievements)
        },
        DetailTileSpec(Icons.Rounded.Psychology, "用户画像", "校园时间管理侧写", AppColors.SurfaceContainer) {
            onNavigate(ProfileRoute.Persona)
        },
        DetailTileSpec(Icons.Rounded.Security, "隐私与安全", "人在回路与风险拦截", AppColors.CoralSoft) {
            onNavigate(ProfileRoute.PrivacySecurity)
        },
        DetailTileSpec(Icons.Rounded.Storage, "数据空间", "本地存储与缓存边界", AppColors.MintAccent) {
            onNavigate(ProfileRoute.DataSpace)
        },
        DetailTileSpec(
            Icons.Rounded.Speed,
            "运行状态",
            "模型、OCR、存储与动效负载",
            AppColors.SurfaceContainer,
            testTag = "profile-agent-runtime-status"
        ) {
            onNavigate(ProfileRoute.RuntimeStatus)
        }
    )
}

internal fun profileSystemEntryTiles(
    runtimeModelName: String,
    performanceLiteMode: Boolean,
    onNavigate: (ProfileRoute) -> Unit,
    onLogout: () -> Unit
): List<DetailTileSpec> {
    return listOf(
        DetailTileSpec(Icons.Rounded.Download, "导出记录", "为答辩或复盘导出时间资产") {
            onNavigate(ProfileRoute.ExportRecords)
        },
        DetailTileSpec(Icons.Rounded.Settings, "设置", "管理账号、测试信息与退出登录") {
            onNavigate(ProfileRoute.Settings)
        },
        DetailTileSpec(
            Icons.Rounded.Speed,
            "运行状态",
            "$runtimeModelName / ${if (performanceLiteMode) "轻量" else "完整"}动效"
        ) {
            onNavigate(ProfileRoute.RuntimeStatus)
        },
        DetailTileSpec(Icons.Rounded.Logout, "退出登录", "返回登录页并保留本地时间线数据", onClick = onLogout)
    )
}
