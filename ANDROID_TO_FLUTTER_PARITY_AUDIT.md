# Android -> Flutter 对齐审计报告

更新时间：`2026-07-02`

## 审计范围

- 源 Android 工程：`D:\桌面\本科\课题all\中国高校计算机大赛AIGC赛道\VisualSemanticAgent`
- 目标迁移仓库：`D:\桌面\本科\课题all\26移动应用创新赛\织时_移动应用创新赛`
- Flutter 工程：`D:\桌面\本科\课题all\26移动应用创新赛\织时_移动应用创新赛\timeweaver_flutter`

本报告基于以下内容对齐：

- Android 侧实际代码与资源：
  - `MainActivity.kt`
  - `ui/home/*`
  - `ui/review/ReviewScreenModule.kt`
  - `ui/timeline/*`
  - `ui/profile/*`
  - `ui/LoginScreen.kt`
  - `plan/PlanModels.kt`
  - `storage/AppPreferencesStore.kt`
  - `account/*`
  - `network/VLMNetworkClient.kt`
  - `intent/IntentDispatcher.kt`
  - `reminder/ReminderScheduler.kt`
  - `voice/VoiceRecognitionManager.kt`
  - `ui/AppTheme.kt`
  - `AndroidManifest.xml`
  - `res/values/strings.xml`
  - `res/font/*`
- Flutter 侧实际代码与资源：
  - `lib/app.dart`
  - `lib/models/*`
  - `lib/pages/*`
  - `lib/services/*`
  - `lib/repositories/event_repository.dart`
  - `android/app/src/main/AndroidManifest.xml`
  - `ios/Runner/Info.plist`
  - `pubspec.yaml`

结论先行：

- Flutter 当前已经具备真实主闭环：`输入 -> 真实解析 -> 待确认 -> 保存时间线 -> 本地提醒 -> 系统日历 -> PDF 导出`
- 但与 Android 原工程相比，仍存在明显的页面层级、数据模型、账户体系、通知中心、历史回看、运行状态、导出记录等差距
- 当前最主要的问题不是“核心功能不存在”，而是“原工程的深层页面结构和数据沉淀还没有完整迁过去”

---

## 一、源 Android 工程完整功能清单

### 1. 启动与账号

- 登录页 / 注册页，本地账号进入
- 本地 SQLite 用户表
- 当前登录会话持久化
- 测试账号自动注入
- 个人资料编辑：
  - 昵称
  - 头像
  - 签名
  - 生日
  - 学校
  - 年龄
  - 性别
  - 专业
  - 年级
  - 家乡

### 2. 首页输入与导入

- 三页底部导航：`首页 / 时间线 / 我的`
- 首页 Today-First 概览
- 文本输入
- 剪贴板导入
- 拍照导入
- 相册导入
- 系统分享文本导入
- 系统分享图片导入
- 语音输入
- 语音失败后的手动补录入口
- 相机实时预览 / 快门入口
- 相机权限、麦克风权限、通知权限状态管理

### 3. 解析链路

- vivo OCR 接口
- vivo chat/completions 接口
- 多事项 `events[]` 结构化输出
- 相对时间解析
- 结果动作类型：
  - `create_event`
  - `navigate`
  - `clarification`
  - `tts_feedback`
  - `unknown`
- 风险控制：
  - 高风险动作拦截
  - 低置信度静默偏好
  - 地图联动偏好

### 4. 结果校验与确认

- 首页待确认卡
- 独立解析校验页 `ReviewScreenModule`
- 原始输入回顾
- 标题 / 时间 / 地点 / 备注字段编辑
- 冲突提醒
- 保存校验
- 取消本次
- 确认写入时间线

### 5. 时间线

- 时间线主页
- 日 / 周 / 月切换
- 日历总览页
- 日期分组
- 今日 / 未来 / 历史视角
- 时间线详情卡
- 时间线事项编辑
- 删除
- 复制成新事项
- 打开地图
- 复制摘要
- 系统分享
- 待确认事项跳转回首页

