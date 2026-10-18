# Windows 11 构建、签名与安装设计

当前仅提供骨架和流程，尚未在云端编译或安装。先读 [可行性结论](../FEASIBILITY.md)，安装成功不代表 MusicKit 服务可用。

## 1. 分工

```text
Windows 编辑源码
    → 公开 GitHub 仓库 / 手动 Actions
    → 标准 macOS runner：XcodeGen + Xcode 编译 arm64 设备 App
    → 打包 unsigned/MusicRemote-unsigned.ipa（不能直接安装运行）
    → Windows 下载并解压构建产物
    → 两台设备上的 AltStore Classic，经 Windows AltServer 重签名安装
    → 检查最终 App 身份与 MusicKit 服务 → 真机验证
```

Apple 密码仅在本地官方安装流程所需界面输入，不写进仓库、日志或 Actions secrets；本方案 CI 不签名，不需要开发者证书、UDID、MusicKit 私钥或 Apple 登录。AltStore 重签名得到的是开发安装包，不是 App Store 分发签名。这里的 IPA 是 zip 格式的设备 App 容器；不是通过 App Store export 流程导出的发行版。

## 2. 云端构建

[GitHub 官方说明](https://docs.github.com/en/actions/how-tos/write-workflows/choose-where-workflows-run/choose-the-runner-for-a-job)支持公开仓库使用免费的标准 hosted runner。附带工作流仅 `workflow_dispatch`，且公开仓库检查不通过即跳过，不启用 push/定时构建，不使用 larger runner。私有仓库不作为本项目零费用默认路线。

用户决定公开源码后，才自行创建公开仓库并上传本目录。没有要求公开测试日志、个人 Apple 信息或音乐资料库。然后在 Actions 选择“手动编译项目骨架”运行。

工作流使用 `macos-15` 与 runner 默认 Xcode，打印 macOS/Xcode/SDK/XcodeGen 版本，记录实际环境；首次成功后应固定已验证的工具版本。部署目标仍为 17.4，使用较新 SDK 不代表测试过旧系统。首次构建有可能因 runner 镜像、工具升级或骨架配置失败，需要根据日志修正，不能提前称已验证。不要用 iOS Simulator 构建结果安装到 iPad。

核心命令（在 macOS，而不是 Windows PowerShell 执行）：

```sh
xcodegen generate --spec project.yml
xcodebuild -project MusicRemote.xcodeproj -scheme MusicRemote \
  -configuration Release -sdk iphoneos -destination 'generic/platform=iOS' \
  -derivedDataPath build/DerivedData \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO ARCHS=arm64 build
mkdir -p build/unsigned/Payload
ditto build/DerivedData/Build/Products/Release-iphoneos/MusicRemote.app \
  build/unsigned/Payload/MusicRemote.app
cd build/unsigned
/usr/bin/zip -qr MusicRemote-unsigned.ipa Payload
```

构建目录仅用于本次产物，没有自动签名和 `-allowProvisioningUpdates`。不通过付费云 Mac、Xcode Cloud 或购买会员解决错误。工作流没有被本次任务触发，仓库也未创建。以后运行前以 GitHub 当前免费规则为准；若要求付费则停止。

## 3. Windows 本地 AltStore Classic

依据 [AltStore 官方 Windows 步骤](https://faq.altstore.io/altstore-classic/how-to-install-altstore-windows)：

1. 按官方说明安装兼容的 Apple 直装版 iTunes、iCloud 及 Windows AltServer；不要默认 Microsoft Store 版可替代。已有版本需按官方排障指引确认，避免盲目覆盖。
2. 用 USB 分别连接解锁后的 iPhone、iPad，信任电脑；按指南配置 AltServer 和 Wi-Fi 同步，分别安装 AltStore Classic。
3. 在设备中信任对应开发者；iOS / iPadOS 16 及以后按系统提示开启“设置 → 隐私与安全性 → 开发者模式”，重启并确认。
4. 将 Actions artifact 下载并解压，取出 `MusicRemote-unsigned.ipa`，通过设备可访问的个人文件传输方式放入“文件”App。
5. 保持 AltServer 可达，在每台设备的 AltStore“我的 App”里使用 `+` 选择 IPA，由 AltStore 请求免费配置并签名安装。不能通过普通文件点击直接安装未签名 IPA。
6. 首次先验证 USB 路线。AltServer 可达性、Wi-Fi 刷新和应用热点通信是三件事；不要以为 iPhone 热点上的两台移动设备互通就代表 Windows AltServer 自动可达。必要时各自 USB 连接 Windows 刷新。

本任务不下载或安装这些软件，不要求把 Apple 密码发给 Codex。使用 AltStore Classic，不将 AltStore PAL、付费赞助能力或第三方签名网站作为必要条件。

## 4. 免费签名维护与身份检查

[AltStore 说明](https://faq.altstore.io/altstore-classic/your-altstore)指出免费安装 App 有 7 天期限和最多 3 个活跃侧载 App 的限制；AltStore 自身占一个名额。不要承诺长期免维护；到期前连接 AltServer 手动刷新，先验证两台设备的续签流程。[Apple Personal Team 说明](https://developer.apple.com/help/account/basics/about-your-developer-account)另列 App ID 和设备配额限制，失败时记录实际错误，不反复创建新身份消耗额度。

AltStore 可能调整最终 Bundle ID 和签名身份。后续验证程序必须显示实际 Bundle ID，并保存签名工具与版本、服务配置所用身份、重签名结果和错误（不保存凭据）。在 macOS 可检查构建包：

```sh
/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' \
  build/DerivedData/Build/Products/Release-iphoneos/MusicRemote.app/Info.plist
```

这个命令只证明重签名前的 Bundle ID。要核对最终安装身份，需要在真实运行的 App 中读取 `Bundle.main.bundleIdentifier`，并结合可取得的最终签名包/配置资料分析；当前说明页面没有实现诊断采集。

若 MusicKit 服务未启用或重签名身份无法关联，**不能**靠增添伪造 entitlement、复用他人私钥、删除签名限制后重新安装解决。不购买开发者会员，按门槛停止。

## 5. 本流程的验证边界

编译通过仅证明当前 SDK 接受源码；签名安装通过仅证明系统允许启动该包；授权弹窗通过仅证明用户许可。目录查询、完整订阅播放、热点双向通信、锁屏遥控和续签后仍可使用，都必须分别有真机证据。
