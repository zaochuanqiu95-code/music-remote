# 服务模块边界（尚未实现）

- Music：用户授权、订阅能力、目录请求、ApplicationMusicPlayer 适配。
- Transport：Network.framework 的 Bonjour 与直接端点连接、身份验证、消息收发和重连。
- Diagnostics：生命周期、连接变化、请求回执与错误记录，支持离线导出。
- Multipeer 实验：独立前台对照，不作为锁屏主通道。

第一阶段只保留边界，不添加假实现或以成功为默认值的接口。