### 6. 提醒与系统执行

- 本地通知调度
- 提前 1 天 / 提前 1 小时等提醒策略
- 提醒数量统计
- 下一条提醒文案
- 系统日历插入页
- 地图导航意图分发

### 7. 我的 / 设置 / 二级页面

- 我的页总览 dashboard
- 状态总览
- 快捷入口
- 一键体检
- 日程表 / 时间资产
- 通知中心
- 我的成就
- 用户画像
- 隐私与安全
- 数据空间
- 运行状态
- 导出记录
- 设置
- 个人信息
- 账号详情
- 提醒中心
- 历史记录 / 历史检索
- 统计页

### 8. 侧向数据沉淀

- Agenda 列表本地持久化
- Inbox 消息持久化
- 偏好持久化
- 用户会话持久化
- 运行状态聚合数据

### 9. 导出与回看

- 导出能力在状态与详情页中作为独立能力展示
- `exportFormats` 状态中存在 `PDF / JPG / PNG`
- 时间资产回看 / 历史搜索 / 来源筛选

### 10. 视觉与资源

- 暖纸色背景
- 深绿主色
- 珊瑚 / 金色辅助色
- Plus Jakarta Sans / Manrope / Literata 字体组合
- 超圆角卡片
- 玻璃态卡片
- 启动图标资源
- 较完整的字符串资源与错误提示文案

---

## 二、目标 Flutter 工程当前功能清单

### 1. 已实现真实功能

- 三页底部导航：`首页 / 时间线 / 我的`
- 文本输入
- 拍照导入
- 相册导入
- 系统分享文本导入
- 系统分享图片导入
- 语音转写
- vivo 真实 OCR 调用
- vivo 真实 chat/completions 调用
- 缺少 `VLM_API_KEY` 时明确报错，不返回假结果
- 待确认事项列表
- 待确认事项字段编辑
- 确认后写入本地时间线
- 本地提醒调度
- 系统日历拉起
- 时间线查看
- 时间线编辑 / 删除 / 复制
- 地图跳转
- 复制摘要
- 系统分享
- PDF 导出到应用文档目录
- 本地偏好保存
- iOS 主 App 分享接收入口
- GitHub Actions / Codemagic iOS no-codesign 构建链路

### 2. 当前 Flutter 已有的数据模型

- `ParsedNotice`
- `EventItem`
- `ReminderItem`
- `SourceInfo`
- `UserPreference`

### 3. 当前 Flutter 已有持久化

- 已确认时间线事项
- 待确认事项
- 用户偏好

### 4. 当前 Flutter 已有系统能力封装

- `ParserService`
- `OcrService`
- `ReminderService`
- `IntegrationService`
- `ShareReceiveService`
- `SpeechService`
- `TtsService`
- `TimelineExportService`
- `PermissionService`

---

## 三、功能差距表

