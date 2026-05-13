import SwiftUI // 导入 SwiftUI。
import AppKit // 导入 AppKit。

@MainActor // 约束状态更新都在主线程。
final class RelationshipRuntime: ObservableObject { // 定义窗口关系状态容器。
    @Published var windowClassName = "-" // 记录窗口类名。
    @Published var windowTitle = "-" // 记录窗口标题。
    @Published var contentViewClassName = "-" // 记录 window.contentView 类名。
    @Published var hostingViewClassName = "-" // 记录最近的 NSHostingView 类名。
    @Published var bridgeViewClassName = "-" // 记录探针 NSView 类名。
    @Published var superviewChainNames: [String] = [] // 记录探针到顶层的 superview 链。
    @Published var lastSnapshotTime = "未捕获" // 记录最近一次抓取时间。

    func apply(window: NSWindow, bridgeView: NSView, superviewChain: [NSView]) { // 写入一份新快照。
        windowClassName = Self.typeName(of: window) // 更新窗口类名。
        windowTitle = window.title.isEmpty ? "(空标题)" : window.title // 更新窗口标题。
        contentViewClassName = window.contentView.map(Self.typeName(of:)) ?? "-" // 更新 contentView 类名。
        hostingViewClassName = superviewChain.first(where: Self.isHostingView(_:)).map(Self.typeName(of:)) ?? "未找到" // 更新最近的 NSHostingView 类名。
        bridgeViewClassName = Self.typeName(of: bridgeView) // 更新桥接 NSView 类名。
        superviewChainNames = superviewChain.map(Self.typeName(of:)) // 更新整条 superview 链。
        lastSnapshotTime = Date.now.formatted(date: .omitted, time: .standard) // 更新时间戳。
    } // 结束快照更新。

    func reset() { // 重置为未捕获状态。
        windowClassName = "-" // 清空窗口类名。
        windowTitle = "-" // 清空窗口标题。
        contentViewClassName = "-" // 清空 contentView 类名。
        hostingViewClassName = "-" // 清空 hostingView 类名。
        bridgeViewClassName = "-" // 清空桥接 view 类名。
        superviewChainNames = [] // 清空 superview 链。
        lastSnapshotTime = "未捕获" // 清空时间戳。
    } // 结束重置。

    private static func isHostingView(_ view: NSView) -> Bool { // 判断某个 NSView 是否是 NSHostingView。
        typeName(of: view).contains("NSHostingView") // 通过反射名做最稳妥判断。
    } // 结束 hosting 判断。

    private static func typeName(of object: AnyObject) -> String { // 提供统一类型名格式化。
        String(reflecting: type(of: object)) // 返回带模块信息的类型名。
    } // 结束类型名格式化。
} // 结束状态容器。
