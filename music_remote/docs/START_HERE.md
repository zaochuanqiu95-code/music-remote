# 从这里开始：只测试热点通信

你暂时不用写代码。当前有一个独立实验工具的源码，显示名称为“热点通信测试”，工程名称为 `HotspotProbe`。它与 Music Remote 主 App 分开；不请求 Apple Music 权限、不播放音乐、不保持后台运行，也不解决 MusicKit 服务资格。

**当前没有编译成功的 IPA，尚未在真机运行。** 以下按顺序操作；任何步骤遇到报错，把报错发给 Codex，停在该步骤即可，不必猜测下一步。

## 今天先做：准备 GitHub

1. 在 Windows 浏览器打开 [GitHub](https://github.com/)。已有账户就登录，没有则使用免费注册；不选择付费计划。
2. 点击右上角 `+` → `New repository`（新建仓库）。
3. Repository name 填 `music-remote`，可见性选择 **Public（公开）**。本流程依赖公开仓库标准 Actions runner 的免费使用政策；如果不希望公开这些源码，就先停下，不改用可能收费的私有构建。
4. 不添加 README、.gitignore 或许可证模板（本地已经有需要的文件），点击 `Create repository`。
5. 创建后先把仓库链接发给 Codex，或发页面截图，下一步再一起上传。截图不要包含账户安全信息。

公开仓库意味着别人可以看到源码。这里只上传本项目目录，不上传 Apple 账户资料、证书、微信文件、个人截图或导出的设备日志。创建仓库不代表 Codex 已经获得上传权限。

## 之后：上传本地文件（第一步完成后再做）

打开 Windows 文件资源管理器，在地址栏输入 `D:\music_remote`。新建的空仓库页面中点击 `uploading an existing file`；已有内容的仓库使用 `Add file` → `Upload files`。

将本项目的文件和文件夹拖入上传区域，保留结构，尤其是 `.github/workflows`、`HotspotProbe`、`MusicRemote`、`docs` 与 `project.yml`。不要只上传一个 zip，GitHub 不会自动解压源码。确认文件预览路径正确后，点击 `Commit changes` 保存。若 `.github` 没有上传成功，先停下，把页面情况发给 Codex。

## 之后：手动云端编译

1. 仓库顶部点击 `Actions`。如果提示启用工作流，阅读后确认。
2. 左侧选择 **手动编译热点通信测试**；不要误选只显示阶段说明的“手动编译项目骨架”。
3. 点击 `Run workflow`，使用默认分支运行。
4. 等待绿色对勾。如果红叉，把失败步骤的报错发来；没有绿色对勾就不能说编译完成。
5. 打开成功的运行记录，在底部 Artifacts 下载 `HotspotProbe-unsigned`，解压得到 `HotspotProbe-unsigned.ipa`。产物一天后过期，需要时可重新编译。

云端不需要 Apple 密码或付费开发者会员。构建包尚未签名，不能直接点击安装。费用依据见 [GitHub 官方文档](https://docs.github.com/en/actions/how-tos/write-workflows/choose-where-workflows-run/choose-the-runner-for-a-job)：公开仓库标准 runner 可免费使用；工作流没有付费 runner 或私有仓库执行路径。首次构建仍可能需要依据 Xcode 日志修复代码。

## 之后：安装到两台设备

按 [Windows 安装流程](WINDOWS_BUILD.md)准备 AltServer 和两台设备上的 AltStore Classic，然后在 AltStore 选择 `HotspotProbe-unsigned.ipa` 重签名安装。**本次装的是 HotspotProbe，不是 MusicRemote。** 普通个人签名能否成功也要实际验证；开发者网站登录成功不代表安装已成功。

建议使用能正常登录的个人 Apple 账户进行本地签名；不要求退出 iPhone/iPad 上的 iCloud 或切换 Apple Music 订阅账户。不提供账户密码给 Codex，不开通会员。若 AltServer 拒绝该账户，记录实际错误后再排查。两台设备安装的 App 都是同一份产物；免费侧载需要定期刷新，并占用侧载 App 名额。

## 安装成功后：第一次实验

1. iPhone 开启个人热点；iPad 连接这个热点。两台设备都打开“热点通信测试”，保持前台。
2. 两端“启用点对点链路”保持关闭，端口都保持 `49632`。
3. **iPad** 点击“开始等待连接”，出现本地网络权限提示时允许。
4. **iPhone** 点击“搜索等待中的设备”，允许本地网络权限；出现 `MR-Probe-...` 后点它连接。
5. 如果显示连接已就绪，先在 iPhone 点“发送一条 ping”，再在 iPad 点同一个按钮。两边都应看到收到对端 ping，并收到对应 pong。分别截图或保存日志。
6. 先各发送 5 次做通路检查；完整 100 次/多轮验收之后再做。初步 5 次成功不代表完整验收通过。

如果搜索 10 秒左右没有结果：

- iPhone 点“停止全部”；iPad 保持等待。
- 在 iPad 页面上找到 IPv4 候选地址（如接口名后面的四段数字），仅把地址输入 iPhone 的“备用”输入框，点“手动 IP 连接”。不固定使用 `172.20.10.1`，也不输入 `接口名：` 前缀。多个候选需要逐个记录测试。
- 仍不通时，两端点“停止全部”，反过来让 iPhone 等待、iPad 搜索或手动连接，再试双向 ping。这里只反转网络角色，不改变未来 iPad 播放音乐的角色。
- 失败时保存双方日志，记录是没有发现、连接超时、本地网络被拒绝，还是有连接但无 pong；不要把上网正常等同于 App 互通。

## 当前工具的边界

- 只测试 Network.framework + Bonjour + TCP，以及手动 IPv4。暂未实现 MultipeerConnectivity、手动 IPv6、自动批量测试、配对、TLS 或播放命令。
- TCP 使用长度前缀处理拆包/粘包，限制单条载荷 1024 字节；只接受版本 1 的 ping/pong，不执行任何设备控制。请只在自己的两台设备测试；不要用它传输凭据或个人内容。
- 连接 10 秒未就绪会停止；ping 超过 3 秒没有匹配回执计为超时。所有超时是实验判据，不能仅凭超时断定系统路由不支持。
- 对端结束连接后，计数保留，连接状态由按钮是否启用和日志共同判断。需要开始下一组时停止全部重新操作；没有自动重连。
- 记录最多 300 行日志到本机，并可分享文本。大量测试应按组保存，以免旧日志被覆盖。
- iPad 锁屏后可能挂起。本工具没有 audio 后台模式，不能用它的锁屏结果推断 ApplicationMusicPlayer 播放期间的网络行为。
- 即使本实验全部通过，MusicKit 账户门槛仍然存在，不进入完整音乐 App 的第二阶段。

API 参考：[Network.framework 官方文档](https://developer.apple.com/documentation/network)、[接收字节 API](https://developer.apple.com/documentation/network/nwconnection/receive%28minimumincompletelength%3Amaximumlength%3Acompletion%3A%29)、[点对点链路开关](https://developer.apple.com/documentation/network/nwparameters/includepeertopeer)。
