# iOS 云端构建与 TestFlight 指南

更新时间：`2026-07-02`

本指南只服务《织时 / TimeWeaver》Flutter 跨平台迁移工程的 iOS 云端构建与 TestFlight 准备，不修改现有 UI，不新增 mock/demo/假数据。

## Windows 本机能做什么

Windows 本机可以完成：

- Flutter/Dart 代码开发。
- `flutter analyze`。
- `flutter test`。
- Android Debug APK 构建与模拟器安装。
- iOS 工程文件、权限说明、CI 配置、TestFlight 文档准备。
- 检查是否存在 Android-only / Windows-only 代码路径。

Windows 本机不能完成：

- iOS App 编译。
- iOS 签名。
- IPA 生成。
- TestFlight 上传。
- iPhone/iPad 真机安装验证。

## 为什么普通云服务器不能构建 iOS

iOS 构建必须使用 macOS、Xcode 和 Apple 签名工具链。普通 Linux/Windows 云服务器没有 Xcode、iOS SDK、codesign、xcodebuild 和 Apple 平台签名能力，所以不能构建可安装到 iPhone/iPad 的 iOS App。

可以使用的云环境包括：

- Codemagic 的 macOS 构建机。
- GitHub Actions 的 `macos-latest` runner。
- 其他提供合法 macOS/Xcode 的 CI 服务。

## 当前工程云端构建条件检查

- `ios/` 目录：已存在，包含 `Runner.xcodeproj`、`Runner.xcworkspace`、`Runner`、`RunnerTests`。
- `ios/Podfile`：已补充标准 Flutter Podfile，平台版本为 iOS 13.0。
- `Info.plist` 权限：已包含相机、相册、通知、麦克风、语音识别、日历、联系人、分享回跳 URL Scheme。
- `pubspec.yaml` iOS 依赖：当前核心插件均有 iOS/Darwin 实现，包括相册、通知、TTS、日历、分享、分享接收、语音、URL 打开、文件打开。
- Android-only 路径：业务 Dart 代码未发现硬编码 Android 文件路径；Android 专用配置集中在 `android/`。
- Windows-only 路径：`ios/Flutter/Generated.xcconfig` 等生成文件含本机 Windows 路径，但该目录已在 `ios/.gitignore` 中忽略；云端应通过 `flutter pub get` 重新生成。
- iOS 系统分享结构：已加入 `Share Extension` target、`ShareViewController.swift`、扩展 `Info.plist`、共享 App Group entitlements 和 Pod target。
- 仍需云端与真机验证：扩展必须使用独立签名 profile，并在 TestFlight 上验证文本/图片分享回跳和真实解析。

## Codemagic 如何接入 GitHub

1. 将当前工程推送到 GitHub 仓库 `Yc1985Y/QiDi.git`。
2. 登录 Codemagic。
3. 连接 GitHub 账号并授权 Codemagic 访问该仓库。
4. 在 Codemagic 中添加应用，选择该仓库。
5. 选择使用仓库内的 `codemagic.yaml`。
6. 先运行 `ios-build-check`，验证无签名 iOS 构建。
7. 准备 Apple Developer Program 后，再配置签名并运行 `ios-testflight-release`。

## App Store Connect API Key 在哪里配置

在 Apple Developer / App Store Connect 中创建 API Key：

1. 进入 App Store Connect。
2. 打开 `Users and Access`。
3. 打开 `Integrations` 或 `Keys`。
4. 新建 API Key，权限至少满足 TestFlight 上传。
5. 保存：
   - Issuer ID
   - Key ID
   - `.p8` 私钥文件

在 Codemagic 中配置：

- 推荐使用 Codemagic 的 App Store Connect integration。
- integration 名称可设置为 `codemagic_app_store_connect`，对应 `codemagic.yaml` 中的占位。
- 不要把 `.p8`、Issuer ID、Key ID 写入仓库。

## Bundle Identifier 如何设置

当前 iOS Runner 的 Bundle Identifier 是：

