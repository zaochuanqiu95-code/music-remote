import Foundation
import Network
import UIKit
import Combine
import Darwin

// 所有状态与缓冲区仅在主队列访问；本工具只处理 ping/pong，没有遥控执行入口。
final class ProbeModel: ObservableObject {
    @Published private(set) var status = "尚未开始"
    @Published private(set) var discovered: [NWBrowser.Result] = []
    @Published private(set) var isListening = false
    @Published private(set) var isBrowsing = false
    @Published private(set) var hasConnection = false
    @Published private(set) var isConnected = false
    @Published private(set) var localAddresses: [String] = []
    @Published private(set) var sentCount = 0
    @Published private(set) var receivedCount = 0
    @Published private(set) var ackCount = 0
    @Published private(set) var timeoutCount = 0
    @Published private(set) var logText = ""

    let runID = String(UUID().uuidString.prefix(8))
    let systemVersion = UIDevice.current.systemVersion
    var isActive: Bool { isListening || isBrowsing || hasConnection }
    private let serviceType = "_musicremote._tcp"
    private var listener: NWListener?
    private var browser: NWBrowser?
    private var connection: NWConnection?
    private var buffer = Data()
    private var isReceiving = false
    private var pending: [UUID: TimeInterval] = [:]
    private var lines: [String] = []
    private let logURL: URL
    private let formatter = ISO8601DateFormatter()

    private struct Message: Codable {
        let version: Int
        let kind: String
        let id: UUID
    }

    init() {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        logURL = directory.appendingPathComponent("hotspot-probe.log")
        if let old = try? String(contentsOf: logURL, encoding: .utf8) {
            lines = Array(old.split(separator: "\n").suffix(250)).map(String.init)
        }
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        record("新运行 \(runID)，\(UIDevice.current.model)，系统 \(systemVersion)，身份 \(Bundle.main.bundleIdentifier ?? "未知")")
        refreshAddresses()
    }

    func record(_ text: String) {
        lines.append("\(formatter.string(from: Date())) [\(runID)] \(text)")
        lines = Array(lines.suffix(300))
        logText = lines.joined(separator: "\n")
        do { try logText.write(to: logURL, atomically: true, encoding: .utf8) }
        catch {
            lines.append("日志文件保存失败：\(error.localizedDescription)，请从屏幕分享日志。")
            lines = Array(lines.suffix(300))
            logText = lines.joined(separator: "\n")
        }
    }

    private func parameters(peerToPeer: Bool) -> NWParameters {
        let parameters = NWParameters.tcp
        parameters.includePeerToPeer = peerToPeer
        return parameters
    }

    private func port(_ text: String) -> NWEndpoint.Port? {
        guard let value = UInt16(text), value > 0, let port = NWEndpoint.Port(rawValue: value) else {
            status = "端口必须为 1～65535"
            record(status)
            return nil
        }
        return port
    }

    func listen(portText: String, peerToPeer: Bool) {
        guard !isActive, let port = port(portText) else { return }
        refreshAddresses()
        do {
            let server = try NWListener(using: parameters(peerToPeer: peerToPeer), on: port)
            listener = server
            isListening = true
            server.service = NWListener.Service(name: "MR-Probe-\(runID)", type: serviceType)
            server.stateUpdateHandler = { [weak self, weak server] state in
                guard let self, let server, self.listener === server else { return }
                self.status = "监听状态：\(state)"
                self.record(self.status)
                switch state {
                case .failed, .cancelled:
                    self.listener = nil
                    self.isListening = false
                default: break
                }
            }
            server.newConnectionHandler = { [weak self, weak server] incoming in
                guard let self, let server, self.listener === server,
                      self.connection == nil else { incoming.cancel(); return }
                self.attach(incoming)
            }
            record("开始监听，端口 \(port)，includePeerToPeer=\(peerToPeer)")
            server.start(queue: .main)
        } catch {
            status = "创建监听器失败：\(error)"
            record(status)
        }
    }

