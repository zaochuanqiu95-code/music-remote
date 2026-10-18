# Music Remote 技术可行性分析

核查日期：2026-10-18。目标系统：iOS / iPadOS 17.4 起；主要验收组合：iPhone（用户确认 iOS 26.0）开启个人热点，iPad Pro 2018（iPadOS 17.4.1）连接热点。iPhone 型号尚未提供。

这是跨系统版本组合，必须用该组合验证发现、双向通信与锁屏行为；不能用两端同版本的测试替代。iPhone 的较新系统不改变 iPadOS 17.4.1 对播放器端后台执行的限制，也不意味着可以在共享实现中直接使用仅适用于较新系统的 API。当前补充是设备信息更新，不是实测结果。

## 1. 决策

**完整方案目前为 NO-GO（不进入 MVP），文档和骨架可以完成。** 原因是免费账户的 MusicKit 服务资格未通过验证，个人热点连通性未实测，锁屏长期接收命令没有平台保证。这里的 NO-GO 是项目门槛未通过，不是声称所有部分在技术上都不可能。

| 要求 | 官方依据 / 推断 | 本项目状态 |
| --- | --- | --- |
| SwiftUI、MusicKit，最低 17.4 | 存在适用 API；后续只使用 17.4 可用接口 | 骨架配置完成，未用 Xcode 编译 |
| 免费账户目录搜索与完整订阅播放 | 官方要求 MusicKit 服务配置；未找到免费 Personal Team 的可承诺接入路径 | 关键阻塞，未登录用户账户核验 |
| iPhone 热点双向消息 | 可以设计 Network.framework 实验；热点不是稳定的开发者 API 契约 | 待真机测 |
| Bonjour 自动发现 | 可用标准 Bonjour API；热点是否传递发现消息不能预设 | 待真机测 |
| 手动 IP 备用 | 可绕过发现；无法绕过路由隔离、权限或系统挂起 | 待真机测 |
| iPad 自带扬声器播放 | iPad 本地播放架构符合目标，实际输出路由需检查 | 待真机测 |
| 锁屏持续播放 | ApplicationMusicPlayer 官方支持配置后台音频后继续播放 | 官方支持，17.4.1 实测待做 |
| 锁屏接收新选歌 | App 必须仍有执行机会，连接和 MusicKit 请求还须成功 | 无可靠性保证，关键实验 |
| 暂停很久后远程恢复 | 可能已挂起，普通 TCP 消息不能保证唤醒 App | 当前无保证可行的方案 |
| Windows 构建与 AltStore 安装 | 可拆成 macOS 编译及 Windows 重签名安装 | 流程已设计，未执行 |

## 2. 先核实免费账户与 MusicKit

要区分四件事：导入 MusicKit 框架、用户允许访问音乐、Apple Music 订阅资格、开发者 App 身份获准访问服务。前两者成功不代表后两者成功。

