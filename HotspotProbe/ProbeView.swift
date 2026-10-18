import SwiftUI

struct ProbeView: View {
    @ObservedObject var probe: ProbeModel
    @State private var host = ""
    @State private var port = "49632"
    @State private var peerToPeer = false

    var body: some View {
        NavigationStack {
            List {
                Section("仅做前台通信实验") {
                    Text("不播放音乐。先让 iPad 连接 iPhone 的个人热点，两端保持此页面打开。")
                    Text("只交换无敏感内容的 ping/pong。此实验未加密、未配对，不用于正式遥控。")
                        .font(.footnote)
                    Text("运行编号：\(probe.runID)")
                    Text("系统：\(probe.systemVersion)")
                    Text("App 身份：\(Bundle.main.bundleIdentifier ?? "未知")")
                        .font(.caption).textSelection(.enabled)
                }
                Section("1 · 设置") {
                    Toggle("启用点对点链路（首轮关闭）", isOn: $peerToPeer)
                        .disabled(probe.isActive)
                    Text("首轮关闭，用于测试热点路径。若以后开启，成功不等于已证明流量经过热点。")
                        .font(.caption)
                    TextField("端口（两端一致）", text: $port)
                        .keyboardType(.numberPad)
                        .disabled(probe.isActive)
                }
                Section("2 · iPad 先点开始等待") {
                    Button("开始等待连接（发布 Bonjour）") {
                        probe.listen(portText: port, peerToPeer: peerToPeer)
                    }.disabled(probe.isActive)
                    ForEach(probe.localAddresses, id: \.self) { address in
                        Text(address).font(.caption).textSelection(.enabled)
                    }
                    Text("以上是 IPv4 候选，含接口名称，不能保证每个地址可达；不要固定使用某个常见热点地址。")
                        .font(.caption)
                }
                Section("3 · iPhone 搜索并连接") {
                    Button("搜索等待中的设备") { probe.browse(peerToPeer: peerToPeer) }
                        .disabled(probe.isActive)
                    ForEach(Array(probe.discovered.enumerated()), id: \.offset) { _, result in
                        Button(String(describing: result.endpoint)) {
                            probe.connect(to: result.endpoint, peerToPeer: peerToPeer)
                        }.disabled(probe.hasConnection)
                    }
                    TextField("备用：输入对端 IPv4 地址", text: $host)
                        .keyboardType(.numbersAndPunctuation)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Button("手动 IP 连接") {
                        probe.connect(host: host, portText: port, peerToPeer: peerToPeer)
                    }.disabled(probe.hasConnection || probe.isListening)
                }
                Section("4 · 两端分别发送测试") {
                    Text(probe.status)
                    Button("发送一条 ping，等待对端 pong") { probe.ping() }
                        .disabled(!probe.isConnected)
                    Text("本端发送：\(probe.sentCount) · 收到对端 ping：\(probe.receivedCount)")
                    Text("收到对应 pong：\(probe.ackCount) · 超时：\(probe.timeoutCount)")
                    Text("每次新连接重新计数；断开时未完成请求记为超时。收到 pong 才算本次往返有应用层回执。")
                        .font(.caption)
                    Button("停止全部 / 准备重新测试", role: .destructive) { probe.stop() }
                }
                Section("日志（包含设备局域网地址）") {
                    ShareLink(item: probe.logText) { Text("分享 / 保存日志文本") }
                    Text("本地保留最近 300 行，重开 App 后可在日志看到此前内容。分享前遮住地址等个人信息。")
                        .font(.caption)
                    Text(probe.logText).font(.system(.caption2, design: .monospaced))
                        .textSelection(.enabled)
                }
            }
            .navigationTitle("热点通信测试")
        }
    }
}
