import SwiftUI // 导入 SwiftUI。
import AppKit // 导入 AppKit。

struct AppKitCounterRepresentable: NSViewRepresentable { // 演示如何把自定义 NSView 塞回 SwiftUI。
    @Binding var count: Int // 让 AppKit 操作 SwiftUI 状态。

    func makeCoordinator() -> Coordinator { // 创建协调器。
        Coordinator(count: $count) // 把 binding 交给协调器。
    } // 结束协调器创建。

    func makeNSView(context: Context) -> AppKitCounterNSView { // 首次创建底层 NSView。
        let view = AppKitCounterNSView() // 创建真正显示内容的 AppKit view。
        view.onIncrement = { context.coordinator.increment() } // 把按钮点击桥回 SwiftUI 状态。
        view.configure(count: count) // 首次同步数据显示。
        return view // 返回给 SwiftUI 托管。
    } // 结束 makeNSView。

    func updateNSView(_ nsView: AppKitCounterNSView, context: Context) { // SwiftUI 状态变化时更新 AppKit view。
        nsView.onIncrement = { context.coordinator.increment() } // 确保事件桥一直指向最新协调器。
        nsView.configure(count: count) // 更新当前计数。
    } // 结束 updateNSView。

    final class Coordinator { // 定义把 AppKit 事件改写回 SwiftUI 的协调器。
        private var count: Binding<Int> // 持有 SwiftUI binding。

        init(count: Binding<Int>) { // 注入 binding。
            self.count = count // 保存 binding。
        } // 结束初始化。

        func increment() { // 把 AppKit 点击回写到 SwiftUI。
            count.wrappedValue += 1 // 自增计数。
        } // 结束加一动作。
    } // 结束协调器。
} // 结束 NSViewRepresentable demo。

final class AppKitCounterNSView: NSView { // 定义自定义 AppKit 计数 view。
    private let titleLabel = NSTextField(labelWithString: "我是原生 NSView。") // 标题文案。
    private let detailLabel = NSTextField(labelWithString: "点击按钮后，事件会经 Coordinator 回写到 SwiftUI @State。") // 说明文案。
    private let countLabel = NSTextField(labelWithString: "") // 计数展示文案。
    private let button = NSButton(title: "让 NSView 改 SwiftUI 状态 +1", target: nil, action: nil) // 演示事件桥的按钮。
    var onIncrement: (() -> Void)? // 暴露点击回调。

    override init(frame frameRect: NSRect) { // 自定义初始化入口。
        super.init(frame: frameRect) // 先调用父类初始化。
        wantsLayer = true // 开启 layer，方便做背景。
        layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor // 设置浅色背景。
        layer?.cornerRadius = 12 // 设置圆角。
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold) // 强调标题。
        detailLabel.textColor = .secondaryLabelColor // 弱化说明文案。
        detailLabel.maximumNumberOfLines = 0 // 允许说明换行。
        countLabel.font = .monospacedDigitSystemFont(ofSize: 22, weight: .bold) // 让数字更清晰。
        button.bezelStyle = .rounded // 使用系统圆角按钮样式。
        button.target = self // 把按钮事件交给当前 view。
        button.action = #selector(handleIncrement) // 绑定点击处理方法。
        let stack = NSStackView(views: [titleLabel, detailLabel, countLabel, button]) // 用 stack 简化布局。
        stack.orientation = .vertical // 垂直排列各元素。
        stack.alignment = .leading // 左对齐。
        stack.spacing = 10 // 设置元素间距。
        addSubview(stack) // 把 stack 放进当前 view。
        stack.translatesAutoresizingMaskIntoConstraints = false // 改用 Auto Layout。
        NSLayoutConstraint.activate([ // 激活四边约束。
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18), // 约束左边距。
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18), // 约束右边距。
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 18), // 约束上边距。
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -18), // 约束下边距。
        ]) // 结束约束激活。
    } // 结束初始化。

    @available(*, unavailable) // 明确禁用 storyboard 初始化。
    required init?(coder: NSCoder) { // 占位实现系统要求的初始化方法。
        fatalError("init(coder:) has not been implemented") // 直接说明这里不支持。
    } // 结束 coder 初始化。

    func configure(count: Int) { // 根据 SwiftUI 状态刷新显示。
        countLabel.stringValue = "当前 count = \(count)" // 更新数字文案。
    } // 结束 configure。

    @objc private func handleIncrement() { // 处理按钮点击。
        onIncrement?() // 把事件透出给协调器。
    } // 结束点击处理。
} // 结束自定义 AppKit 计数 view。

struct HostingContainerRepresentable: NSViewRepresentable { // 演示如何在 NSView 里手动塞 NSHostingView。
    let title: String // 要显示给 SwiftUI 子树的标题。
    let count: Int // 要显示给 SwiftUI 子树的计数。

    func makeNSView(context: Context) -> HostingContainerNSView { // 首次创建 AppKit 容器。
        let view = HostingContainerNSView() // 创建容器 view。
        view.configure(title: title, count: count) // 注入首次数据。
        return view // 返回容器。
    } // 结束 makeNSView。