Apple 的 [自动开发者令牌文档](https://developer.apple.com/documentation/musickit/using-automatic-token-generation-for-apple-music-api)要求在开发者网站为明确的 App ID 启用 MusicKit App Service，并使运行 App 的 Bundle ID 匹配。[账户 MusicKit 配置说明](https://developer.apple.com/help/account/services/musickit)给出相同入口。这是服务配置，不应随意创建一个名为 `com.apple.developer.musickit` 的 entitlement 来代替。

[开发者令牌文档](https://developer.apple.com/documentation/applemusicapi/generating-developer-tokens)把 Apple Music API 的开发者认证与 Apple Developer Program 成员身份关联。手工生成 JWT 需要相应标识和私钥，不能用它绕过账户门槛。自动令牌也不是免费权限的证明。

[Personal Team 官方说明](https://developer.apple.com/help/account/basics/about-your-developer-account)只确认个人设备测试与周期性重新预置等能力。[支持能力表](https://developer.apple.com/help/account/reference/supported-capabilities-ios)与 [capability 概览](https://developer.apple.com/help/account/capabilities/capabilities-overview)说明能力受会员类型影响，但不能用该表未列出 MusicKit 推断服务必然开放或必然禁止。

**当前可确认的结论：不能把免费账户获取所需 MusicKit 服务权限作为已成立条件；官方资料没有为本项目证明免费接入。** 本次没有账户访问权限，也没有真正用该账户签名运行，不能声称已确认用户账户一定能用，或已观察到拒绝。项目按阻塞处理。

后续用户提供的新证据：土耳其区账户已进入开发者网站，但 `Certificates, Identifiers & Profiles` 弹出 `Access Unavailable`，提示该资源只供开发者计划成员或相关组织团队成员访问。现可确认这个账户当前无法通过此入口配置服务；仍没有签名运行 MusicKit 的结果。另一个中国区账户在开发者登录环节失败，原因未确定。无须通过改区或付款进行验证。

验证必须使用最终 AltStore 重签名后的身份：

1. 用户在自己的浏览器登录 Apple Developer，检查能否访问 Identifiers，为明确 Bundle ID 启用 MusicKit App Service。不购买会员、不提交付款。
2. 若免费账户没有该入口，记录页面结果；可向 Apple Developer Support 询问免费 Personal Team 的 MusicKit App Service 资格。项目暂停 MusicKit 实现，不用付费账户代为“验证免费”。
3. 若入口可用，仍须在 AltStore 最终安装后的 App 中依次验证 `MusicAuthorization`、`MusicSubscription.current.canPlayCatalogContent`、歌曲/专辑/歌单目录查询以及完整歌曲播放。授权允许或 30 秒试听不算通过。
4. 记录重签名前后 Bundle ID、Team ID、配置描述文件和服务关联的变化；不要只测云端原始 Bundle ID。AltStore 不能替账户增加 Apple 服务资格。
5. 两台设备分别授权，iPad 需要有效 Apple Music 订阅；iPhone 的搜索资格也单独核实。已有订阅和热点蜂窝流量是前提，不承诺 Apple Music 服务本身免费，也不触发试用或订阅。

## 3. 热点优先的网络方案

主要拓扑是热点宿主 iPhone 与其客户端 iPad，不是同一路由器下的两个普通客户端。Apple DTS 在 [Personal Hotspot 讨论](https://developer.apple.com/forums/thread/702058)指出热点是用户功能，不是开发者 API；这不是“必然不能通信”的证明，但足以说明不能给出跨机型、跨系统的保证。

### 首选实验：Network.framework

使用 iOS 17.4 可用的 `NWListener`、`NWBrowser`、`NWConnection`。Bonjour 负责发现，TCP 负责可靠有序字节传输，两者不是替代关系。第一轮由 iPad 发布 `_musicremote._tcp`，iPhone 浏览并连接；同一条 TCP 连接收发消息即可证明双向通信，不要求双方各开服务器。

交换带序号的 ping/pong、状态请求和明确应用层回执；TCP 发送完成不等于命令已执行。记录浏览器/监听器/连接状态、错误域和错误码、路径接口、远端端点与往返耗时。不要把热点接口硬编码为 `en0` 或强制 `.wifi`，也不要把某个常见网关地址写成系统契约。

### 自动发现失败后的手动连接

保持 iPad 监听，展示当前候选局域网地址及实际端口，用户在 iPhone 输入；IPv6 需保留作用域，端口独立输入。地址获取可在后续实验使用公开的 `getifaddrs`，排除 loopback、展示多个候选；不能声称总能自动判定热点地址。

如果 iPhone → iPad 不通，独立测试角色反转：iPhone 监听，iPad 主动连接热点侧 iPhone 地址。连接建立后仍可双向发送遥控命令，播放器角色不变。宿主网关地址可以在设备网络设置可见时作为候选，不固定为 `172.20.10.1`。重新开热点可能改变地址。

手动 IP 只绕过 mDNS。若两种方向均不通，需记录路由/权限/接口证据，不能称已解决。普通 Wi-Fi 只帮助区分代码问题与热点问题，不能代替主要场景验收。

### MultipeerConnectivity：仅作前台对照候选

[官方文档](https://developer.apple.com/documentation/multipeerconnectivity)说明它使用基础设施 Wi-Fi、点对点 Wi-Fi 和蓝牙等传输，但进入后台会停止发现并断开会话。因此可以测试前台发现、配对和消息，不适合承担本需求的锁屏主通道。框架可能选择不同链路；发现成功不能单凭此证明消息一定经由热点转发。

Network.framework 的 `includePeerToPeer` 可作为另一组实验（先关闭验证热点，再开启比较），不能宣称它与热点同时工作必然成功。iPadOS 17.4 不采用要求更新系统/硬件的 Wi-Fi Aware 等方案。

### 权限与命令保护

依照 [TN3179](https://developer.apple.com/documentation/technotes/tn3179-understanding-local-network-privacy)，两端前台先允许本地网络权限，声明 `NSLocalNetworkUsageDescription` 和明确的 `NSBonjourServices`。普通声明类型的 Bonjour 浏览/发布不等同于直接收发 UDP 组播；不要默认申请 multicast entitlement。自定义广播扫描会引入额外权限，第一版不采用。手动 IP 仍受本地网络权限约束。

后续 MVP 需显式配对、验证端点身份和加密传输（例如验证配对身份的 TLS），限制消息长度、命令种类和连接数；热点密码不能代替 App 级配对。协议带版本、request ID、有效期，按 request ID 去重，防止“下一首”重试执行两次。超时显示未确认，不自动补播已过期的选歌。第一阶段未实现这些机制。

## 4. 播放与锁屏必须分开评估

搜索计划使用 `MusicCatalogSearchRequest` 的 Song、Album、Playlist；iPhone 只传类型、catalog ID 和 storefront 上下文，iPad 以自己的授权重新查询并构建队列。跨 storefront 无内容、订阅失效、网络断流要返回失败；不转发 DRM 音频或用户令牌。播放、暂停、上一首、下一首统一由 iPad 的 `ApplicationMusicPlayer.shared` 执行。显式选用新曲目与队列跳转分开处理。

[ApplicationMusicPlayer 文档](https://developer.apple.com/documentation/musickit/applicationmusicplayer)明确后台 audio 配置可让当前音乐在 App 进入后台后继续播放。这支持采用该播放器；仍需在目标 17.4.1 上测试跨曲、长时间播放、来电/其他音频中断以及内置扬声器输出。不能把 2026 示例中出现的所有 API 都当作 17.4 API。

[Apple DTS 对后台 TCP 的解释](https://developer.apple.com/forums/thread/717396)：App 仍运行时网络可工作，被挂起后则不能继续依赖它处理请求。[后台执行限制](https://developer.apple.com/forums/thread/685525)说明 iOS 没有通用的无限后台执行机制。**后台播放有声音，不足以证明本 App 的网络处理代码始终获得执行。** 是否能在本设备播放期间稳定处理连接回调与 MusicKit 选歌必须实测。

| 状态 | 可承诺范围 | 实验重点 |
| --- | --- | --- |
| 双端前台 | 可开发并测试连接、查询、播放 | 热点路由、权限和身份 |
| iPad 锁屏且音乐连续播放 | 配置后台音频有官方依据 | 新选歌是否到达、是否真的开始播放 |
| iPad 锁屏，暂停或队列结束很久 | 没有通用 TCP 唤醒保证 | 暂停后恢复是关键失败路径 |
| 连接断开、需重新发现/连接 | 需要 App 有执行机会 | 播放期间重连与空闲重连分别测 |
| 用户强制退出、重启、进程被终止 | 不承诺自动恢复 | 用户重新打开 App |
| iPhone 遥控 App 退到后台 | 热点仍开不代表遥控 App 仍运行 | 回前台恢复连接和状态 |

TCP keepalive、心跳或 `beginBackgroundTask` 不能赋予无限后台时间；BGAppRefresh/BGProcessing 不提供即时遥控调度；后台 URLSession 面向传输任务，不是常驻命令服务器。远端 TCP 包也不是系统唤醒事件。添加静音音频循环、假 VoIP、位置定位不能算有效解决方案。

APNs/中继会引入额外基础设施与资格，且静默推送仍不能保证及时唤醒；更换 WebSocket、HTTP 轮询或外部服务器也不能消除挂起限制。蓝牙/CoreBluetooth 是不同架构，若以后研究也要单独核实后台事件与执行预算，当前不是已验证备用方案。

当前可靠的人工恢复方法是解锁 iPad，打开 Music Remote，再重连同步状态。若必须要求“暂停数十分钟后、不碰 iPad、每次均能选新歌”，在当前约束下没有可以承诺的实现路径。即使购买会员也不会自动移除后台限制；本项目不执行购买。

## 5. Windows 与成本

设计使用公开 GitHub 仓库的标准 macOS Actions runner 编译未签名设备 App，将其打包为待重签名 IPA。Windows 上 AltServer / AltStore Classic 完成个人账户签名和安装；不用把 Apple 密码或证书上传 CI。未签名 IPA 本身不能直接启动，且重签名不能解决 MusicKit 资格。

[GitHub 官方文档](https://docs.github.com/en/actions/how-tos/write-workflows/choose-where-workflows-run/choose-the-runner-for-a-job)说明标准公开仓库 runner 可免费使用；私有仓库超出额度可能收费。因此附带工作流只允许公开仓库并只手动触发，未创建仓库、未运行作业。公开源码需要用户自行决定，敏感数据和凭据不得提交。

[AltStore Windows 安装说明](https://faq.altstore.io/altstore-classic/how-to-install-altstore-windows)与 [Classic 使用说明](https://faq.altstore.io/altstore-classic/your-altstore)支持这条本地安装设计。免费签名存在 7 天有效期和活跃 App 数量限制，需定期刷新，AltStore 本身也占用名额。USB 刷新应优先测试，不依赖主要热点环境能自动发现 Windows AltServer。具体步骤见 [Windows 构建文档](docs/WINDOWS_BUILD.md)。

## 6. 第二阶段门槛

账户资格先核实；随后第一个网络实验必须在 iPhone 热点中完成。全部实测判据见 [验证计划](docs/VALIDATION_PLAN.md)，当前结果见 [记录表](docs/TEST_RESULTS.md)。

只有免费账户加最终重签名身份能搜索和完整播放、热点至少一种连接方式稳定双向收发、iPad 锁屏持续播放且播放期间新选歌测试通过，才可以考虑对应范围的 MVP。暂停后长期恢复若失败，不能悄悄删掉该需求或标成完成，需明确报告并由用户决定是否接受解锁恢复的范围变化。没有实际设备结果前不进入 MVP。
