import SwiftUI

struct FeasibilityView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("第一阶段：可行性评估") {
                    Text("这是项目骨架，尚未提供音乐搜索、播放或遥控功能。")
                    Text("主要环境：iPhone 开启个人热点，iPad 连接热点。")
                }
                Section("关键验证尚未完成") {
                    Text("免费账户的 MusicKit 服务资格")
                    Text("热点中的双向通信与发现")
                    Text("iPad 锁屏播放与接收新选歌")
                    Text("暂停较长时间后远程恢复")
                }
                Section("项目状态") {
                    Text("请先阅读仓库中的 FEASIBILITY.md 和真机验证计划。")
                }
            }
            .navigationTitle("Music Remote")
        }
    }
}
