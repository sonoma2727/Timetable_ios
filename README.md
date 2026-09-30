# Timetable iOS 端

SwiftUI 原生实现，功能与 Android 端一致：教务登录、今日页、周课表网格、课程详情、开学日期设置、同课同色配色、Keychain 凭据加密、免责声明与项目 README 一致。

## 获取 IPA（Releases）

Release 中的 `Timetable.ipa` **未包含签名**，安装前需用以下任一方式重签（均用你自己的 Apple ID，免费证书 7 天有效）：

- 爱思助手：工具箱 → IPA 签名 → 选择 IPA → 用 Apple ID 签名 → 安装
- AltStore / Sideloadly：电脑端签名安装
- 有付费开发者证书可用 ESign 等直接签名

要求 iOS 16+。

## 本地构建（macOS + Xcode 15+）

工程用 [XcodeGen](https://github.com/yonaskolb/XcodeGen) 描述，首次生成工程文件：

```bash
brew install xcodegen
cd ios
xcodegen generate
open Timetable.xcodeproj
```

在 Xcode 中选择模拟器/真机运行（真机需在 Signing 里选择你的开发者团队）。

## CI 构建

推送到 `main` 自动构建并上传 artifact；打 `v*` 标签自动构建 IPA 并创建 GitHub Release（见 `.github/workflows/build.yml`）。

```bash
git tag v0.1.0
git push origin v0.1.0
```

## 说明

- 兼容 iOS 16+，纯 SwiftUI，无第三方依赖。
- 教务系统为 HTTP（`jwxt.cqrk.edu.cn:18080`），已在 Info.plist 中对该域名做 ATS 例外（对应 Android 的 network_security_config）。
- 账号密码存 Keychain，课表缓存存沙盒文件，开学日期存 UserDefaults，均不上传。
- 本目录在 Windows 下只能编辑源码，无法编译验证；到 Mac 上如有报错，把错误信息发回来修。
