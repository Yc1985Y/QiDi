# 真实功能完成报告

更新时间：`2026-07-03`

| 原安卓功能 | Flutter 是否已对齐 | 对应 Flutter 文件 | 是否真实功能 | 是否需要 iOS 真机验证 | 备注 |
|---|---|---|---|---|---|
| 本地账号登录 | 是 | `lib/pages/login_page.dart` `lib/repositories/account_repository.dart` | 是 | 否 | SQLite + 会话恢复 |
| 本地账号注册 | 是 | `lib/pages/login_page.dart` `lib/repositories/account_repository.dart` | 是 | 否 | 无云假登录 |
| 个人资料保存 | 是 | `lib/pages/profile_page.dart` `lib/app.dart` | 是 | 部分需要 | 头像拍照 / 相册在 iOS 需真机验收 |
| 文本输入解析 | 是 | `lib/pages/input_page.dart` `lib/services/parser_service.dart` | 是 | 否 | 缺 API key 时真实报错 |
| 剪贴板导入 | 是 | `lib/pages/input_page.dart` | 是 | 否 | 非 placeholder |
| 相册导入 | 是 | `lib/pages/input_page.dart` | 是 | 是 | iOS 照片权限需真机验收 |
| 实时拍照导入 | 部分 | `lib/pages/live_camera_capture_page.dart` | 是 | 是 | Android 已本地编译通过，iOS 需真机验证 |
| 语音输入 | 是 | `lib/app.dart` `lib/services/speech_service.dart` | 是 | 是 | iOS 录音/识别需真机验收 |
| 系统分享文本导入 | 是 | `lib/services/share_receive_service.dart` | 是 | 是 | iOS 主 App 链路保留，Share Extension 仍需完成验证 |
| 系统分享图片导入 | 是 | `lib/services/share_receive_service.dart` | 是 | 是 | 同上 |
| OCR 识别 | 是 | `lib/services/ocr_service.dart` | 是 | 是 | iOS 图片输入链路需真机验收 |
| LLM 结构化解析 | 是 | `lib/services/parser_service.dart` | 是 | 否 | 不返回 mock 结果 |
| 独立校验页 | 是 | `lib/pages/review_page.dart` | 是 | 否 | 保留真实编辑和确认 |
| 冲突检测 | 是 | `lib/app.dart` `lib/pages/review_page.dart` | 是 | 否 | 使用真实时间线数据 |
| 确认写入时间线 | 是 | `lib/app.dart` | 是 | 否 | 真写本地存储 |
| 时间线日视图 | 是 | `lib/pages/timeline_page.dart` `lib/pages/timeline_logic.dart` | 是 | 否 | |
| 时间线周视图 | 是 | `lib/pages/timeline_page.dart` `lib/pages/timeline_logic.dart` | 是 | 否 | |
| 时间线月视图 | 是 | `lib/pages/timeline_page.dart` `lib/pages/timeline_logic.dart` | 是 | 否 | |
| 日历总览 | 是 | `lib/pages/timeline_page.dart` | 是 | 否 | 当前为内嵌结构 |
| 时间线详情编辑 | 是 | `lib/pages/timeline_page.dart` | 是 | 否 | |
| 地图导航 | 是 | `lib/services/integration_service.dart` | 是 | 是 | iOS 地图跳转需真机验收 |
| 复制摘要 | 是 | `lib/services/integration_service.dart` | 是 | 否 | |
| 系统分享出站 | 是 | `lib/services/integration_service.dart` | 是 | 是 | iOS 分享面板需真机验收 |
| 复制成新事项 | 是 | `lib/app.dart` | 是 | 否 | |
| 删除事项 | 是 | `lib/app.dart` | 是 | 否 | |
| 本地提醒 | 是 | `lib/services/reminder_service.dart` | 是 | 是 | iOS 通知权限/触发需真机验收 |
| 系统日历写入 | 是 | `lib/services/integration_service.dart` | 是 | 是 | iOS 日历权限与写入需真机验收 |
| 导出 PDF | 是 | `lib/services/timeline_export_service.dart` | 是 | 是 | iOS 打开文件需真机验收 |
| 导出 PNG | 是 | `lib/services/timeline_export_service.dart` | 是 | 是 | 同上 |
| 导出 JPG | 是 | `lib/services/timeline_export_service.dart` | 是 | 是 | 同上 |
| 导出记录 | 是 | `lib/models/export_record.dart` `lib/pages/profile_page.dart` | 是 | 否 | 本地持久化 |
| 通知中心 | 是 | `lib/models/inbox_message.dart` `lib/pages/profile_page.dart` | 是 | 否 | 真回流数据 |
| 历史记录筛选 | 是 | `lib/pages/profile_page.dart` | 是 | 否 | 日期 / 状态 / 来源 |
| 运行状态 | 是 | `lib/pages/profile_page.dart` | 是 | 部分需要 | 权限可读，iOS 最终状态需真机确认 |
| 用户画像 | 部分 | `lib/pages/profile_page.dart` | 是 | 否 | 真实计算，但视觉未完全 1:1 |
| 成就页 | 部分 | `lib/pages/profile_page.dart` | 是 | 否 | 基于真实计数，视觉仍可继续收敛 |
| 隐私与安全偏好 | 是 | `lib/pages/profile_page.dart` | 是 | 否 | 真写偏好 |
| 数据空间 | 部分 | `lib/pages/profile_page.dart` | 是 | 否 | 功能真实，视觉结构仍有尾差 |

## 当前严格结论

- 未发现为了过流程而新增的 `mock / demo / placeholder / 空壳按钮`。
- 已完成的条目都对应真实入口、真实动作、真实存储或真实系统调用。
- 仍不能宣称完成的部分主要是两类：
  1. iOS 侧系统能力真机验收；
  2. 某些页面的视觉与结构还没有做到和 Android 原工程完全 1:1。
