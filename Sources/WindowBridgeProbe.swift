import SwiftUI // 导入 SwiftUI。
import AppKit // 导入 AppKit。

struct WindowBridgeProbe: NSViewRepresentable { // 定义 SwiftUI 到 AppKit 的探针桥。
    @ObservedObject var runtime: RelationshipRuntime // 持有要回写的快照状态。

    func makeNSView(context: Context) -> BridgeProbeNSView { // 首次创建底层 NSView。
        let view = BridgeProbeNSView() // 创建探针 view。
        view.refresh(runtime: runtime) // 首次注入状态对象。
        return view // 返回探针 view。
    } // 结束 makeNSView。

    func updateNSView(_ nsView: BridgeProbeNSView, context: Context) { // SwiftUI 刷新时同步状态对象。
        nsView.refresh(runtime: runtime) // 触发探针重新抓关系。
    } // 结束 updateNSView。
} // 结束探针桥定义。

final class BridgeProbeNSView: NSView { // 定义真正插入 SwiftUI 树中的 NSView。
    private weak var runtime: RelationshipRuntime? // 弱持有状态，避免无意义循环。

    override func viewDidMoveToWindow() { // 在 view 挂到窗口时抓一次。
        super.viewDidMoveToWindow() // 先走系统默认逻辑。
        captureHierarchySoon() // 延后到下一轮 runloop 再抓，保证层级稳定。
    } // 结束窗口挂载回调。

    override func viewDidMoveToSuperview() { // 在 view 挂到 superview 时也抓一次。
        super.viewDidMoveToSuperview() // 先走系统默认逻辑。
        captureHierarchySoon() // 延后抓取，避免中间态。
    } // 结束 superview 挂载回调。

    func refresh(runtime: RelationshipRuntime) { // 更新当前状态对象。
        self.runtime = runtime // 替换成最新状态对象。
        captureHierarchySoon() // 每次刷新后都补抓一次。
    } // 结束 refresh。

    private func captureHierarchySoon() { // 把真正抓取推迟到主线程下一拍。
        DispatchQueue.main.async { [weak self] in // 切到下一轮 runloop。
            self?.captureHierarchyNow() // 执行一次真正抓取。
        } // 结束异步块。
    } // 结束延后抓取。

    private func captureHierarchyNow() { // 读取 window 与 superview 链。
        guard let runtime else { return } // 没有状态对象就直接结束。
        guard let window else { runtime.reset(); return } // 还没进窗口时回写未捕获状态。
        let superviewChain = makeSuperviewChain() // 从当前 view 往上收集所有 superview。
        runtime.apply(window: window, bridgeView: self, superviewChain: superviewChain) // 把抓到的结果写回状态。
    } // 结束即时抓取。

    private func makeSuperviewChain() -> [NSView] { // 组装当前 view 到顶层的 superview 链。
        var views: [NSView] = [self] // 先把自己放进数组。
        var currentSuperview = superview // 从直接父 view 开始往上走。

        while let view = currentSuperview { // 只要还存在父 view 就继续。
            views.append(view) // 记录当前父 view。
            currentSuperview = view.superview // 继续往上跳。
        } // 结束上溯。

        return views // 返回完整链路。
    } // 结束链路组装。
} // 结束探针 view。
