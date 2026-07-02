# iOS TestFlight 发布准备指南

更新时间：`2026-07-02`

本文只用于《织时 / TimeWeaver》Flutter iOS 云端签名、上传 TestFlight 和真机测试准备。不修改现有 UI，不新增 mock/demo/假数据，不用静态说明替代真实功能。

## 当前构建状态

GitHub Actions 已通过：

- `flutter pub get`
- `flutter analyze`
- `flutter test`
- `pod install`
- `flutter build ios --release --no-codesign`

这证明当前 Flutter、Dart、CocoaPods 和 Xcode 无签名编译链路可以通过。它不等于 App 已经可以安装到 iPhone/iPad，也不等于系统分享、通知、日历、相机、相册、PDF 等真实设备能力已经验证完成。

## Apple Developer Program 需要准备什么

- 已开通 Apple Developer Program 的 Apple ID。
- 可用于 App Store Connect 的团队权限。
- Bundle Identifier：`com.zhishi.timeweaver`。
- App Group：`group.com.zhishi.timeweaver`。
- Distribution signing certificate。
- App Store provisioning profile。
- App Store Connect API Key，用于 Codemagic 自动上传。
- iPhone 和 iPad 测试设备，以及可加入 TestFlight 的 Apple ID。

不要把证书、`.p8`、Team ID、Provisioning Profile、API Key 写入仓库。

## Bundle ID 如何创建

1. 登录 Apple Developer。
2. 进入 `Certificates, Identifiers & Profiles`。
3. 打开 `Identifiers`，新增 `App IDs`。
4. Platform 选择 iOS。
5. Bundle ID 选择 Explicit。
6. 填写 `com.zhishi.timeweaver`。
7. 按真实功能开启需要的 capability，至少关注 App Groups。
8. App Group 使用 `group.com.zhishi.timeweaver`，Runner 和 Share Extension 后续必须使用同一个组。

当前工程的 iOS Runner 已使用 `com.zhishi.timeweaver`。`Info.plist` 通过 `$(PRODUCT_BUNDLE_IDENTIFIER)` 引用，不单独硬写。

## App Store Connect 如何创建 App

1. 登录 App Store Connect。
2. 进入 `My Apps`。
3. 新建 App，平台选择 iOS。
4. App 名称填写 `织时`。
5. Bundle ID 选择 `com.zhishi.timeweaver`。
6. SKU 使用项目内部唯一值，例如 `timeweaver-ios`。
7. 创建后完善隐私、分类、年龄分级、测试信息和导出合规信息。

## App Store Connect API Key 如何配置

1. 在 App Store Connect 打开 `Users and Access`。
2. 进入 `Integrations` 或 `Keys`。
3. 新建 API Key，并授予 TestFlight 上传所需权限。
4. 保存 Issuer ID、Key ID 和 `.p8` 私钥。
5. 在 Codemagic 中配置 App Store Connect integration，建议命名为 `codemagic_app_store_connect`。

`.p8` 文件和 API Key 信息只放在 Codemagic 后台，不提交到 Git。

## Codemagic 如何配置 signing

Codemagic 需要配置：

- App Store Connect integration：`codemagic_app_store_connect`。
- 环境变量组：`ios_signing`。
- 环境变量组：`vivo_api`。
- `BUNDLE_ID=com.zhishi.timeweaver`。
- `VLM_APP_ID`。
- `VLM_API_KEY`。
- iOS distribution certificate。
- App Store provisioning profile，匹配 `com.zhishi.timeweaver`。

如果使用 Share Extension，后续还需要为扩展 target 配置独立 Bundle ID、App Group 和 provisioning profile。

## Codemagic 如何上传 TestFlight

1. 先运行 `ios-build-check`，确认无签名 iOS release 编译通过。
2. 确认证书、profile、App Store Connect integration 和环境变量都已配置。
3. 运行 `ios-testflight-release`。
4. Codemagic 会执行测试、安装 Pods、应用 signing profiles、构建 signed IPA。
5. 构建成功后通过 App Store Connect integration 上传 TestFlight。
6. 到 App Store Connect 的 TestFlight 页面等待 Apple 处理 build。

`ios-testflight-release` 不应写死任何 Apple API Key、证书、Team ID 或 Provisioning Profile。

## iPhone/iPad 如何安装 TestFlight 版本

1. 在 App Store 安装 Apple 官方 TestFlight。
2. 把测试用 Apple ID 加入 App Store Connect 测试员。
3. 接收 TestFlight 邀请邮件，或通过公开测试链接加入。
4. 在 TestFlight 中安装《织时》。
5. 每次上传新 build 后，在 TestFlight 更新并重新测试。

## 必须真机验证的功能

- iPhone 冷启动和热启动。
- iPad 冷启动和横竖屏显示。
- 首页、时间线、个人页的真实交互。
- 文本输入调用 vivo API 解析。
- 相册选择图片并进入 OCR/解析链路。
- 拍照输入并进入 OCR/解析链路。
- 从外部 App 系统分享文本/图片进入《织时》。
- 确认卡片生成、编辑、确认和保存。
- 重启后本地数据仍存在。
- 调起系统日历并写入事项。
- 本地通知权限申请和提醒触发。
- PDF 导出、打开和系统分享。
- 权限拒绝后的真实错误提示。
- 无网络和接口失败时的真实错误提示。

未在 iPhone/iPad 上运行前，不能声称 iOS 真机验证、TestFlight 验收或上架前功能验收已完成。

