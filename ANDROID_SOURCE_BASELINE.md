# Android 源工程基线

更新时间：`2026-07-03`

## 1. 工程定位

- 源工程：`D:\桌面\本科\课题all\中国高校计算机大赛AIGC赛道\VisualSemanticAgent`
- 包名：`com.vsa.visualsemanticagent`
- 入口：`app/src/main/java/com/vsa/visualsemanticagent/MainActivity.kt`
- 构建脚本：`app/build.gradle`
- Manifest：`app/src/main/AndroidManifest.xml`

## 2. 技术栈

### 2.1 平台与构建

- 语言：`Kotlin`
- UI：`Jetpack Compose`
- 编译 SDK：`34`
- 最低 SDK：`29`
- 目标 SDK：`34`
- Java / Kotlin：`17`
- Compose 编译扩展：`1.5.3`

### 2.2 关键依赖

- Compose UI / Material3
- CameraX：
  - `camera-core`
  - `camera-camera2`
  - `camera-lifecycle`
  - `camera-view`
  - `camera-extensions`
- WorkManager：本地提醒
- DataStore Preferences：偏好存储
- OkHttp：网络请求
- Gson：JSON 解析
- Timber：日志
- Lottie Compose：动画资源

### 2.3 原生系统能力

- 相机实时预览与拍照
- 语音识别
- 文本转语音
- 系统分享接收：`SEND text/plain`、`SEND image/*`
- 系统日历插入
- 地图意图跳转
- 本地通知 / 提醒
- 文件导出 / FileProvider

## 3. Manifest 与权限基线

来自 [AndroidManifest.xml](D:\桌面\本科\课题all\中国高校计算机大赛AIGC赛道\VisualSemanticAgent\app\src\main\AndroidManifest.xml)：

- `CAMERA`
- `RECORD_AUDIO`
- `INTERNET`
- `ACCESS_NETWORK_STATE`
- `VIBRATE`
- `POST_NOTIFICATIONS`
- `READ_MEDIA_IMAGES`
- `READ_EXTERNAL_STORAGE`（`maxSdkVersion=32`）

查询与外部交互：

- 语音识别服务
- 地图 App
- Google / 系统日历
- `INSERT event`
- `SENDTO smsto`

## 4. 页面与模块基线

### 4.1 首页与输入

- `ui/home/HomeScreenModule.kt`
- `ui/home/HomeTopSection.kt`
- `ui/home/HomeInputHubSection.kt`
- `ui/home/HomeResultSection.kt`
- `ui/CameraScreen.kt`
- `ui/camera/LiveCameraCaptureScreen.kt`

真实入口包括：

- 拍照识别
- 相册导入
- 粘贴文本
- 语音输入
- 系统分享文本 / 图片
- 最近识别结果
- 待确认主卡

### 4.2 校验与结果确认

- `ui/review/ReviewScreenModule.kt`

真实能力：

- 原始输入回放
- 标题 / 时间 / 地点 / 备注编辑
- 冲突提示
- 保存校验
- 确认写入时间线
- 取消

### 4.3 时间线

- `ui/timeline/TimelineScreenModule.kt`
- `ui/timeline/TimelineCalendarModule.kt`
- `ui/timeline/TimelineDetailModule.kt`
- `ui/PlanComponents.kt`
- `plan/PlanModels.kt`

真实能力：

- 本日 / 本周 / 本月
- 日历总览
- 详情面板
- 删除 / 复制 / 分享 / 导航
- 导出格式语义：`PDF / PNG / JPG`

### 4.4 我的 / 资料 / 设置

- `ui/profile/ProfileScreenModule.kt`
- `ui/profile/ProfileNavigation.kt`
- `ui/profile/ProfileTileModels.kt`
- `ui/profile/ProfileSummaryModels.kt`
- `ui/profile/ProfileInboxModels.kt`
- `ui/profile/ProfileStatusModels.kt`
- `ui/profile/ProfileHistoryModels.kt`
- `ui/profile/ProfileCheckupModels.kt`

真实二级结构：

- Dashboard
- 智能体中心
- 智能体体检
- 历史记录
- 统计
- 成就
- 偏好设置
- 账号
- 设置
- 个人资料
- 用户画像
- 提醒中心
- 时间线资产
- 导出记录
- 运行状态
- 通知中心
- 隐私与安全
- 数据空间

### 4.5 登录 / 会话 / 账号

- `ui/LoginScreen.kt`
- `account/AccountRepository.kt`
- `account/AccountModels.kt`
- `account/AccountSessionStore.kt`

真实能力：

- 本地账号注册
- 本地账号登录
- 会话恢复
- 个人资料回写
- 内置测试账号

## 5. 数据与业务链路基线

### 5.1 解析链路

- `network/VLMNetworkClient.kt`
- `model/VLMModels.kt`
- `utils/ResponseInterpreter.kt`
- `utils/NoticeSegmentExtractor.kt`
- `input/CampusNoticeInput.kt`

链路：

`多源输入 -> OCR / 文本整理 -> VLM chat/completions -> 结构化 events[] -> 校验 -> 时间线`

说明：

- 源工程存在 `network/MockVLMResponseFactory.kt`
- 但 `app/build.gradle` 中 `VLM_USE_MOCK=false`
- 所以比赛目标基线仍应以真实接口链路为准，不能把 mock 当作完成态

### 5.2 风控与执行

- `decision/ExecutableIntent.kt`
- `decision/ActionValidator.kt`
- `decision/RiskPolicyEngine.kt`
- `decision/ScheduleConflict.kt`
- `decision/TemporalIntentStabilizer.kt`
- `decision/PendingExecutionRegistry.kt`

能力：

- 高风险动作拦截
- 低置信度控制
- 时间冲突判断
- 人在回路确认

### 5.3 提醒与通知

- `reminder/ReminderScheduler.kt`
- `reminder/ReminderWorker.kt`
- `notification/InboxMessageData.kt`

能力：

- 提前一天 / 提前一小时
- 本地通知调度
- Inbox 消息回流

### 5.4 语音与 TTS

- `voice/VoiceRecognitionManager.kt`
- `voice/VivoRealtimeAsrClient.kt`
- `tts/TextToSpeechManager.kt`

### 5.5 存储

- `storage/AppPreferencesStore.kt`
- `account/*`

基线存储：

- 偏好
- 账号 / 会话
- 提醒状态
- 历史沉淀数据

## 6. 视觉资源基线

### 6.1 字体

- `res/font/literata_*`
- `res/font/manrope_*`
- `res/font/plus_jakarta_sans_*`

### 6.2 主题

- `ui/AppTheme.kt`
- `res/values/themes.xml`

关键视觉常量：

- 主色：`#003528`
- 背景：`#FFF8F2`
- 珊瑚辅助：`#FFE0DC`
- 金色辅助：`#FFEDC0`
- 卡片圆角：`20 / 28 / 999 dp` 体系
- 玻璃态卡片、暖纸色背景、深绿文字

### 6.3 文案与图标

- `res/values/strings.xml`
- `res/drawable/ic_launcher_foreground.xml`
- `res/mipmap-anydpi-v26/*`

## 7. 当前迁移时必须坚持的基线结论

1. 原 Android 工程是唯一标准。
2. 真实主链路必须保留：
   - 输入
   - 解析
   - 校验
   - 确认
   - 时间线
   - 提醒
   - 日历
   - 导出
3. Android 已有的深层页面不是可选项，而是 Flutter 需要逐项补齐的目标。
4. Android 中存在的 mock 代码不能被当作 Flutter 的兜底理由；比赛版本仍以真实接口和真实系统能力为准。
