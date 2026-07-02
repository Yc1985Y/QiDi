# iOS 兼容迁移报告

更新时间：`2026-07-02`

## 迁移目标

将原 Android 作品《织时：将校园信息碎片整合为专属时间线的智能助手》迁移为 Flutter 跨平台工程，在保留原有真实功能链路的前提下，为 Android 和 iOS 共用一套业务代码。

## 原功能保留映射

| 原 Android 功能 | Flutter 迁移状态 | 当前实现 |
| --- | --- | --- |
| 手动文本导入 | 已实现 | `InputPage` -> `AppController.parseInput` |
| 拍照/相册导入 | 已实现 | `image_picker` -> vivo OCR -> vivo chat |
| 系统分享文本 | Android 已实现，iOS 主 App 侧已接入 | `receive_sharing_intent` + Android intent-filter |
| 系统分享图片 | Android 已实现，iOS 主 App 侧已接入 | 图片路径进入 OCR + 解析 |
| vivo 真实模型解析 | 已实现 | `ParserService`，缺 key 直接报错 |
| 待确认卡 | 已实现 | `ConfirmCard` |
| 确认加入时间线 | 已实现 | `EventItem.fromParsedNotice` + 本地保存 |
| 确认后调系统日历 | 已实现 | `add_2_calendar` |
| 本地提醒 | 已实现 | `flutter_local_notifications` + `timezone` |
| 时间线 PDF 导出 | 已实现 | `pdf` + `NotoSansSC-Regular.otf` |
| 地图跳转 | 已实现 | `url_launcher` |
| 出站分享/复制 | 已实现 | `share_plus` / Clipboard |
| 语音转写 | 已实现系统语音版本 | `speech_to_text` |
| TTS 播报 | 已实现 | `flutter_tts` |

## iOS 已完成内容

- `ios/Runner/Info.plist` 已加入：
  - 相机、相册、通知、麦克风、语音识别权限说明。
  - 日历权限 `NSCalendarsUsageDescription`。
  - 联系人权限 `NSContactsUsageDescription`，用于系统日历界面可能触发的联想能力。
  - `CFBundleURLTypes`，用于 `receive_sharing_intent` 回跳主 App。
  - `AppGroupId` 占位。
- `ios/Runner/SceneDelegate.swift` 已按插件要求转发分享 URL 生命周期回调。
- `ios/Runner/Runner.entitlements` 已加入 App Group 占位。
- Xcode Runner target 已配置 `CODE_SIGN_ENTITLEMENTS` 与默认 `CUSTOM_GROUP_ID=group.com.zhishi.timeweaver`。

## iOS 仍需 macOS/Xcode 完成

Windows 无法完成以下真实验证：

- iOS 编译。
- Apple Developer Team 签名。
- App Group capability 开通。
- Share Extension target 创建与签名。
- iPhone/iPad 真机安装。
- 从 iOS 系统分享文本/图片进入 App 的端到端测试。

在 macOS 上继续时，应完成：

1. `flutter config --enable-swift-package-manager`
2. 用 Xcode 打开 `ios/Runner.xcworkspace`
3. 为 Runner target 选择 Apple Team。
4. 为 Runner target 开启 App Groups，值使用团队可用的 group id。
5. 新建 Share Extension target。
6. Share Extension 的 `Info.plist` 支持 text、web url、image。
7. Share Extension 继承 `RSIShareViewController`。
8. Share Extension target 链接 `receive-sharing-intent` Swift Package product。
9. Runner target 的 `Embed Foundation Extension` 放在 `Thin Binary` 之前。
10. 在 iPhone/iPad 上验证分享文本、分享图片、日历、提醒和 PDF 导出。

## Android 已验证

- `flutter analyze` 通过。
- `flutter test` 通过。
- `flutter build apk --debug` 通过。
- APK 已安装到 `emulator-5554`。
- `com.zhishi.timeweaver_flutter/.MainActivity` 已启动到前台。
- 最近日志未见启动期 `FATAL EXCEPTION`。

## 运行限制

- 未带 `--dart-define=VLM_APP_ID` 与 `--dart-define=VLM_API_KEY` 的构建不会调用真实 vivo 接口，会显示配置错误。
- 真实接口联调需要使用原项目同源 vivo 凭据通过 `--dart-define` 注入。
- iOS 分享扩展不能在 Windows 上生成可签名交付物，必须到 macOS/Xcode 完成。