| 模块 | 安卓原工程状态 | Flutter 当前状态 | 差距 | 是否必须补齐 | 迁移方案 |
|---|---|---|---|---|---|
| 登录/注册 | 已有本地账号、注册、登录、会话恢复 | 未实现 | Flutter 无账号入口与会话层 | 是，P1 | 迁移为 Flutter 本地账号仓储与会话存储，保留本地模式，不引入云假登录 |
| 个人资料 | 头像、签名、生日、学校、年龄、性别、专业、年级、家乡完整 | 仅昵称、学校、专业、年级 | 字段缺失较多 | 是，P1 | 扩展 `UserPreference` 或新增 `AccountProfile` 模型，补齐编辑与持久化 |
| 文本输入 | 已实现 | 已实现 | 基本对齐 | 是 | 保持现有实现，继续对齐文案与校验方式 |
| 拍照/相册输入 | 已实现 | 已实现 | Flutter 无实时相机工作台，仅系统拍照/选图 | 是，P0 | 迁移 Android 相机工作台表达，至少补齐页面结构与来源反馈 |
| 系统分享接收 | Android 已打通，iOS 有 App Group/Extension 预留 | Android/Flutter 已接入，iOS 主 App 已接入 | iOS Share Extension 未完成 | 是，P0 | 保留当前主 App 接收；Share Extension 结构需继续补齐并真机验证 |
| OCR + LLM 真实链路 | 已实现 | 已实现 | 基本对齐 | 是 | 保持真实接口，不降级为本地假解析 |
| 多事项解析 | 已实现 `events[]` | 已实现 `events[]` | 基本对齐 | 是 | 保持 |
| 独立解析校验页 | 已实现 `ReviewScreenModule` | 未实现，仅首页弹窗编辑 | 缺少完整校验页和原始输入回顾 | 是，P0 | 迁移为 Flutter 独立 review 页面 |
| 冲突检测 | 已实现冲突提示 | 未实现 | 不能在确认前提醒时间冲突 | 是，P0 | 在 Flutter 确认前引入时间冲突检测 |
| 时间线视图模式 | 日 / 周 / 月 + 日历总览 | 仅按天分组列表 | 页面结构明显不足 | 是，P0 | 迁移时间线切换、日历总览与详情页 |
| 时间线详情操作 | 编辑 / 删除 / 复制 / 导航 / 复制 / 分享 | 已实现同类操作 | 当前页面承载较轻 | 是 | 在不破坏现有可用性的前提下向 Android 详情页结构靠拢 |
| 本地提醒 | 已实现 | 已实现 | 基本对齐 | 是 | 保持 |
| 通知中心 / Inbox | 已实现且持久化 | 未实现 | 缺少解析反馈回流页 | 是，P1 | 增加真实 inbox 模型、持久化与列表页 |
| 历史记录 / 历史搜索 | 已实现筛选、检索、来源过滤 | 未实现 | 缺少回看页 | 是，P1 | 基于时间线与来源信息增加历史回看模块 |
| 运行状态页 | 已实现模型/OCR/存储/权限状态页 | 未实现 | 缺少工程状态自检入口 | 是，P1 | 增加真实 runtime status 页面 |
| 导出记录 | 已有导出记录入口 | 仅 PDF 导出动作，无历史 | 缺少导出记录沉淀 | 是，P1 | 保存导出记录并在“我的”页展示 |
| 用户画像/成就/统计 | 已有独立页面 | 未实现 | 深层产品结构缺失 | 否，P2 | 后续按真实数据逐步迁移，不能用静态假页面顶替 |
| 数据空间 / 隐私与安全 | 已有独立页面 | 未实现 | 缺少产品说明与状态页 | 是，P1 | 基于真实本地存储和权限状态实现说明页 |
| 设置页 | 已有 | 当前仅偏好开关 | 深度明显不足 | 是，P1 | 迁移为独立设置页，挂接真实偏好与系统能力说明 |
| 导出格式 | 状态层已有 `PDF/JPG/PNG` | 当前仅真实 PDF | 格式能力未对齐 | 是，P1 | 先补齐导出记录与格式策略，再逐步实现真实 JPG/PNG 导出 |

---

## 四、页面差距表

