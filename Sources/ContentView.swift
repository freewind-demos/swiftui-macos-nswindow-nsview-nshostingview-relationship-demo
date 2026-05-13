import SwiftUI // 导入 SwiftUI。

struct ContentView: View { // 定义 demo 主界面。
    @ObservedObject var runtime: RelationshipRuntime // 读取窗口关系快照。
    @State private var appKitCounter = 0 // 给 NSViewRepresentable demo 用的计数。
    @State private var hostedCounter = 3 // 给 NSHostingView demo 用的计数。

    var body: some View { // 定义主界面内容。
        ScrollView { // 内容较长，外层用滚动容器。
            VStack(alignment: .leading, spacing: 24) { // 自上而下摆放所有模块。
                headerSection // 顶部说明区。
                relationshipSection // 关系图与运行时快照。
                appKitIntoSwiftUISection // 演示 NSViewRepresentable。
                swiftUIIntoAppKitSection // 演示 NSHostingView。
            } // 结束纵向主布局。
            .padding(28) // 给整体内容加边距。
        } // 结束滚动容器。
        .background(Color(nsColor: .windowBackgroundColor)) // 使用系统窗口背景色。
        .background( // 在背景里插一个隐形探针。
            WindowBridgeProbe(runtime: runtime) // 让探针进入同一棵 SwiftUI/AppKit 树。
                .frame(width: 0, height: 0) // 探针本身不占空间。
        ) // 结束探针背景。
    } // 结束主界面内容。

    private var headerSection: some View { // 定义顶部说明区。
        VStack(alignment: .leading, spacing: 14) { // 垂直排顶部文案。
            Text("SwiftUI 里的 NSWindow / NSView / NSHostingView") // 显示主标题。
                .font(.system(size: 30, weight: .bold, design: .rounded)) // 使用醒目标题字体。
            Text("这个 Demo 把 3 个方向拆开看：最外层窗口是谁、SwiftUI 根树怎样落到 NSHostingView、以及 SwiftUI 与 AppKit 双向嵌套时各自该站哪一层。") // 给出 demo 目标。
                .foregroundStyle(.secondary) // 弱化辅助文字。
            HStack(spacing: 12) { // 放 3 个摘要标签。
                Pill(text: "1. Window 承载根树") // 标签 1。
                Pill(text: "2. NSViewRepresentable 向内桥") // 标签 2。
                Pill(text: "3. NSHostingView 向外托管") // 标签 3。
            } // 结束摘要标签。
        } // 结束顶部说明区布局。
    } // 结束顶部说明区。

    private var relationshipSection: some View { // 定义运行时关系图区域。
        DemoCard(title: "运行时关系图", subtitle: "这个区域直接读取当前窗口实际层级，不是手写示意图。") { // 包一层卡片。
            VStack(alignment: .leading, spacing: 12) { // 垂直排层级节点。
                DiagramRow(role: "最外层", title: "NSWindow", detail: runtime.windowClassName + " · title = " + runtime.windowTitle) // 显示窗口节点。
                ArrowRow() // 加箭头。
                DiagramRow(role: "window.contentView", title: "NSView", detail: runtime.contentViewClassName) // 显示 window.contentView。
                ArrowRow() // 加箭头。
                DiagramRow(role: "SwiftUI 根宿主", title: "NSHostingView", detail: runtime.hostingViewClassName) // 显示 hosting view。
                ArrowRow() // 加箭头。
                DiagramRow(role: "SwiftUI 根视图", title: "ContentView", detail: "这里开始进入纯 SwiftUI body。") // 显示 SwiftUI 根视图。
                ArrowRow() // 加箭头。
                DiagramRow(role: "桥接探针", title: "NSViewRepresentable -> NSView", detail: runtime.bridgeViewClassName) // 显示桥接探针。
                VStack(alignment: .leading, spacing: 6) { // 再展示真实 superview 链。
                    Text("探针往上看到的 superview 链") // 显示链标题。
                        .font(.headline) // 强调链标题。
                    Text(runtime.superviewChainNames.isEmpty ? "暂无数据" : runtime.superviewChainNames.joined(separator: "\n")) // 展示每一层真实类名。
                        .font(.system(.body, design: .monospaced)) // 用等宽字体显示类名。
                        .textSelection(.enabled) // 允许复制类名。
                        .foregroundStyle(.secondary) // 弱化次级信息。
                    Text("最近抓取: \(runtime.lastSnapshotTime)") // 展示抓取时间。
                        .font(.footnote) // 用脚注样式。
                        .foregroundStyle(.secondary) // 弱化时间信息。
                } // 结束 superview 链展示。
                Text("结论：SwiftUI 根视图本身不是 NSView。真正进入 AppKit 世界的是系统替你创建的 NSHostingView；而你自定义的 AppKit view 需要通过 NSViewRepresentable 进来。") // 给出这一段的结论。
                    .foregroundStyle(.secondary) // 弱化结论文字。
            } // 结束关系图内容。
        } // 结束关系图卡片。
    } // 结束关系图区域。

