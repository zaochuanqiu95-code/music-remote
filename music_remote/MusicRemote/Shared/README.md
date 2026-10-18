# 命令协议设计（尚未实现）

候选消息：hello、ping、pong、playCatalogItem、play、pause、previous、next、getState、state、result。

所有消息包含协议版本、request ID、会话身份与有效期；选歌带项目类型、catalog ID 和 storefront。传输使用长度前缀，限制载荷为 64 KiB；TCP 读取必须处理拆包和粘包。

接收回执、执行回执和播放器状态分开。按 request ID 去重，显式拒绝版本不兼容、未配对、过期及格式错误消息；断线不重放旧的“下一首”。网络重连后重新同步真实队列和状态。

不会在设备间发送 Apple Music 令牌、Apple 密码或音频流。