| 页面 | 安卓原页面 | Flutter 当前页面 | UI 差异 | 交互差异 | 需要修改的文件 |
|---|---|---|---|---|---|
| 启动/登录 | `LoginScreen.kt` | 无 | Flutter 缺少入口层 | 无法登录/注册/恢复会话 | `lib/app.dart`，新增 `lib/pages/login_page.dart`、账号仓储 |
| 首页 | `ui/home/HomeScreenModule.kt` | `lib/pages/home_page.dart` | Flutter 当前层级更浅，少了工作台与结果区拆分 | 缺实时相机工作台、最近识别结果区、跳 review 流程 | `lib/pages/home_page.dart`、`lib/pages/input_page.dart`、新增 review 页面 |
| 解析校验页 | `ui/review/ReviewScreenModule.kt` | 无 | 缺独立校验页 | 只能弹窗改字段，缺源文本回顾与冲突提示 | 新增 `lib/pages/review_page.dart` |
| 时间线主页 | `ui/timeline/TimelineScreenModule.kt` | `lib/pages/timeline_page.dart` | Flutter 仅线性列表 | 缺日/周/月、日历总览、待确认跳转卡 | `lib/pages/timeline_page.dart`、新增 timeline 组件 |
| 时间线详情 | `ui/timeline/TimelineDetailModule.kt` | 当前 AlertDialog 编辑 + `TimelineItem` | 详情信息密度不足 | 缺完整详情抽屉/面板结构 | `lib/widgets/timeline_item.dart`、新增详情组件 |
| 日历总览 | `ui/timeline/TimelineCalendarModule.kt` | 无 | 缺页面 | 缺月份浏览、日期点选 | 新增 `lib/pages/timeline_calendar_page.dart` 或内嵌组件 |
| 我的首页 | `ui/profile/ProfileScreenModule.kt` | `lib/pages/profile_page.dart` | Flutter 目前只有基础资料卡 + 开关 | 缺 dashboard、快捷入口、工具板 | `lib/pages/profile_page.dart` |
| 通知中心 | `NotificationInboxDetailPage` | 无 | 缺页面 | 缺反馈消息回流 | 新增 profile detail/inbox 页面 |
| 历史记录 | `HistoryDetailPage` | 无 | 缺页面 | 缺搜索/过滤/来源筛选 | 新增 history 页面 |
| 运行状态 | `RuntimeStatusDetailPage` | 无 | 缺页面 | 缺模型/OCR/存储/权限状态展示 | 新增 runtime 页面 |
| 导出记录 | `ExportRecordsDetailPage` | 无 | 缺页面 | 缺导出列表沉淀 | 新增 export records 页面 |
| 设置/隐私/数据空间 | `SettingsDetailPage` 等 | 无 | 缺页面 | 缺独立设置层 | 新增 settings/detail 页面 |

---

## 五、数据模型差距表

| 模型 | 安卓字段 | Flutter 字段 | 缺失字段 | 迁移方式 |
|---|---|---|---|---|
| 日程事项 | `AgendaCardData(id,title,summary,time,location,status,isoDateTime,sourceLabel,action,reminders,ownerAccount)` | `EventItem(id,title,eventType,startTimeIso,deadlineIso,location,description,source,confidence,status,reminders,createdAtIso,updatedAtIso)` | `summary`、`sourceLabel`、`action`、`ownerAccount` 等语义未完整映射 | 扩展 Flutter `EventItem`，保留来源标签、动作类型、账户归属 |
| 待确认事项 | Android 侧由 `ExecutableIntent + ExecutionSuggestion + source preview` 驱动 | `ParsedNotice` | 缺 `fallback_query`、`sourcePreview`、冲突信息、执行模式 | 新增 review-state 模型或扩展 `ParsedNotice` |
| 输入来源 | `CampusNoticeInput(sourceType,rawText,imageUri,base64Image,userInstruction)` | `SourceInfo(type,rawText,imagePath,ocrText,importedAtIso)` | `userInstruction`、`imageUri/base64Image` 中间态 | 增加解析上下文结构，避免页面层直接堆逻辑 |
| 提醒 | `AgendaReminderData(label,minutesBefore)` | `ReminderItem(id,eventId,label,minutesBefore,scheduledAtIso,notificationId,enabled)` | Flutter 反而更完整 | 保持，必要时把 Android 语义映射到 Flutter |
| 偏好 | `reminderLeadMinutes/reminderDayEnabled/reminderHourEnabled/blockHighRisk/muteLowConfidence/autoMapLink/performanceLiteMode` | `UserPreference` 已有这些 | 账号资料字段、签名、生日、性别、家乡缺失 | 扩展 `UserPreference` 或独立 `AccountProfile` |
| Inbox 消息 | `InboxMessageData(id,type,title,summary,status,createdAtMillis,ownerAccount)` | 无 | 全部缺失 | 新增 `InboxMessage` 模型与持久化 |
| 运行状态 | `AgentRuntimeStatusData(...)` | 无 | 全部缺失 | 新增运行状态聚合模型 |
| 账号 | `AccountUser`、`AccountAuthResult` | 无 | 全部缺失 | 新增本地账号模型、仓储、会话存储 |
| 导出记录 | Android 有导出入口与记录页语义 | 无 | 全部缺失 | 新增 `ExportRecord` 模型与存储 |