    func browse(peerToPeer: Bool) {
        guard !isActive else { return }
        let scanner = NWBrowser(for: .bonjour(type: serviceType, domain: nil), using: parameters(peerToPeer: peerToPeer))
        browser = scanner
        isBrowsing = true
        discovered = []
        scanner.stateUpdateHandler = { [weak self, weak scanner] state in
            guard let self, let scanner, self.browser === scanner else { return }
            self.status = "发现状态：\(state)"
            self.record(self.status)
            switch state {
            case .failed, .cancelled:
                self.browser = nil
                self.isBrowsing = false
            default: break
            }
        }
        scanner.browseResultsChangedHandler = { [weak self, weak scanner] results, _ in
            guard let self, let scanner, self.browser === scanner else { return }
            self.discovered = results.sorted { String(describing: $0.endpoint) < String(describing: $1.endpoint) }
            self.record("Bonjour 候选数：\(results.count)")
        }
        record("开始 Bonjour 浏览，includePeerToPeer=\(peerToPeer)")
        scanner.start(queue: .main)
    }

    func connect(host: String, portText: String, peerToPeer: Bool) {
        let cleaned = host.trimmingCharacters(in: .whitespacesAndNewlines)
        guard IPv4Address(cleaned) != nil else {
            status = "请输入对端显示的 IPv4 地址，不带接口名或端口"
            record(status)
            return
        }
        guard let port = port(portText) else { return }
        connect(to: .hostPort(host: NWEndpoint.Host(cleaned), port: port), peerToPeer: peerToPeer)
    }

    func connect(to endpoint: NWEndpoint, peerToPeer: Bool) {
        guard connection == nil, listener == nil else { return }
        browser?.cancel()
        browser = nil
        isBrowsing = false
        record("尝试连接 \(endpoint)，includePeerToPeer=\(peerToPeer)")
        attach(NWConnection(to: endpoint, using: parameters(peerToPeer: peerToPeer)))
    }

