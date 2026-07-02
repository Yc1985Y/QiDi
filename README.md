# 织时_移动应用创新赛

作品名称：`织时：将校园信息碎片整合为专属时间线的智能助手`

本目录是从原工程 `D:\桌面\本科\课题all\中国高校计算机大赛AIGC赛道\VisualSemanticAgent` 迁移出来的移动应用创新赛版本。原 Android 工程已完整保留，新 Flutter 工程用于推进 Android / iOS 跨平台迁移。

## 目录结构

- `织时_Android原型/`：从原工程复制来的 Android 原型，保留原有代码、资源和功能基线。
- `timeweaver_flutter/`：新的 Flutter 跨平台工程，当前主要开发入口。
- `配置说明.md`：本机 E 盘环境、Flutter 命令、vivo API 参数传入方式。
- `进度说明.md`：本迁移工程当前落地状态和验证记录。
- `IOS_COMPATIBILITY_MIGRATION_REPORT.md`：iOS 兼容迁移报告与仍需 macOS/Xcode 验证的部分。

## 当前 Flutter 能力

- 多入口导入：手动文本、拍照、相册、系统分享文本、系统分享图片、语音转写。
- 真实接口链路：文本走 vivo chat completions，图片先走 vivo OCR，再进入结构化解析；没有配置 API key 时直接报配置错误，不做本地假解析。
- 待确认机制：解析结果进入确认卡，用户确认后进入本地时间线。
- 系统能力：确认后调系统日历确认添加，本地通知排程，地图跳转，系统分享，复制文本，TTS 播报。
- 时间线导出：生成真实 PDF 文件到应用文档目录，并调用系统文件打开器。

## 构建入口

推荐使用 ASCII 目录入口，避免中文路径影响 Flutter 工具链：

```powershell
Set-Location 'E:\tw_mobile_project'
```

常用环境变量：

```powershell
$env:Path='E:\devtools\flutter\bin;C:\Program Files\Git\cmd;E:\AndroidSDK\platform-tools;E:\AndroidSDK\cmdline-tools\latest\bin;'+$env:Path
$env:PUB_CACHE='E:\devtools\pub-cache'
$env:GRADLE_USER_HOME='E:\devtools\gradle-cache'
$env:ANDROID_HOME='E:\AndroidSDK'
$env:ANDROID_SDK_ROOT='E:\AndroidSDK'
$env:JAVA_HOME='E:\AIGC\tools\jdk17\jdk-17.0.19+10'
```

带真实 vivo 参数运行或构建：

```powershell
flutter run --dart-define=VLM_APP_ID=你的AppID --dart-define=VLM_API_KEY=你的AppKey
```

Debug APK 构建：

```powershell
flutter build apk --debug
```

最新已验证 APK：

`E:\tw_mobile_project\build\app\outputs\flutter-apk\app-debug.apk`
