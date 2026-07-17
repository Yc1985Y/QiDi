# iOS TestFlight 提交检查清单

更新时间：`2026-07-02`

本清单用于《织时 / TimeWeaver》进入 TestFlight 前逐项检查。所有功能必须是真实实现，不允许 mock/demo/placeholder/空壳按钮冒充完成。

## App 身份

- [ ] Bundle Identifier 已确定，建议当前值：`com.zhishi.timeweaver`
- [ ] Apple Developer App ID 已创建。
- [ ] Share Extension App ID `com.zhishi.timeweaver.ShareExtension` 已创建。
- [ ] Runner 与 Share Extension 均已启用 `group.com.zhishi.timeweaver`。
- [ ] 主 App 与 Share Extension 的 App Store provisioning profile 均已准备。
- [ ] App Store Connect App 记录已创建。
- [ ] Display Name 为：`织时`
- [ ] 版本号和 build number 符合 TestFlight 上传要求。
- [ ] Codemagic 环境变量 `BUNDLE_ID` 与 Xcode 工程一致。

## 视觉与基础资源

- [ ] 不重做原 Android 设计风格。
- [ ] 保留原有三页结构和既有产品表达。
- [ ] App 图标完整，包含 App Store 1024 图标。
- [ ] 启动画面可正常显示。
- [ ] iPhone 竖屏布局无明显遮挡。
- [ ] iPad 横竖屏布局可读，不出现关键操作不可点。

## 权限说明

- [ ] 相机权限说明完整。
- [ ] 相册读取权限说明完整。
- [ ] 相册写入权限说明完整。
- [ ] 通知权限说明完整。
- [ ] 麦克风权限说明完整。
- [ ] 语音识别权限说明完整。
- [ ] 日历权限说明完整。
- [ ] 联系人权限说明完整，用于系统日历界面可能触发的联想能力。
- [ ] 权限弹窗文案与真实功能一致，不夸大、不误导。

## 真实功能检查

- [ ] 相机：真实拍摄通知/海报并进入 OCR + 解析链路。
- [ ] 相册：真实选择图片并进入 OCR + 解析链路。
- [ ] 文本输入：真实调用 vivo chat completions。
- [ ] 系统分享文本：从外部 App 分享文本进入《织时》。
- [ ] 系统分享图片：从相册或其他 App 分享图片进入《织时》。
- [ ] 待确认卡：展示标题、时间、地点、说明、置信度。
- [ ] 确认：保存到本地时间线。
- [ ] 日历：确认后调起系统日历并可添加事项。
- [ ] 通知：本地提醒可申请权限并在真实时间触发。
- [ ] PDF 导出：真实生成 PDF 文件，中文显示正常。
- [ ] PDF 打开/分享：系统文件打开器或分享面板可处理导出的 PDF。
- [ ] 地图：有地点时可跳转地图。
- [ ] 语音：真实语音识别，不用假文本代替。
- [ ] TTS：真实播报状态或错误提示。

## 隐私与合规

- [ ] 隐私说明覆盖：相机、相册、语音、通知、日历、网络请求、AI 解析。
- [ ] vivo API key 不写入仓库源码。
- [ ] App Store Connect / Codemagic API Key 不写入仓库。
- [ ] 不上传用户图片、文本之外的无关隐私数据。
- [ ] 接口失败时明确提示真实失败原因，不伪装成功。

## 禁止项

- [ ] 不存在 mock/demo 模式入口。
- [ ] 不存在假数据默认填充真实结果。
- [ ] 不存在 placeholder 页面冒充功能完成。
- [ ] 不存在空壳按钮。
- [ ] 不存在“兜底测试”替代真实功能验证。
- [ ] 不存在为了过审查而隐藏失败的逻辑。
- [ ] 不存在未经用户确认直接写入日历的高风险动作。

## 启迪赛道真实移动应用要求

- [ ] App 可安装到真实 iPhone/iPad。
- [ ] 核心流程可在移动端端到端完成。
- [ ] AI 能力是真实接口调用。
- [ ] 系统能力是真实调用 iOS 能力。
- [ ] 离线/拒权/接口失败均有真实状态反馈。
- [ ] 交付物不是演示壳、网页壳或静态样机。

## TestFlight 前最后检查

- [ ] `ios-build-check` workflow 通过。
- [ ] `ios-testflight-release` workflow 已配置签名后通过。
- [ ] TestFlight build 已出现在 App Store Connect。
- [ ] iPhone 已安装 TestFlight 版本。
- [ ] iPad 已安装 TestFlight 版本。
- [ ] iPhone/iPad 真机验证结果已记录到 `进度说明.md`。
