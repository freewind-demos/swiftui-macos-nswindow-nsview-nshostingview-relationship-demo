import SwiftUI // 导入 SwiftUI。

@main // 声明应用入口。
struct SwiftUINSWindowNSViewNSHostingViewRelationshipDemoApp: App { // 定义 demo app。
    @StateObject private var runtime = RelationshipRuntime() // 持有窗口关系快照。

    var body: some Scene { // 定义主场景。
        Window("NSWindow / NSView / NSHostingView", id: "main") { // 创建主窗口。
            ContentView(runtime: runtime) // 把快照状态交给根视图。
        } // 结束窗口内容。
        .defaultSize(width: 1180, height: 820) // 设置默认窗口大小。
    } // 结束场景。
} // 结束 app。
