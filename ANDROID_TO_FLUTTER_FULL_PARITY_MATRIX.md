# Android -> Flutter 全量对齐矩阵

更新时间：`2026-07-17`

唯一基线：`D:\桌面\本科\课题all\中国高校计算机大赛AIGC赛道\VisualSemanticAgent`

| 模块 | Android 基线 | Flutter 实现 | 当前结论 | 已验证证据 | 仍需外部设备验证 |
|---|---|---|---|---|---|
| 登录 / 注册 / 会话 | `ui/LoginScreen.kt`、`account/*` | `login_page.dart`、`account_repository.dart`、`account_session_service.dart` | 源码与真实本地流程已对齐；事项、消息、导出、成就和用户偏好均按账号隔离 | 模拟器真实账号登录、会话恢复和旧偏好迁移 | iOS 键盘和相册/相机头像流程 |
| 首页问候与总览 | `ui/home/HomeTopSection.kt` | `home_page.dart` | 组件层级、颜色、字体、尺寸、间距和底栏图标已按 Compose 常量对齐 | Android/Flutter 同分辨率截图回归，无溢出 | 不同实体设备字体栅格差异 |
| 输入中枢 | `ui/home/HomeInputHubSection.kt` | `home_page.dart` | 拍照、粘贴、语音、解析按钮及状态分支已对齐 | 模拟器交互和真实解析 | iOS 输入法、权限弹窗 |
| 实时相机 | `ui/camera/LiveCameraCaptureScreen.kt` | `live_camera_capture_page.dart` | 实时预览、闪光灯、镜头切换、快门、相册入口和错误状态已对齐 | 模拟器真实 Camera 预览非空 | Android/iPhone/iPad 实体摄像头、双镜头切换 |
| 分享导入 | `MainActivity.kt`、Manifest intent filters | `share_receive_service.dart`、Android Manifest、iOS Share Extension | Android 架构已对齐；iOS target 和 App Group 已配置到工程 | Android 编译和入口检查 | iPhone/iPad 分享文本、图片到 Runner |
| vivo OCR / VLM | `VLMNetworkClient.kt`、`ResponseInterpreter.kt` | `ocr_service.dart`、`parser_service.dart` | 使用真实接口；批量事件、action、clarification、target_found 和缺字段语义已迁移 | 真实 key 解析两次成功；解析测试通过 | iOS 图片来源权限 |
| vivo 实时 ASR | `VivoRealtimeAsrClient.kt` | `speech_service.dart`、`vivo_asr_protocol.dart` | 16 kHz PCM16、40 ms 帧、WebSocket 增量去重和 15 秒停止规则已迁移 | 模拟器真实返回语音文本，无系统 SpeechRecognizer 调用 | Android 真机中文语音质量；iPhone/iPad 麦克风 |
| 解析校验页 | `ui/review/ReviewScreenModule.kt` | `review_page.dart`、`review_logic.dart` | 原文回看、字段编辑、冲突、校验、保存、确认和取消层级已对齐 | 真实 clarification 补齐后提升为 create_event 并写入时间线 | iOS 键盘和系统日历跳转 |
| 时间线主视图 | `ui/timeline/TimelineScreenModule.kt` | `timeline_page.dart`、`timeline_logic.dart` | 本日/本周/本月、提醒 hero、日历入口、分组时间轴和空状态已对齐 | 模拟器打开、列表显示、无崩溃 | iOS 长列表和动态字体 |
| 日历总览 | `ui/timeline/TimelineCalendarModule.kt` | `timeline_page.dart` | 独立路由、固定日格、周起始、事件点和当日列表已对齐 | 源码核对和路由回归 | iPad 宽屏视觉验收 |
| 时间线详情 | `ui/timeline/TimelineDetailModule.kt` | `timeline_page.dart` | 查看/编辑、导航、复制、分享、副本、删除和关闭动作已保留 | 模拟器详情打开、持久化重启、真实删除 | 地图 App、系统分享面板实体机验收 |
| 本地提醒 | `reminder/*` | `reminder_service.dart` | 真实本地通知排程和权限检查已接入 | Android 初始化、排程代码和运行状态检查 | 实体 Android/iPhone/iPad 到点触发 |
| 系统日历 | Android Calendar Intent | `integration_service.dart` | 使用真实系统日历编辑 Intent，不做静默假写入 | 模拟器真实打开 Google Calendar；时间线先持久化 | 模拟器未登录 Google 账号，最终日历保存需实体机 |
| 地图导航 | Android geo/map Intent | `integration_service.dart` | Android geo URI 与 iOS Apple Maps 分平台实现 | 源码和路由检查 | 实体设备地图 App |
| PDF / PNG / JPG 导出 | `PlanComponents.kt` | `timeline_export_service.dart` | 三种格式均生成真实文件并记录导出审计 | Dart 测试、Android 构建和路由回归 | iOS 文件打开/分享 |
| 通知中心 | `ProfileInboxModels.kt` | `inbox_message.dart`、`profile_page.dart` | 总览筛选、20 条列表、清空和策略入口已按源码组织 | 17 个 ProfileRoute 全路由回归 | iPad 宽屏视觉验收 |
| 历史 / 统计 / 成就 | Profile summary/history models | `profile_page.dart`、`user_insight_service.dart`、`achievement_unlock_record.dart` | 保留 Android 统计层级；成就由真实数据计算，首次解锁后按账号永久保存，并回流通知中心 | 规则、账号隔离、重启恢复和空账号边界通过 | iPad 宽屏视觉验收 |
| 智能体中心 / 体检 | Profile checkup/tile models | `profile_page.dart` | 功能地图、系统入口、真实状态、评分和行动项已对齐 | 全路由回归 | iPad 宽屏视觉验收 |
| 用户画像 | `ProfileStatusModels.kt` | `profile_page.dart`、`user_insight_service.dart` | 保留原标签优先级，并加入当前账号个人资料完整度、校园身份、事项类型和时间分布证据 | 资料不足与组合画像规则测试通过 | 大数据量和多账号人工验收 |
| 设置 / 偏好 / 隐私 | `ProfileScreenModule.kt` | `profile_page.dart`、`storage_service.dart` | 风控、低置信度、提醒和地图设置按账号独立持久化，旧全局键只迁移给当前登录账号 | 账号 A/B 隔离、清理和模拟器迁移测试通过 | iOS 权限状态 |
| 个人资料 | `ProfileScreenModule.kt` | `profile_page.dart`、`account_repository.dart` | 头像来源、82 dp 预览、字段分组、长度限制和真实保存已对齐 | 模拟器页面回归 | 实体设备相机/相册头像 |
| 运行状态 / 数据空间 | Profile status/tile models | `profile_page.dart` | 真实权限、接口、存储和数据分层状态已对齐 | 全路由回归 | iOS 最终权限状态 |
| 主题 / 字体 / 背景 | `AppTheme.kt`、`WeavingDesign.kt`、`res/font/*` | `app.dart`、`weaving_widgets.dart`、`assets/fonts/*` | 原颜色、字体、20 dp 卡片、毛玻璃边框、弥散光和动效参数已迁移 | 首页、相机、时间线和全部 ProfileRoute 截图回归 | iOS 字体栅格与安全区 |
| 云端 iOS 编译 | `ios/*`、Codemagic、GitHub Actions | `codemagic.yaml`、`.github/workflows/flutter_ios_check.yml` | GitHub Actions no-codesign 已通过；签名流程只引用集成和环境变量 | pub get/analyze/test/pod install/build ios no-codesign 已通过 | TestFlight 签名、安装和真机功能验收 |

## 严格结论

- 本轮 Android 源码级迁移与模拟器主流程回归已完成，没有保留已知的主流程空壳按钮，也没有加入 mock/demo/假数据或本地规则兜底。
- 已真实跑通：vivo 文本解析、clarification 补齐、动作提升、本地时间线写入、重启持久化、详情删除、vivo ASR 返回、相机预览。
- Android 系统日历 Intent 已真实打开；由于模拟器没有 Google 账号，不能声称系统日历最终保存已完成。
- 不能声称 iPhone/iPad 真机验证、TestFlight 签名安装、iOS Share Extension、通知触发、日历写入、相机、录音和导出打开已经完成。
