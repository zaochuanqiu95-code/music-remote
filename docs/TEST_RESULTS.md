# 验证记录

记录日期：2026-10-18。

用户确认的设备信息：iPhone 系统为 iOS 26.0，型号尚未提供；iPad Pro 2018 为 iPadOS 17.4.1。该信息不构成任何通信或播放测试通过的证据。

后续账户证据：用户提供截图，土耳其区个人账户的 `Certificates, Identifiers & Profiles` 返回 `Access Unavailable`，要求开发者计划资格或相关组织团队资格。中国区账户能登录普通 Apple 账户网站，但开发者网页登录被拒绝，Developer App 提示未知错误。原因尚未确诊。

## 本次实际完成

- 联网查阅 Apple、GitHub、AltStore 和 XcodeGen 官方资料，链接保存在对应文档。
- 创建文档、SwiftUI 说明页面、XcodeGen 工程定义及仅手动触发的骨架构建入口。
- Windows PowerShell XML 解析已通过：`MusicRemote/Configuration/Info.plist` 格式有效。静态检查不等于 Swift 编译。
- 本机未检测到 Python、Swift 或 xcodebuild 命令；没有执行 Swift 编译或 XcodeGen 生成。
- 本地 Markdown 链接目标检查、部署目标与 plist 路径文本检查、工作流手动触发和公开仓库条件检查均通过。未运行 YAML 解析器或工作流执行验证。

## 实机 / 云端状态

| 项目 | 结果 | 原因 / 证据 |
| --- | --- | --- |
| 免费账户启用 MusicKit | 受阻 / 进入 MVP 的阻塞项 | 用户截图确认土耳其区账户无权访问服务配置入口；没有 MusicKit 运行结果 |
| 最终 AltStore 身份 MusicKit 可用 | 待测 | 没有签名包与真机 |
| 云端 macOS 编译 | 未执行 | 本次未上传仓库、未触发 Actions |
| AltStore 安装与 7 天刷新 | 待测 | 本次未操作 Windows 安装工具或设备 |
| 热点 Bonjour 发现 | 待测 | 无两台设备的运行证据 |
| 热点双向 TCP、手动 IP、角色反转 | 待测 | 无运行证据 |
| MultipeerConnectivity 前台发现 | 待测 | 无运行证据；官方后台断连限制已确认 |
| iPad 内置扬声器完整歌曲播放 | 待测 | 无运行证据 |
| iPad 锁屏 60 分钟与跨曲 | 待测 | 无运行证据 |
| 锁屏播放中接收新选歌 | 待测 / 关键门槛 | 无运行证据 |
| 暂停 30 分钟后恢复 / 新选歌 | 待测 / 无可靠唤醒保证 | 无运行证据 |
| 普通 Wi-Fi 对照 | 待测 | 无运行证据 |

## 后续每次实验填写

新增独立 `HotspotProbe` 源码：Bonjour 浏览/发布、手动 IPv4、双向 ping/pong、超时与本地日志；没有 MusicKit、MPC 或后台执行实现。新增独立手动编译工作流，尚未触发，未取得 IPA 或真机结果。操作见 [新手步骤](START_HERE.md)。

该实验工具的 Windows 静态检查：本地 Markdown 链接、plist XML、无 MusicKit/后台音频声明、工作流手动触发与公开仓库条件均通过。对收发代码进行了人工检查；没有 Swift 编译器，未执行网络代码或协议运行测试。首次云端构建和真机验证仍是必需步骤。

```text
运行 ID / 时间：
源码版本与构建编号：
Xcode / SDK / 签名工具版本：
iPhone 型号 / 系统：
iPad 型号 / 系统：
实际安装 Bundle ID / Team（分享前脱敏）：
Apple Music 地区与订阅能力（不记录账号）：
网络：iPhone 个人热点 / 对照 Wi-Fi；连接发起方向：
通信模式 / includePeerToPeer 设置：
双方 App 生命周期 / 是否连接调试器：
锁屏起点 / 最近播放或暂停时刻：
命令 ID / 发送 / 接收 / 执行 / 可听见变化时间：
回执或错误域与错误码：
是否在解锁后才执行：
失败数 / 总次数 / 延迟：
脱敏日志路径：
结论与适用条件：
```
