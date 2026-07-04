# Android -> Flutter 全量对齐矩阵

更新时间：`2026-07-03`

| 原安卓模块 | 原安卓文件 | 原安卓功能 / 设计 | Flutter 对应文件 | Flutter 当前状态 | 差距 | 是否必须补齐 | 补齐方案 |
|---|---|---|---|---|---|---|---|
| 登录 / 注册 / 会话 | `ui/LoginScreen.kt` `account/*` | 本地账号、会话恢复、资料回写 | `lib/pages/login_page.dart` `lib/repositories/account_repository.dart` `lib/services/account_session_service.dart` | 已完全对齐 | 仍需 iOS 真机验证键盘/输入体验 | 是 | 保持现有 SQLite + 会话实现 |
| 首页问候与总览 | `ui/home/HomeTopSection.kt` | Today-First 问候、总览卡 | `lib/pages/home_page.dart` | 功能已对齐但 UI 未完全对齐 | 卡片密度、排版细节仍有差异 | 是 | 继续按 Android 视觉资源细调 |
| 输入中枢 | `ui/home/HomeInputHubSection.kt` | 拍照、相册、粘贴、语音、分享导入 | `lib/pages/input_page.dart` `lib/pages/live_camera_capture_page.dart` | 功能已对齐但 UI 未完全对齐 | 仍有细节文案与按钮布局差异 | 是 | 继续按 Android 文案和层级收敛 |
| 实时相机取景 | `ui/camera/LiveCameraCaptureScreen.kt` | 实时预览、闪光灯、切镜头、快门、相册入口 | `lib/pages/live_camera_capture_page.dart` | 部分对齐 | iOS 真实拍照链路未真机验证 | 是 | 保留当前插件方案，后续上 TestFlight 做真机验收 |
| 最近识别 / 待确认主卡 | `ui/home/HomeResultSection.kt` | 最近识别摘要、主待确认卡 | `lib/pages/home_page.dart` | 功能已对齐但 UI 未完全对齐 | 卡片排版还不是 1:1 | 是 | 继续对照 Android 组件细调 |
| 解析校验页 | `ui/review/ReviewScreenModule.kt` | 原始输入回看、字段编辑、冲突提示、确认/取消 | `lib/pages/review_page.dart` | 部分对齐 | UI 细节与原卡片层次仍有差异 | 是 | 继续贴近 Android 文案和字段布局 |
| 时间线主视图 | `ui/timeline/TimelineScreenModule.kt` | 本日 / 本周 / 本月、多组列表 | `lib/pages/timeline_page.dart` `lib/pages/timeline_logic.dart` | 功能已对齐但 UI 未完全对齐 | 顶部控制区和时间轴细节仍有差异 | 是 | 继续细调结构与视觉 |
| 日历总览 | `ui/timeline/TimelineCalendarModule.kt` | 月视图、点选日期、当日事项 | `lib/pages/timeline_page.dart` | 部分对齐 | 仍是内嵌视图，不是完全同构模块 | 是 | 后续按 Android 结构继续拆分 |
| 时间线详情 | `ui/timeline/TimelineDetailModule.kt` | 编辑、分享、复制、导航、删除、副本 | `lib/pages/timeline_page.dart` | 功能已对齐但 UI 未完全对齐 | 面板样式与信息密度仍有差异 | 是 | 继续按 Android 详情页布局收敛 |
| 导出能力 | `ui/PlanComponents.kt` | PDF / PNG / JPG 导出 | `lib/services/timeline_export_service.dart` `lib/pages/timeline_page.dart` | 已完全对齐 | iOS 文件打开链路需真机验证 | 是 | 保持当前真实导出实现 |
| 通知中心 | `ui/profile/ProfileInboxModels.kt` | Inbox 回流、筛选、清空 | `lib/models/inbox_message.dart` `lib/pages/profile_page.dart` | 部分对齐 | UI 和分类表达仍未 1:1 | 是 | 继续对 Android inbox 文案和状态标签 |
| 历史记录 | `ui/profile/ProfileHistoryModels.kt` | 搜索、日期筛选、来源筛选、重校验 | `lib/pages/profile_page.dart` | 部分对齐 | 展示密度与字段仍需细调 | 是 | 继续按 Android 历史模型比对 |
| 智能体体检 | `ui/profile/ProfileCheckupModels.kt` | 评分、行动项、结论文案 | `lib/pages/profile_page.dart` | 功能已对齐但 UI 未完全对齐 | 卡片样式和跳转组织仍有差异 | 是 | 继续对齐 tile 与 summary 结构 |
| 用户画像 | `ui/profile/ProfileStatusModels.kt` | 动态画像与标签 | `lib/pages/profile_page.dart` | 部分对齐 | 标签墙和解释文案仍不完整 | 是 | 继续按 Android 画像模块补齐 |
| 成就页 | `ui/profile/ProfileSummaryModels.kt` | 成就墙 / 徽章表达 | `lib/pages/profile_page.dart` | 部分对齐 | 视觉层仍不完全一致 | 否 | 在不改整体设计前提下继续资源收敛 |
| 运行状态 | `ui/profile/ProfileStatusModels.kt` | 模型、OCR、权限、存储状态 | `lib/pages/profile_page.dart` | 部分对齐 | 状态字段仍可继续补齐 | 是 | 继续从 Android runtime status 聚合模型补字段 |
| 数据空间 | `ui/profile/ProfileTileModels.kt` | 数据分层、时间资产、导出缓存 | `lib/pages/profile_page.dart` | 部分对齐 | 分层说明和视觉块仍不完全一致 | 是 | 继续按原 tile 结构补齐 |
| 偏好设置 | `ui/profile/ProfileScreenModule.kt` | 提醒、风控、地图、性能 | `lib/pages/profile_page.dart` | 已完全对齐 | iOS 提醒 / 日历需真机验证 | 是 | 保持真实写入偏好 |
| 个人资料 | `ui/profile/ProfileScreenModule.kt` | 头像、签名、生日、学校、性别等 | `lib/pages/profile_page.dart` `lib/repositories/account_repository.dart` | 功能已对齐但 UI 未完全对齐 | 头像流程与布局细节仍需收敛 | 是 | 继续对齐字段组与文案 |
| 系统分享接收 | `MainActivity.kt` `AndroidManifest.xml` | 文本 / 图片分享导入 | `lib/services/share_receive_service.dart` `ios/Runner/*` | Android 已完全对齐；iOS 需真机验证 | iOS Share Extension 还未最终完成 | 是 | 保留主 App 接收架构，后续做 iOS 真机验证 |
| OCR | `network/VLMNetworkClient.kt` | vivo OCR | `lib/services/ocr_service.dart` | 已完全对齐 | iOS 真机图片来源待验证 | 是 | 保持真实接口 |
| LLM 解析 | `network/VLMNetworkClient.kt` `utils/ResponseInterpreter.kt` | vivo chat/completions 结构化事项 | `lib/services/parser_service.dart` | 已完全对齐 | 仍需真实生产 key 联调 | 是 | 保持真实接口，无假结果 |
| 本地提醒 | `reminder/*` | 提醒排程 | `lib/services/reminder_service.dart` | Android-only 需平台封装 | iOS 提醒权限与触发需真机验证 | 是 | 保持 Flutter 本地通知方案 |
| 系统日历 | Android Intent / Calendar | 插入系统日历 | `lib/services/integration_service.dart` | Android-only 需平台封装 | iOS 日历写入需真机验证 | 是 | 保持插件封装，后续真机验收 |
| 主题与字体 | `ui/AppTheme.kt` `res/font/*` | Plus Jakarta Sans / Manrope / Literata + 暖纸色体系 | `pubspec.yaml` `assets/fonts/*` `lib/app.dart` | 部分对齐 | 主题仍未抽到独立 `theme/` 体系 | 是 | 继续把颜色 / typography 从页面内剥离 |

## 当前结论

- 已完全对齐：账号体系、真实解析、时间线导出、基础提醒/日历/分享链路。
- 功能已对齐但 UI 未完全对齐：首页、校验页、时间线、个人资料、智能体中心。
- 仍需真机验证：iOS 拍照、系统分享接收、通知、日历、导出文件打开。
- 当前不能宣称“完全 1:1 完成”，因为 `我的` 页和时间线的视觉层、以及 iOS 真机侧系统能力，仍有尾差。