    func updateNSView(_ nsView: HostingContainerNSView, context: Context) { // SwiftUI 状态变化时刷新容器。
        nsView.configure(title: title, count: count) // 更新标题与计数。
    } // 结束 updateNSView。
} // 结束 hosting 容器桥。

final class HostingContainerNSView: NSView { // 定义一个内部持有 NSHostingView 的 AppKit 容器。
    private let nativeLabel = NSTextField(labelWithString: "我是外层 NSView；下面卡片是我手动创建并持有的 NSHostingView。") // 说明外层容器职责。
    private let hostingView = NSHostingView(rootView: HostedSwiftUICard(title: "", count: 0)) // 创建托管 SwiftUI 子树的 hosting view。

    override init(frame frameRect: NSRect) { // 自定义初始化入口。
        super.init(frame: frameRect) // 先完成父类初始化。
        wantsLayer = true // 开启 layer。
        layer?.backgroundColor = NSColor.quaternaryLabelColor.withAlphaComponent(0.08).cgColor // 设置淡背景。
        layer?.cornerRadius = 12 // 设置圆角。
        nativeLabel.textColor = .secondaryLabelColor // 弱化原生说明文字。
        nativeLabel.maximumNumberOfLines = 0 // 允许说明文字换行。
        let stack = NSStackView(views: [nativeLabel, hostingView]) // 用 stack 承载原生标题与 hosting view。
        stack.orientation = .vertical // 垂直布局。
        stack.alignment = .leading // 左对齐。
        stack.spacing = 12 // 设置间距。
        addSubview(stack) // 把 stack 加到容器里。
        stack.translatesAutoresizingMaskIntoConstraints = false // 改用 Auto Layout。
        hostingView.translatesAutoresizingMaskIntoConstraints = false // 让 hosting view 参与约束。
        NSLayoutConstraint.activate([ // 激活约束。
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18), // 约束左边距。
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18), // 约束右边距。
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 18), // 约束上边距。
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -18), // 约束下边距。
            hostingView.widthAnchor.constraint(greaterThanOrEqualToConstant: 320), // 给 hosting view 一个可读宽度。
        ]) // 结束约束激活。
    } // 结束初始化。

    @available(*, unavailable) // 明确禁用 storyboard 初始化。
    required init?(coder: NSCoder) { // 占位实现系统要求的初始化方法。
        fatalError("init(coder:) has not been implemented") // 直接说明这里不支持。
    } // 结束 coder 初始化。

    func configure(title: String, count: Int) { // 根据外部状态刷新容器。
        hostingView.rootView = HostedSwiftUICard(title: title, count: count) // 把最新 SwiftUI 子树塞进 NSHostingView。
    } // 结束 configure。
} // 结束 hosting 容器。

struct HostedSwiftUICard: View { // 定义由 NSHostingView 托管的 SwiftUI 子树。
    let title: String // 显示标题。
    let count: Int // 显示计数。

    var body: some View { // 定义 SwiftUI 子树内容。
        VStack(alignment: .leading, spacing: 10) { // 垂直排布卡片内容。
            Text(title) // 显示标题。
                .font(.title3.weight(.semibold)) // 强调标题。
            Text("这个区域虽然长得像普通 SwiftUI，但它其实挂在 NSHostingView 下面。") // 解释当前子树出处。
                .foregroundStyle(.secondary) // 弱化说明文字。
            Text("count = \(count)") // 显示当前计数。
                .font(.system(size: 28, weight: .bold, design: .rounded)) // 放大数字。
            HStack(spacing: 10) { // 横向展示 3 个语义标签。
                BadgeLabel(text: "外层: NSView") // 标签 1。
                BadgeLabel(text: "中层: NSHostingView") // 标签 2。
                BadgeLabel(text: "内层: SwiftUI View") // 标签 3。
            } // 结束标签行。
        } // 结束垂直卡片内容。
        .padding(18) // 增加内边距。
        .frame(maxWidth: .infinity, alignment: .leading) // 拉满可用宽度。
        .background(Color(nsColor: .windowBackgroundColor)) // 使用系统窗口底色。
        .overlay( // 加一层边框。
            RoundedRectangle(cornerRadius: 12) // 创建圆角矩形。
                .stroke(Color.blue.opacity(0.35), lineWidth: 1) // 绘制蓝色描边。
        ) // 结束边框。
        .clipShape(RoundedRectangle(cornerRadius: 12)) // 裁出圆角。
    } // 结束 SwiftUI 子树内容。
} // 结束 hosted SwiftUI 卡片。

private struct BadgeLabel: View { // 定义一个复用标签。
    let text: String // 保存标签文字。

    var body: some View { // 定义标签样式。
        Text(text) // 显示文字。
            .font(.system(size: 12, weight: .medium, design: .rounded)) // 设置标签字体。
            .padding(.horizontal, 10) // 设置水平内边距。
            .padding(.vertical, 6) // 设置垂直内边距。
            .background(Color.blue.opacity(0.12)) // 设置淡蓝背景。
            .clipShape(Capsule()) // 做成胶囊。
    } // 结束标签样式。
} // 结束标签定义。
