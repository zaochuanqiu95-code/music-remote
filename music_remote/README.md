# Music Remote

第一阶段：技术可行性分析与项目骨架。主要网络是 **iPhone（iOS 26.0）开启个人热点，iPad Pro 2018（iPadOS 17.4.1）连接该热点**。最低部署版本 iOS / iPadOS 17.4。

## 当前结论

**尚不能确认在“不购买开发者会员”的条件下满足完整需求，暂不进入第二阶段。**

- 免费 Personal Team 可以用于有限的个人设备安装，但这不证明可以使用 MusicKit 的目录搜索、自动开发者令牌和完整订阅播放服务。
- 官方接入流程要求为 App ID 启用 MusicKit App Service；目前没有核实到适用于本项目免费账户加 AltStore 的官方保证。先验证账户，再决定是否继续；不购买会员。
- 热点中的双向通信、Bonjour 发现、手动 IP 连接都需要这两台真机验证。
- `ApplicationMusicPlayer` 的后台播放有官方依据；锁屏后接收新选歌、尤其暂停很久后恢复，不能据此得到保证。

详细证据与边界见 [FEASIBILITY.md](FEASIBILITY.md)。已联网查阅官方资料，核查日期：2026-10-18；没有进行云端编译、Apple 账户验证或真机测试。

## 目标

iPhone 搜索 Apple Music 歌曲、专辑、目录歌单，并发送歌曲标识和播放命令；iPad 独立通过 `ApplicationMusicPlayer` 播放到自己的扬声器。控制包含播放、暂停、上一首、下一首。音频不经 iPhone 转发，不使用 AirPlay 或外部音响。个人资料库歌单作为另行验证的范围，不把目录歌单搜索等同于资料库搜索。

## 文件结构

```text
MusicRemote/
  App/                     SwiftUI 入口与阶段说明页面
  Configuration/           权限用途、Bonjour 服务类型、后台音频声明
  Features/                搜索、遥控、播放器模块的设计边界
  Services/                网络与 MusicKit 模块的设计边界
  Shared/                  后续命令协议的设计边界
docs/
  WINDOWS_BUILD.md          Windows → 云端未签名 IPA → AltStore 本地签名安装
  VALIDATION_PLAN.md        热点优先的真机验证步骤及第二阶段门槛
  TEST_RESULTS.md           当前证据记录（全部实机项目待测）
.github/workflows/
  build-skeleton.yml        仅手动触发、仅公开仓库的骨架编译入口
project.yml                XcodeGen 工程定义，部署目标 17.4
```

骨架只有阶段说明 UI，**未实现搜索、播放、发现、连接、遥控**。没有伪造的成功状态，也没有假定存在的 MusicKit entitlement。`Info.plist` 中的用途说明和 `audio` 声明只是后续实验配置，不代表获得服务资格或后台运行保证。

## Windows 使用方式

Windows 可以编辑代码；iOS 设备产物需要 macOS 上的 Xcode。云端流程与安装步骤见 [WINDOWS_BUILD.md](docs/WINDOWS_BUILD.md)。此仓库没有被上传，工作流没有被运行，没有生成 IPA，没有产生费用。

## 阶段安排

1. 先核实免费账户能否为最终安装身份使用 MusicKit。无法通过则记录阻塞，不转向付费操作。
2. 下一项实验优先测试热点前台双向消息：Bonjour、直接 IP，再评估 MultipeerConnectivity；普通 Wi-Fi 仅作对照。
3. 通过账户门槛后，以独立小型验证程序测试 Apple Music 授权、目录搜索、完整歌曲播放和锁屏连续播放。
4. 验证锁屏播放中选新歌、暂停后等待再恢复、连接中断后重连；按 [验证计划](docs/VALIDATION_PLAN.md)留存证据。
5. 关键门槛通过才开发 MVP。失败时明确保留限制；解锁 iPad 回到 App 是人工恢复方式，不能标成锁屏遥控已实现。

当前阶段交付已完成；第二阶段门槛尚未通过。

## 接下来：独立的热点通信实验

用户后续提供的土耳其区账户截图已显示 `Certificates, Identifiers & Profiles` 返回 `Access Unavailable`，要求加入开发者计划或相关组织团队；该账户无法按官方流程配置 MusicKit。中国区账户的开发者登录问题仍未解决。这些结果不证明 MusicKit 真机调用已经被测试。

为继续验证主要网络环境，另备 `HotspotProbe/` 和独立工作流 `build-hotspot-probe.yml`，仅测试 Bonjour 发现、手动 IPv4 与双向 ping/pong，不接入 MusicKit，也不属于完整 App 的第二阶段。**只有源码，尚未编译或真机验证。** 主 App 仍只有阶段说明页面。

编程新手请从 [一步一步开始](docs/START_HERE.md)操作。第一件事是准备免费的公开 GitHub 仓库；没有执行上传、云端构建、签名或收费操作。