    private var appKitIntoSwiftUISection: some View { // 定义 NSViewRepresentable 演示区。
        DemoCard(title: "SwiftUI -> NSView", subtitle: "用 NSViewRepresentable 把一个真正的 AppKit view 塞进 SwiftUI。") { // 包卡片。
            VStack(alignment: .leading, spacing: 14) { // 垂直摆放说明与 demo。
                Text("这里的按钮活在原生 NSView 里；点击后先走 AppKit target/action，再经 Coordinator 回写到 SwiftUI @State。") // 解释事件流向。
                    .foregroundStyle(.secondary) // 弱化说明文字。
                AppKitCounterRepresentable(count: $appKitCounter) // 插入自定义 NSView。
                    .frame(maxWidth: .infinity, minHeight: 180) // 给 demo 一个稳定高度。
                Text("SwiftUI 侧同步读到的 count = \(appKitCounter)") // 证明 AppKit 已改到 SwiftUI 状态。
                    .font(.system(size: 16, weight: .semibold, design: .rounded)) // 强调同步结果。
            } // 结束 NSViewRepresentable 演示区内容。
        } // 结束 NSViewRepresentable 演示区卡片。
    } // 结束 NSViewRepresentable 演示区。

    private var swiftUIIntoAppKitSection: some View { // 定义 NSHostingView 演示区。
        DemoCard(title: "NSView -> NSHostingView -> SwiftUI", subtitle: "当外层壳必须是 AppKit 时，用 NSHostingView 托管一小棵 SwiftUI 子树。") { // 包卡片。
            VStack(alignment: .leading, spacing: 14) { // 垂直摆放说明与 demo。
                Text("外层 `HostingContainerNSView` 先决定布局、生命周期、Auto Layout；真正要复用的声明式 UI，再塞给它内部持有的 `NSHostingView`。") // 解释职责分层。
                    .foregroundStyle(.secondary) // 弱化说明。
                HStack(spacing: 12) { // 放一组按钮改 SwiftUI 状态。
                    Button("SwiftUI count - 1") { // 减 1 按钮。
                        hostedCounter -= 1 // 更新 SwiftUI 状态。
                    } // 结束减 1 动作。
                    Button("SwiftUI count + 1") { // 加 1 按钮。
                        hostedCounter += 1 // 更新 SwiftUI 状态。
                    } // 结束加 1 动作。
                    Button("重置为 3") { // 重置按钮。
                        hostedCounter = 3 // 回到初始值。
                    } // 结束重置动作。
                } // 结束按钮行。
                HostingContainerRepresentable(title: "这块 SwiftUI 卡片由 NSHostingView 托管", count: hostedCounter) // 插入内部持有 NSHostingView 的 AppKit 容器。
                    .frame(maxWidth: .infinity, minHeight: 220) // 给容器稳定高度。
                Text("这段模式适合：你的外层必须接 NSWindow / NSViewController / Auto Layout / 旧 AppKit 生命周期，但某块 UI 想用 SwiftUI 写。") // 总结适用场景。
                    .foregroundStyle(.secondary) // 弱化总结。
            } // 结束 NSHostingView 演示区内容。
        } // 结束 NSHostingView 演示区卡片。
    } // 结束 NSHostingView 演示区。
} // 结束主界面。