```text
com.zhishi.timeweaver
```

正式上架前建议确认是否使用这个 ID。如果要修改，需要同步修改：

- `ios/Runner.xcodeproj/project.pbxproj` 中 Runner target 的 `PRODUCT_BUNDLE_IDENTIFIER`。
- Codemagic 环境变量 `BUNDLE_ID`。
- Apple Developer 中的 App ID。
- App Store Connect 中的 App 记录。
- App Group，例如 `group.com.zhishi.timeweaver`。
- Share Extension Bundle ID：`com.zhishi.timeweaver.ShareExtension`。

Bundle Identifier 一旦用于 App Store Connect，后续不要随意改。

## no-codesign 构建和正式签名构建的区别

`flutter build ios --release --no-codesign`：

- 用于检查 Dart、Flutter、Xcode 编译是否能过。
- 不需要 Apple 证书。
- 不生成可安装到 iPhone/iPad 的正式 IPA。
- 不能上传 TestFlight。

正式签名构建：

- 需要 Apple Developer Program。
- 需要 Bundle ID、证书、Provisioning Profile、App Store Connect API Key。
- 会生成可上传 TestFlight 的 `.ipa`。
- 可以通过 TestFlight 安装到 iPhone/iPad。

## 没有 Apple Developer Program 时能做到哪一步

可以做到：

- Windows 本机 Android 构建。
- GitHub Actions / Codemagic 的 `--no-codesign` iOS 编译检查。
- 修复 iOS 编译错误。
- 完成权限、Bundle ID、文档和 CI 配置。

不能做到：

- 上传 TestFlight。
- App Store Connect 创建正式 App 记录。
- 长期有效的真机分发。
- 正式上架应用市场。

## 有 Apple Developer Program 后如何上传 TestFlight

1. 在 Apple Developer 中创建 App ID，Bundle ID 与工程一致。
2. 创建 `com.zhishi.timeweaver.ShareExtension` 扩展 App ID，并为 Runner 和 Share Extension 配置同一个 App Group `group.com.zhishi.timeweaver`。
3. 在 App Store Connect 创建 App。
4. 在 Codemagic 配置 App Store Connect integration。
5. 在 Codemagic 配置 signing certificate 和 provisioning profiles。
6. 为主 App 和 Share Extension 分别准备 App Store provisioning profile；`codemagic.yaml` 会在发布流程中拉取扩展 profile，并由 `xcode-project use-profiles` 应用。
7. 配置环境变量：
   - `VLM_APP_ID`
   - `VLM_API_KEY`
8. 运行 `ios-testflight-release` workflow。
9. 构建成功后到 App Store Connect 的 TestFlight 页面等待处理。
10. 添加 iPhone/iPad 使用的 Apple ID 为内部或外部测试员。
11. 在 iPhone/iPad 安装 TestFlight，再安装《织时》测试版。

## TestFlight 如何安装到 iPhone/iPad

1. iPhone/iPad 安装 Apple 官方 `TestFlight` App。
2. 使用加入测试的 Apple ID 登录。
3. 接收 App Store Connect 发送的测试邀请，或通过公开测试链接加入。
4. 在 TestFlight 中安装《织时》。
5. 每次上传新 build 后，在 TestFlight 中更新。

## 必须在 iPhone/iPad 上真实测试的功能

- 首次启动、启动画面、桌面名称 `织时`、App 图标。
- vivo API 真实解析：文本通知 -> 待确认卡。
- 图片 OCR：相册图片、拍照图片。
- 系统分享：从微信、相册、浏览器、备忘录分享文本/图片进入 App。
- 确认后写入系统日历。
- 本地通知权限申请与提醒触发。
- 语音输入与系统语音识别权限。
- TTS 播报。
- PDF 导出、打开和分享。
- 地图跳转。
- iPad 横竖屏和布局可读性。
- 无网络、权限拒绝、接口失败时的真实错误提示。

未在 iPhone/iPad 上跑过之前，不能声称 iOS 真机验证已完成。
