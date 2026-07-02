# 织时 Flutter 跨平台工程

这是《织时》移动应用创新赛版本的 Flutter 工程，真实迁移原 Android 原型的校园通知解析、待确认、时间线、本地提醒、系统日历和 PDF 导出能力。

## 环境

```powershell
Set-Location 'E:\tw_mobile_project'
$env:Path='E:\devtools\flutter\bin;C:\Program Files\Git\cmd;E:\AndroidSDK\platform-tools;E:\AndroidSDK\cmdline-tools\latest\bin;'+$env:Path
$env:PUB_CACHE='E:\devtools\pub-cache'
$env:GRADLE_USER_HOME='E:\devtools\gradle-cache'
$env:ANDROID_HOME='E:\AndroidSDK'
$env:ANDROID_SDK_ROOT='E:\AndroidSDK'
$env:JAVA_HOME='E:\AIGC\tools\jdk17\jdk-17.0.19+10'
```

## 真实 API 参数

Flutter 工程不把 vivo 凭据写进源码。运行真实解析时通过 `--dart-define` 注入：

```powershell
flutter run --dart-define=VLM_APP_ID=你的AppID --dart-define=VLM_API_KEY=你的AppKey
```

可选：

```powershell
--dart-define=VLM_MODEL_NAME=Volc-DeepSeek-V3.2
--dart-define=VLM_API_ENDPOINT=https://api-ai.vivo.com.cn/v1/chat/completions
--dart-define=VLM_OCR_ENDPOINT=https://api-ai.vivo.com.cn/ocr/general_recognition
```

未传入 `VLM_API_KEY` 时，解析和 OCR 会明确报配置错误，不会走 mock、demo 或本地规则兜底。

## 验证命令

```powershell
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

已在 Windows + E 盘 Android SDK/JDK/Flutter 环境下完成 Debug APK 构建、安装到 `emulator-5554` 并启动到前台。