private struct DemoCard<Content: View>: View { // 定义统一卡片容器。
    let title: String // 保存卡片标题。
    let subtitle: String // 保存卡片副标题。
    @ViewBuilder let content: Content // 保存卡片主体内容。

    var body: some View { // 定义卡片外观。
        VStack(alignment: .leading, spacing: 16) { // 垂直排卡片内容。
            Text(title) // 显示标题。
                .font(.title2.weight(.bold)) // 设置标题样式。
            Text(subtitle) // 显示副标题。
                .foregroundStyle(.secondary) // 弱化副标题。
            content // 注入调用方内容。
        } // 结束卡片内容布局。
        .padding(20) // 给卡片加内边距。
        .frame(maxWidth: .infinity, alignment: .leading) // 拉满宽度并左对齐。
        .background(Color(nsColor: .controlBackgroundColor)) // 使用系统控制背景色。
        .clipShape(RoundedRectangle(cornerRadius: 16)) // 统一圆角。
        .overlay( // 再叠一层淡描边。
            RoundedRectangle(cornerRadius: 16) // 创建圆角矩形。
                .stroke(Color.black.opacity(0.06), lineWidth: 1) // 绘制淡边框。
        ) // 结束描边。
    } // 结束卡片外观。
} // 结束卡片定义。

private struct DiagramRow: View { // 定义关系图节点行。
    let role: String // 记录节点角色。
    let title: String // 记录节点标题。
    let detail: String // 记录节点细节。

    var body: some View { // 定义节点行样式。
        VStack(alignment: .leading, spacing: 6) { // 垂直排节点信息。
            Text(role.uppercased()) // 显示角色。
                .font(.caption.weight(.bold)) // 用小号粗体。
                .foregroundStyle(.secondary) // 弱化角色说明。
            Text(title) // 显示节点名称。
                .font(.system(size: 18, weight: .bold, design: .rounded)) // 强调节点名称。
            Text(detail) // 显示节点细节。
                .font(.system(.body, design: .monospaced)) // 用等宽字体显示细节。
                .textSelection(.enabled) // 允许复制细节。
                .foregroundStyle(.secondary) // 弱化细节。
        } // 结束节点信息布局。
        .padding(14) // 给节点加边距。
        .frame(maxWidth: .infinity, alignment: .leading) // 拉满宽度。
        .background(Color.blue.opacity(0.06)) // 给节点浅蓝背景。
        .clipShape(RoundedRectangle(cornerRadius: 12)) // 做圆角。
    } // 结束节点行样式。
} // 结束节点行定义。

private struct ArrowRow: View { // 定义箭头行。
    var body: some View { // 定义箭头外观。
        HStack { // 用横向容器承载箭头。
            Image(systemName: "arrow.down") // 显示向下箭头。
                .foregroundStyle(.secondary) // 弱化箭头颜色。
        } // 结束箭头布局。
        .frame(maxWidth: .infinity) // 让箭头居中。
    } // 结束箭头外观。
} // 结束箭头行定义。

private struct Pill: View { // 定义顶部摘要标签。
    let text: String // 保存标签文本。

    var body: some View { // 定义标签样式。
        Text(text) // 显示标签。
            .font(.system(size: 12, weight: .medium, design: .rounded)) // 设置标签字体。
            .padding(.horizontal, 10) // 设置水平内边距。
            .padding(.vertical, 6) // 设置垂直内边距。
            .background(Color.orange.opacity(0.15)) // 设置浅橙背景。
            .clipShape(Capsule()) // 做成胶囊。
    } // 结束标签样式。
} // 结束标签定义。