    private func attach(_ link: NWConnection) {
        connection = link
        hasConnection = true
        isConnected = false
        buffer = Data()
        pending = [:]
        sentCount = 0
        receivedCount = 0
        ackCount = 0
        timeoutCount = 0
        link.stateUpdateHandler = { [weak self, weak link] state in
            guard let self, let link, self.connection === link else { return }
            self.status = "连接状态：\(state)"
            self.record(self.status)
            self.isConnected = false
            switch state {
            case .ready:
                self.isConnected = true
                self.record("连接已就绪，端点 \(link.endpoint)，路径 \(String(describing: link.currentPath))")
                self.receive(link)
            case .failed, .cancelled:
                self.closeConnection()
            default: break
            }
        }
        link.start(queue: .main)
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self, weak link] in
            guard let self, let link, self.connection === link, !self.isConnected else { return }
            self.status = "连接 10 秒未就绪，请核对权限、地址与热点"
            self.record(self.status)
            self.closeConnection()
        }
    }

    func ping() {
        guard isConnected else { return }
        let id = UUID()
        pending[id] = ProcessInfo.processInfo.systemUptime
        sentCount += 1
        record("发送 ping \(id)")
        send(Message(version: 1, kind: "ping", id: id))
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            guard let self, self.pending.removeValue(forKey: id) != nil else { return }
            self.timeoutCount += 1
            self.record("ping 超时（3 秒无对应 pong）\(id)")
        }
    }

    private func send(_ message: Message) {
        guard let link = connection, isConnected else { return }
        do {
            let payload = try JSONEncoder().encode(message)
            var frame = Data()
            let length = UInt32(payload.count)
            for shift in [24, 16, 8, 0] { frame.append(UInt8((length >> shift) & 255)) }
            frame.append(payload)
            link.send(content: frame, completion: .contentProcessed { [weak self, weak link] error in
                DispatchQueue.main.async {
                    guard let self, let link, self.connection === link else { return }
                    if let error {
                        self.record("发送失败：\(error)")
                        self.closeConnection()
                    }
                }
            })
        } catch { record("编码失败：\(error)") }
    }

    private func receive(_ link: NWConnection) {
        guard !isReceiving else { return }
        isReceiving = true
        link.receive(minimumIncompleteLength: 1, maximumLength: 4096) { [weak self, weak link] data, _, complete, error in
            DispatchQueue.main.async {
                guard let self, let link, self.connection === link else { return }
                self.isReceiving = false
                if let data {
                    self.buffer.append(data)
                    guard self.consumeFrames() else { self.closeConnection(); return }
                }
                if let error {
                    self.record("接收失败：\(error)")
                    self.closeConnection()
                } else if complete {
                    self.status = "对端已关闭连接"
                    self.record("对端结束连接，残留字节 \(self.buffer.count)")
                    self.closeConnection()
                } else {
                    self.receive(link)
                }
            }
        }
    }

    // 长度前缀支持 TCP 拆包/粘包；只允许最多 1024 字节的单条实验消息。
    private func consumeFrames() -> Bool {
        while buffer.count >= 4 {
            let length = buffer.prefix(4).reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }
            guard length > 0, length <= 1024 else { record("拒绝非法消息长度 \(length)"); return false }
            let total = 4 + Int(length)
            guard buffer.count >= total else { return true }
            let payload = Data(buffer.dropFirst(4).prefix(Int(length)))
            buffer = Data(buffer.dropFirst(total))
            do {
                let message = try JSONDecoder().decode(Message.self, from: payload)
                guard message.version == 1 else { record("拒绝协议版本"); return false }
                switch message.kind {
                case "ping":
                    receivedCount += 1
                    record("收到 ping \(message.id)，返回 pong")
                    send(Message(version: 1, kind: "pong", id: message.id))
                case "pong":
                    if let start = pending.removeValue(forKey: message.id) {
                        ackCount += 1
                        let milliseconds = (ProcessInfo.processInfo.systemUptime - start) * 1000
                        record("收到对应 pong \(message.id)，往返 \(String(format: "%.1f", milliseconds)) ms")
                    } else { record("收到迟到或未知 pong \(message.id)，不计入成功") }
                default: record("拒绝未知消息"); return false
                }
            } catch { record("消息解码失败：\(error)"); return false }
        }
        return true
    }

    private func closeConnection() {
        let old = connection
        connection = nil
        isReceiving = false
        isConnected = false
        hasConnection = false
        buffer = Data()
        if !pending.isEmpty {
            timeoutCount += pending.count
            record("连接结束，\(pending.count) 条请求未确认")
            pending = [:]
        }
        old?.cancel()
    }

    func stop() {
        closeConnection()
        let oldListener = listener
        listener = nil
        oldListener?.cancel()
        let oldBrowser = browser
        browser = nil
        oldBrowser?.cancel()
        isListening = false
        isBrowsing = false
        discovered = []
        status = "已停止，可开始新的实验"
        record(status)
        refreshAddresses()
    }

    private func refreshAddresses() {
        var first: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&first) == 0 else { record("无法获取候选地址"); return }
        defer { freeifaddrs(first) }
        var current = first
        var values: [String] = []
        while let item = current {
            defer { current = item.pointee.ifa_next }
            guard let address = item.pointee.ifa_addr,
                  address.pointee.sa_family == UInt8(AF_INET),
                  (item.pointee.ifa_flags & UInt32(IFF_UP)) != 0,
                  (item.pointee.ifa_flags & UInt32(IFF_LOOPBACK)) == 0 else { continue }
            var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            let hostCapacity = socklen_t(host.count)
            if getnameinfo(address, socklen_t(address.pointee.sa_len), &host,
                           hostCapacity, nil, 0, NI_NUMERICHOST) == 0 {
                values.append("\(String(cString: item.pointee.ifa_name))：\(String(cString: host))")
            }
        }
        localAddresses = values.sorted()
        record("IPv4 候选（不代表可达）：\(localAddresses.joined(separator: "，"))")
    }
}
