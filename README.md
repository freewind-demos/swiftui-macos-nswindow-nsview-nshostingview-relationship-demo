# SwiftUI macOS NSWindow / NSView / NSHostingView 关系与用法

## 简介

这个 Demo 专门把 `SwiftUI` 里的 `NSWindow`、`NSView`、`NSHostingView` 拆开讲清楚。

它不只给静态说明，还会在运行时抓当前窗口真实层级，同时演示 2 个最常见桥接方向：

1. `SwiftUI -> NSView`：`NSViewRepresentable`
2. `NSView -> NSHostingView -> SwiftUI`

## 快速开始

### 环境要求

- macOS 14+
- Xcode 15+
- XcodeGen

安装 `XcodeGen`：

```bash
brew install xcodegen
```

### 运行

```bash
cd /Users/peng.li/workspace/freewind-demos/swiftui-macos-nswindow-nsview-nshostingview-relationship-demo
./scripts/build.sh
open build/DerivedData/Build/Products/Debug/SwiftUINSWindowNSViewNSHostingViewRelationshipDemo.app
```

如果你想持续修改并自动重编重启：

```bash
cd /Users/peng.li/workspace/freewind-demos/swiftui-macos-nswindow-nsview-nshostingview-relationship-demo
./dev.sh
```

如果你想直接打开工程：

```bash
cd /Users/peng.li/workspace/freewind-demos/swiftui-macos-nswindow-nsview-nshostingview-relationship-demo
xcodegen generate
open SwiftUINSWindowNSViewNSHostingViewRelationshipDemo.xcodeproj
```

## 注意事项

- 这个 Demo 是 macOS App，不是 iOS
- 运行时关系图依赖当前系统内部 SwiftUI 实现，类名可能随系统版本略有变化
- 但核心关系不变：`NSWindow` 在最外层，SwiftUI 根树通常由 `NSHostingView` 托管

## 教程

### 1. 关键概念

先把 3 个名字分清：

`NSWindow`

- 真正的 macOS 窗口对象
- 负责窗口层级、标题、焦点、大小、关闭等系统行为

`NSView`

- AppKit 的基础视图类型
- 做布局、事件、绘制、Auto Layout
- 传统 macOS UI 的基本积木

`NSHostingView`

- 一个特殊的 `NSView`
- 它的职责是“托管一棵 SwiftUI view 树”
- 当 SwiftUI 要落到 AppKit 世界时，通常靠它接住

### 2. 这个 Demo 在演示什么

这个 Demo 分 3 块：

第一块：运行时关系图

- 用一个隐藏的 `NSViewRepresentable`
- 把真正的探针 `NSView` 插进当前 SwiftUI 树
- 让它向上找 `window` 和 `superview`
- 所以你看到的不是手写结论，而是当前窗口真实层级

第二块：`SwiftUI -> NSView`

- 做一个真正的 `AppKitCounterNSView`
- 外面包一层 `AppKitCounterRepresentable`
- 按钮点击先走 AppKit `target/action`
- 再经 `Coordinator` 回写到 SwiftUI `@State`

第三块：`NSView -> NSHostingView -> SwiftUI`

- 做一个外层 `HostingContainerNSView`
- 它内部手动持有 `NSHostingView`
- `NSHostingView` 的 `rootView` 再指向 `HostedSwiftUICard`
- 所以外层生命周期和布局归 AppKit，里面小块 UI 仍可继续用 SwiftUI 写

### 3. 核心关系怎么记

最常见的方向可以这样记：

```text
NSWindow
  -> contentView（某个 NSView）
    -> NSHostingView
      -> SwiftUI 根视图树
        -> NSViewRepresentable
          -> 你自己的 NSView
```

反过来，如果你已经站在 AppKit 里：

```text
你自己的 NSView
  -> NSHostingView(rootView: ...)
    -> 一小棵 SwiftUI 子树
```

### 4. 关键代码解读

运行时探针的关键思路：

```swift
struct WindowBridgeProbe: NSViewRepresentable {
    @ObservedObject var runtime: RelationshipRuntime

    func makeNSView(context: Context) -> BridgeProbeNSView {
        let view = BridgeProbeNSView()
        view.refresh(runtime: runtime)
        return view
    }
}
```

这里不是为了显示 UI，而是为了把一个真实 `NSView` 插进 SwiftUI 层级里。

然后在这个 `NSView` 里向上抓：

```swift
guard let window else { return }
let superviewChain = makeSuperviewChain()
runtime.apply(window: window, bridgeView: self, superviewChain: superviewChain)
```

这样就能知道：

- 当前挂在哪个 `NSWindow`
- 往上经过了哪些 `NSView`
- 最近的 `NSHostingView` 是谁

`SwiftUI -> NSView` 的关键代码：

```swift
struct AppKitCounterRepresentable: NSViewRepresentable {
    @Binding var count: Int

    func makeNSView(context: Context) -> AppKitCounterNSView {
        let view = AppKitCounterNSView()
        view.onIncrement = { context.coordinator.increment() }
        return view
    }
}
```

意思很直接：

- SwiftUI 负责状态
- 原生 `NSView` 负责按钮和 AppKit 事件
- `Coordinator` 负责把事件桥回 SwiftUI

`NSView -> NSHostingView -> SwiftUI` 的关键代码：

```swift
final class HostingContainerNSView: NSView {
    private let hostingView = NSHostingView(rootView: HostedSwiftUICard(title: "", count: 0))

    func configure(title: String, count: Int) {
        hostingView.rootView = HostedSwiftUICard(title: title, count: count)
    }
}
```

意思是：

- 你仍然站在 AppKit 容器里
- 但你把内部某一块内容交给 SwiftUI 写
- 于是 `NSHostingView` 成了 AppKit 与 SwiftUI 的交界面

## 操作

1. 先看最上面的“运行时关系图”
2. 对照 `NSWindow -> NSHostingView -> ContentView -> NSViewRepresentable -> NSView`
3. 再点中间卡片里的按钮，观察 `NSView` 如何回写 SwiftUI 状态
4. 再点下面卡片里的按钮，观察 `NSHostingView` 如何吃到新的 SwiftUI 子树数据

## 源码入口

- `Sources/SwiftUINSWindowNSViewNSHostingViewRelationshipDemoApp.swift`
- `Sources/ContentView.swift`
- `Sources/WindowBridgeProbe.swift`
- `Sources/BridgeDemos.swift`
- `Sources/RelationshipRuntime.swift`