---

## 六、系统能力差距表

| 系统能力 | Android 原工程 | Flutter 当前状态 | 差距结论 |
|---|---|---|---|
| 相机 | 已有实时预览、拍照入口、权限处理 | 已能调系统相机拍照 | 主闭环可用，但缺原工作台式实时预览与反馈 |
| 相册 | 已实现 | 已实现 | 基本对齐 |
| 系统分享 | Android 已实现；iOS 架构有预留 | Android 已实现；iOS 主 App 已接入 | iOS Share Extension 仍需补齐并真机验证 |
| 通知 | 已实现 WorkManager 本地提醒 | 已实现 `flutter_local_notifications` | 基本对齐 |
| 日历 | 已实现系统日历插入 | 已实现 `add_2_calendar` | 基本对齐，iOS 需真机验证 |
| PDF 导出 | Android 产品语义中已有导出能力 | 已真实生成 PDF | 当前 Flutter 仅 PDF，未覆盖 JPG/PNG |
| 文件保存 | Android 有导出概念和记录页 | Flutter 已写入文档目录 | 缺导出记录页面与二次管理 |
| 网络请求 | 已实现 vivo OCR + chat | 已实现 vivo OCR + chat | 基本对齐 |
| 权限处理 | 相机/麦克风/通知等较完整 | 已有 camera/photos/notification | 仍缺更完整的状态页和拒绝后解释页 |
| 本地存储 | DataStore + SQLite + Session + Inbox | `SharedPreferences` 仅存事件/待确认/偏好 | 数据沉淀层明显不足 |
| OCR | 已实现 | 已实现 | 基本对齐 |
| LLM/AIGC | 已实现 | 已实现 | 基本对齐 |
| 错误处理 | 原工程错误态更完整，含重试语义与 inbox 回流 | 有基础报错 | 缺系统化错误沉淀与历史回看 |

---

## 七、资源差距表

| 资源类型 | Android 原工程 | Flutter 当前状态 | 差距 |
|---|---|---|---|
| 主字体 | `plus_jakarta_sans_*`、`manrope_*`、`literata_*` | 仅 `NotoSansSC-Regular.otf` 用于 PDF | 页面字体体系未迁移 |
| 图标资源 | launcher foreground、品牌图标 | Flutter 默认图标与 iOS AppIcon 已有一套 | 与原 Android 品牌图标仍未完全统一 |
| 色彩系统 | `AppTheme.kt` 中完整色板 | `app.dart` 内只保留了主色系子集 | 主题系统未拆到独立 `theme/`，可维护性不足 |
| 字符串 | `strings.xml` 较完整 | Flutter 多数文案散落页面 | 统一文案资源层缺失 |
| 启动画面 | Android 有 app icon / theme | Flutter 有默认启动图与 iOS LaunchScreen | 未完成与原作品统一设计核对 |
| 字体与排版 | Android 有完整 Typography | Flutter 仅少量 TextTheme | 字号、字重、字体家族未完整对齐 |

建议迁移到：

- `timeweaver_flutter/assets/fonts/`
- `timeweaver_flutter/assets/icons/`
- `timeweaver_flutter/lib/theme/`

---

## 八、P0 / P1 / P2 优先级

### P0：比赛演示主闭环必须完整对齐

1. 独立解析校验页
2. 确认前冲突检测
3. 时间线 `日 / 周 / 月 / 日历总览`
4. 时间线详情结构对齐
5. 系统分享链路继续保留，iOS Share Extension 结构继续补齐
6. 来源、原始输入、待确认状态在 UI 中完整回放
7. 核心主题与关键文案继续向 Android 原设计收敛

### P1：真实应用体验必须补齐

1. 本地账号 / 登录 / 注册 / 会话
2. 完整个人资料字段
3. 通知中心 / Inbox 持久化
4. 历史记录 / 搜索 / 来源筛选
5. 运行状态页
6. 导出记录页
7. 设置 / 隐私与安全 / 数据空间
8. 导出格式从仅 PDF 继续扩到真实 JPG / PNG

### P2：增强体验但不阻断主闭环

1. 成就页
2. 用户画像页
3. 统计页
4. 更完整的品牌资源统一
5. 更细颗粒度的动画与视觉强化

---

## 当前审计结论

### 已完成对齐的主线

- 多入口真实导入
- 真实 OCR / LLM 解析
- 待确认后进入时间线
- 本地提醒
- 系统日历
- 出站分享 / 复制 / 地图
- PDF 导出
- iOS no-codesign 构建链路

### 当前最明显缺口

- Flutter 还没有把 Android 原工程的“深层页面结构”迁完整
- `我的` 页差距最大
- `解析校验页` 与 `时间线视图层次` 是最关键的 P0 缺口
- 数据层还缺账号、Inbox、运行状态、导出记录等真实模型

### 下一步执行建议

1. 先做 P0：
   - review 校验页
   - timeline 多视图
   - 核心来源回放 / 冲突检测
2. 再做 P1：
   - 通知中心
   - 运行状态
   - 导出记录
   - 账号与个人资料
3. 所有新增项都必须是真实现，不能用说明文字、空页面或假数据占位

---

## 2026-07-03 增量更新：实时相机工作台与字体资源回迁

### 本步完成内容

- 新增 Flutter 实时相机工作台：
  - `timeweaver_flutter/lib/pages/live_camera_capture_page.dart`
  - 对齐 Android `ui/camera/LiveCameraCaptureScreen.kt`
  - 已接入：
    - 实时预览
    - 快门拍照
    - 闪光灯开关
    - 前后镜头切换
    - 相册入口
- 更新输入页拍照入口：
  - `timeweaver_flutter/lib/pages/input_page.dart`
  - 首页“拍照识别”和“拍照”按钮不再直接走系统相机 picker，而是先进入实时取景页
- 回迁 Android 字体资源到 Flutter：
  - `assets/fonts/literata_*`
  - `assets/fonts/manrope_*`
  - `assets/fonts/plus_jakarta_sans_*`
  - `pubspec.yaml`
  - `lib/app.dart`
- 修复可见中文乱码文案：
  - `lib/app.dart`
  - `lib/pages/timeline_page.dart`

### 本步验证结果

- `dart analyze`：通过
- `flutter test`：通过
- `flutter build apk --debug`：通过
- 由于 Windows 中文路径会触发 Gradle 非 ASCII 限制，本步 APK 在 ASCII 路径 `E:\codex_timeweaver_flutter_check` 下完成真实构建

### 本步结论

- Flutter 拍照链路已从“直接调系统相机”推进到更接近原 Android 的“实时相机工作台”。
- 视觉资源方面已经开始回用 Android 原字体，不再只依赖迁移工程临时字体。
- 这一步仍然不是“完全 1:1 完成”；`我的` 页和时间线细部视觉、iOS 真机系统能力验证仍需继续。
