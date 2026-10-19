# 桌面端 Bot App WebView 需求

状态：草案（2026-10-18）。适用平台：macOS、Windows、Linux。

## 1. 背景与目标

桌面端打开 bot app 时，现在用的是 `desktop_webview_window` 0.3.x：Flutter 画的标题栏，外加一个只注入了 `MixinContext.getContext()` 的 WebView
（`lib/utils/web_view/web_view_desktop.dart`）。iOS 和 Android 早就是另一种形态：没有标题栏，右上角只有一个 native 胶囊（`••• | ✕`），
点 `•••` 弹出操作菜单，页面能调用一整套 `MixinContext` JS bridge。

目标是让桌面端的形态和能力尽量对齐移动端：

- 窗口没有系统标题栏和系统按钮，只保留右上角的胶囊。胶囊的形态和位置与移动端一致。
- 胶囊上方留一条沉浸式区域，专门用来拖动窗口。
- 点 `•••` 时，在当前 WebView 窗口里弹出一个 Flutter view。这个 view 和主窗口共享同一个 Flutter 引擎，所以数据（会话、账号、app 信息）直接互通。
- 页面能用的 JS bridge 和导航行为与 Android 对齐。

页面本身是为手机设计的，所以窗口**固定尺寸，不支持最大化、全屏和调整大小**。

## 2. 依赖：升级 `desktop_webview_window` 到 0.4.0

0.4.0 已发布到 pub.dev，是 breaking release。插件不再提供 Flutter 标题栏，改成由 runner 安装一个 native **composer** 来决定窗口里有什么。
需要先读插件 README 的 “Custom window layout” 和 “Migrating to 0.4.0” 两节，以及头文件
`desktop_webview_window/webview_window_composer.h`。

flutter-app 要做的迁移：

| 现状 | 0.4.0 |
|---|---|
| `main.dart` 里的 `runWebViewNavigationBar(args)` / `runWebViewTitleBarWidget` | 删除。标题栏改由 native composer 负责 |
| `lib/widgets/web_view_navigation_bar.dart` | 删除 |
| `CreateConfiguration(titleBarTopPadding:, userDataFolderWindows:)` | 删掉 `titleBarTopPadding`，改成 `windows: WindowsWebviewOptions(userDataFolder:)` |
| `WebviewWindow.clearAll(userDataFolderWindows:)` | `clearAll(windows: WindowsWebviewOptions(...))` |
| `setBrightness` 在窗口创建后才调用，启动时会闪一下 | `CreateConfiguration(brightness:)` 在窗口显示前就生效 |
| JS handler `(data)` | `(Object? data, String origin)`，可以按来源校验调用方（见 5.5） |
| macOS 沙盒 | 页面要上传文件或下载时，需要 entitlement `com.apple.security.files.user-selected.read-write` |

## 3. 平台范围

| 能力 | macOS | Windows | Linux Wayland | Linux X11 |
|---|---|---|---|---|
| 无系统标题栏、拖拽区、胶囊 | ✅ | ✅ | ✅ | ✅ |
| JS bridge、导航策略 | ✅ | ✅ | ✅ | ✅ |
| `•••` 弹出共享引擎的 Flutter view | ✅ | ✅ | ✅ | ❌ 降级，见 5.4 |

Linux X11 不做 Flutter view，原因是同一个引擎上创建第二个 `FlView` 会崩，GLX BadAccess，见
[flutter/flutter#186577](https://github.com/flutter/flutter/issues/186577)。除了这一项，X11 上其余功能都要做。
运行时用 `GDK_IS_X11_DISPLAY(gdk_display_get_default())` 判断是否是 X11。

## 4. 窗口形态

```
沉浸式（app capabilities 包含 IMMERSIVE）        非沉浸式
┌──────────────────────────────┐               ┌──────────────────────────────┐
│░░░░░░░░░░ 拖拽区 ░░░░░░░░░░░░│ ← theme-color  │░░░░░░░░░░ 拖拽区 ░░░░░░░░░░░░│
│                   ( ••• │ ✕ )│ ← 浮在页面上    │ ‹ [icon] Bot Name ( ••• │ ✕ )│ ← 标题行，也能拖动
│                              │               ├──────────────────────────────┤
│         WebView              │               │         WebView              │
│                              │               │                              │
└──────────────────────────────┘               └──────────────────────────────┘
```

| 项 | 规格 |
|---|---|
| 窗口尺寸 | 沿用现在的 `380 × 750` 逻辑像素（包含拖拽区）。固定，不能 resize、最大化或全屏 |
| 拖拽区 | 窗口最上方一条，高度建议 `28`，最终由设计确认。只用来拖动，**双击不做任何事** |
| 胶囊 | `88 × 32`，距 WebView 区域的顶部 `6`、右边 `6`（Android `fragment_web.xml` 的 `web_control`）。左右两半分别是 `•••` 和 `✕`，中间是一条 1px 分隔线，上下各留 8 |
| 非沉浸式标题行 | 高 44，显示 app 图标和名字（和 Android `titleVa` 一致）。胶囊垂直居中在这一行里。整行可以拖动，但胶囊本身不响应拖动 |
| 返回按钮 | 只在非沉浸式标题行，图标左边的 `‹`。页面能后退（`can_go_back`）时显示，不能后退时隐藏，图标和标题左移补位。沉浸式没有标题行，由页面自己处理返回 |
| WebView 区域 | 从拖拽区（沉浸式）或标题行（非沉浸式）下面开始，**不延伸到拖拽区底下**。桌面 WebView 的 `env(safe-area-inset-top)` 是 0，页面不会为顶部留空 |
| 背景色 | 拖拽区和标题行使用页面 `<meta name="theme-color">` 的颜色；页面没有设置时，用 app 主题的背景色 |
| 胶囊样式 | 根据 theme-color 的亮度切换 light/dark 两套（Android `WebControlView.updateByMode`、`refreshByLuminance`） |
| 窗口外观 | 保留系统的圆角和阴影（macOS、Windows 11）。Linux 没有标题栏时不保证有阴影 |
| 关闭 | 胶囊 `✕`、页面调用 `MixinContext.close()`、Cmd+W、Alt+F4 都走 `webview.close()` 或 `dww_browser_close` |
| 前进后退快捷键 | 所有布局都支持鼠标侧键。macOS 用 `⌘[` / `⌘]`，Linux 和 Windows 用 `Alt+←` / `Alt+→`。Windows 页面区域由 WebView2 自己处理，composer 只接 header 区域和冒泡上来的 `WM_APPCOMMAND` |
| 最小化 | 不提供按钮。Cmd+M 和任务栏/Dock 的系统行为保持 |

## 5. 功能需求

### 5.1 Native composer（三个平台各写一份，放在 runner 里）

在第一个 browser 创建之前调用 `dww_set_composer` 安装 composer。flutter-app 的 WebView 窗口全部交给它处理，包括 bot app 和普通链接，
因为移动端两种情况都显示胶囊。

- Dart 通过 `CreateConfiguration(composerArguments:)` 传一段 JSON 给 `compose`，内容是首帧需要的信息：`immersive`、app 名字和图标路径、初始背景色、是否是 bot。
- composer 按 browser id 保存每个窗口的状态，在 `closing` 时释放。browser id 和 Dart 侧的 `Webview.id` 是同一个值。
- composer 要做的事：
  - 去掉系统标题栏和按钮，禁止 resize 和最大化；
  - 放好拖拽区、标题行和胶囊；
  - 把 `webview_view` 放到第 4 节规定的区域。

各平台要点：

| 平台 | 窗口 | 拖拽 | 胶囊叠在 WebView 上 |
|---|---|---|---|
| macOS | 保留 `.titled` 和 `.closable`，去掉 `.resizable`；设置 `titlebarAppearsTransparent`、`titleVisibility = .hidden`、`.fullSizeContentView`；隐藏三个 `standardWindowButton`；关闭 zoom | 拖拽区 view 在 `mouseDown` 里调用 `window.performDrag(with:)` | 普通 `NSView`，叠在 `webview_view` 上面 |
| Windows | 用 `SetWindowSubclass` 子类化窗口：`WM_NCCALCSIZE` 去掉非客户区，去掉 `WS_THICKFRAME` 和 `WS_MAXIMIZEBOX`，`DWMWA_WINDOW_CORNER_PREFERENCE = DWMWCP_ROUND`。在 `layout` 回调里摆放 `webview_view` | 拖拽区和标题行在 `WM_NCHITTEST` 返回 `HTCAPTION`，其他位置返回 `HTCLIENT`，不能返回任何 resize 边框 | WebView2 是一个子 HWND（airspace），胶囊必须是 z-order 在它之上的兄弟子 HWND。要做圆角和抗锯齿，需要 `WS_EX_LAYERED` 子窗口配合 `UpdateLayeredWindow`（Win8 及以上，manifest 里已声明） |
| Linux | `gtk_window_set_decorated(FALSE)`、`gtk_window_set_resizable(FALSE)` | 拖拽区放一个 `GtkEventBox`，在 `button-press` 里调用 `gtk_window_begin_move_drag` | 用 `GtkOverlay` 把胶囊叠在 WebView 上，圆角和颜色用 CSS 实现 |

插件仓库里 example 的 `linux/test_composer.cc` 和 `macos/Runner/TestComposer.swift` 可以当作起点。

### 5.2 Runner 和 Dart 之间的通道

插件的 composer 只负责 native 之间的调用。flutter-app 需要在 runner 里自己注册一个 MethodChannel，名字比如 `one.mixin/bot_window`：

| 方向 | 方法 | 用途 |
|---|---|---|
| native → Dart | `onMoreTapped(browserId)` | 用户点了 `•••` |
| native → Dart | `onPopupDismissed(browserId)` | 弹出层被关闭，比如按了 Esc 或点了遮罩 |
| Dart → native | `setChrome(browserId, {backgroundColor, capsuleStyle})` | 读到 theme-color 后，更新拖拽区、标题行和胶囊的颜色 |
| Dart → native | `showPopup(browserId)` / `hidePopup(browserId)` | 显示或隐藏弹出用的 Flutter view。返回 view id，失败时返回错误 |

`✕` 不需要经过 Dart，composer 直接调用 `dww_browser_close`。Dart 侧通过 `webview.onClose` 清理资源。

### 5.3 theme-color

- 在 document start 注册 `MutationObserver`（只观察 `<head>`；`<head>` 出现前临时观察整个 document），解析到 `theme-color` 或其内容变化时立即更新，不等待页面和子资源加载完成。每次页面加载完成，以及页面调用 `MixinContext.reloadTheme()` 时也更新：
  - 用 `evaluateJavaScript` 读取 `<meta name="theme-color">`，脚本和 Android `WebFragment.themeColorScript` 一致；
  - 然后调用 `setChrome`。
- 胶囊的 light/dark 判断规则与 Android `refreshByLuminance` 一致。

### 5.4 `•••` 弹出层

**内容**与移动端一致：

| 页面类型 | 第一组 | 第二组 |
|---|---|---|
| Bot app | 转发、刷新 | 关于（bot 资料） |
| 普通网页 | 转发、刷新 | 复制链接、在浏览器打开 |

头部显示：bot 页面显示图标、名字、认证标记和 app number；普通网页显示标题和 URL。

- **转发**：沿用 `web_view_mobile.dart` 里 `_ShareMenuItem` 的逻辑。URL 匹配 `resourcePatterns` 时发 AppCard，否则发文本链接；`shareable == false` 时禁止转发。
- **刷新**：`webview.reload()`。
- 桌面端没有查看授权的权限，因此不显示授权菜单。
- 移动端的“悬浮”和“扫码”不做。桌面窗口本来就常驻，不需要悬浮；bot 菜单本来也没有扫码。

**实现方式**（macOS、Windows、Linux Wayland）：

- Native 侧用主引擎创建一个额外的 Flutter view，放进 WebView 窗口：
  - macOS：用主引擎创建 `FlutterViewController`；
  - Windows：`FlutterDesktopEngineCreateViewController`；
  - Linux：`fl_view_new_for_engine`。
- Dart 侧把弹出层的 widget 渲染进这个 view，可以用 `ViewAnchor` 加 `View`，或者把根改成 `runWidget` 加 `ViewCollection`。这样就能直接拿到 `accountServer`、数据库和会话选择器。
- **第一次点 `•••` 时才创建这个 view，之后只隐藏和复用，在 composer 的 `closing` 回调里销毁**。不要每次弹出都创建和销毁一次。
- 关闭弹出层：选完某一项、点遮罩、按 Esc。
- 样式：
  - macOS 和 Wayland：view 盖住整个 WebView 区域，背景透明，Flutter 自己画半透明遮罩和底部 sheet。
  - Windows：Flutter view 也是子 HWND，盖在 WebView2 上时**透明区域透不到网页**。第一版 view 只占 sheet 自己的矩形区域，不做遮罩。
- 关于的用户资料弹窗在 WebView 窗口内打开。菜单转发和用户资料里的转发都先关闭 WebView 弹层，再激活主窗口，在主窗口选择会话。

**Linux X11 降级**：不创建 Flutter view。点 `•••` 弹出一个 native `GtkMenu`，只放不需要 Flutter UI 的几项：刷新、复制链接、在浏览器打开、关闭。转发、关于在 X11 上先不提供。

参考实现：这个方案在插件历史里做过一版，提交 `a49a704`，后来撤掉了。插件 `doc/shared_titlebar_engine.md` 记录了各平台借用主引擎的方式和注意事项，可以参考。

### 5.5 JS bridge

在 `addScriptToExecuteOnDocumentCreated` 里注入一个和 Android 形态相同的 `window.MixinContext`。内部通过 `window.desktopWebview.postMessage(name, data)` 发给 Dart；Dart 侧用 `addJavaScriptHandler` 接收。

| 方法 | 桌面行为 |
|---|---|
| `getContext()` | **同步**返回 JSON。其余字段在注入脚本时预先算好；`appearance` 在调用时读 `prefers-color-scheme`，它跟随 `setBrightness`，主题切换后不用再注入脚本。字段：`app_version`、`immersive`、`appearance`、`platform: "Desktop"`、`locale`、`conversation_id`、`currency` |
| `reloadTheme()` | 见 5.3 |
| `close()` | `webview.close()` |
| `openInBrowser(url)` | 同步返回 `true`，然后用系统浏览器打开 |
| `showToast(text)` | 在 WebView 窗口里显示 toast。没有弹出层时可以先用主窗口的 toast，或者先不做 |
| `getAssets` / `getTipAddress` / `tipSign` / `signBotSignature` / `verifyPin` / Web3（`mixinwallet.*`、`_mw_`） | 桌面端目前没有 TIP 和钱包能力。**必须立即回调失败值**：Android 拒绝时回调的是 `cb('')`。不能让页面一直等着。`signBotSignature` 是否能用 session key 实现，待确认 |
| `playlist(urls)` | 不支持，静默忽略 |

安全要求：

- 回调函数名必须先校验是合法的 JS 标识符，参数一律用 `jsonEncode` 拼接，防止脚本注入。
- handler 现在会拿到 `origin`。将来支持签名或资产类方法时，只接受 `origin` 匹配该 app `resourcePatterns` 的 http(s) 页面，和移动端一致。

iOS 页面判断的是 `window.webkit.messageHandlers.MixinContext`。macOS 和 Linux 的 WebKit 都有 `window.webkit`，但不会注册这个 handler，页面应该会回落到 Android 形态的 `window.MixinContext`。**需要用真实 bot 页面验证。**

### 5.6 导航策略

通过 `setOnUrlRequestCallback` 实现。0.4.0 在三个平台都会把非 http 的 scheme 交给 Dart 判断：

| URL | 行为 |
|---|---|
| `mixin://`、外部转账链接、lightning 链接 | 取消导航，交给 flutter-app 现有的 URL 处理（和聊天里点链接一样）。同一个 URL 在 1 秒内重复触发时只处理一次（Android 也这样做） |
| WalletConnect 链接 | 取消导航；桌面端暂不支持 |
| http / https / file | 允许 |
| 其他 scheme（`mailto:`、`tel:` 等） | 取消导航，交给系统打开 |

- `target=_blank` 和 `window.open`：插件已经统一在当前窗口打开，并且会经过上面的判断。
- `Mixin-Conversation-ID` 请求头：Android 每次导航都会带上这个头，插件不支持自定义请求头。页面可以从 `getContext().conversation_id` 拿到会话 id，所以先不做。如果发现有 bot 依赖这个头，再向插件提需求。

### 5.7 页面行为（插件已提供，flutter-app 只需验收）

`alert` / `confirm`、`<input type=file>`、下载（会先询问保存位置）、右键菜单，三个平台都已支持，见插件 README 的 “Page dialogs, files and downloads” 一节。

- 摄像头和麦克风：使用平台默认行为。
- UA：沿用 `setApplicationNameForUserAgent(' Mixin/<version>')`。

### 5.8 窗口管理

- 同一个 bot 再次打开时，激活已有窗口，不新开一个：用 `nativeWindowHandle` 加窗口库实现 show 和 focus。
- 主窗口退出时，关闭所有 bot 窗口。

## 6. 插件能力对照

| 需求 | 插件 0.4.0 | 说明 |
|---|---|---|
| 去掉标题栏、拖拽区、胶囊、固定尺寸 | ✅ composer | flutter-app 在 runner 里实现 |
| `✕` 关闭 | ✅ `dww_browser_close` | |
| `•••` 事件传给 Dart，弹出 Flutter view | ✅ 允许 | runner 自建 channel；共享引擎的 view 由 flutter-app 负责 |
| JS bridge | ✅ `addScriptToExecuteOnDocumentCreated`、`addJavaScriptHandler`、`evaluateJavaScript` | handler 带 `origin` |
| theme-color | ✅ `evaluateJavaScript` 加 `navigationState` | |
| `mixin://` 等 scheme 交给 Dart | ✅ 三个平台一致 | |
| alert / confirm / 文件选择 / 下载 / 右键菜单 | ✅ | |
| 启动不闪 | ✅ `CreateConfiguration(brightness:)` | |
| 加载失败页 | ✅ `onLoadError` | 失败时可以显示重试 |
| 自定义请求头 `Mixin-Conversation-ID` | ❌ | 先不需要 |
| Linux X11 第二个 Flutter view | ❌ Flutter 上游问题 | 按 5.4 降级 |

**结论：这批需求不需要改插件。**

## 7. 风险

1. **flutter-app 根节点改成 multi-view**：macOS 上，部分插件默认假设只有 `registrar.view` 或 implicit view，切换后要回归主窗口的所有插件。Windows 的 `FlutterDesktopEngineCreateViewController` 还是演进中的 embedder API，Flutter 升级时需要复查。
2. **Windows 胶囊叠层**：layered 子窗口的 DPI 切换、窗口在多个显示器之间移动时的重绘，需要实机验证。
3. **Linux**：Wayland 上没有标题栏的窗口没有阴影；X11 只能用降级菜单。
4. **iOS 形态的页面**：只检测 `webkit.messageHandlers` 的页面，可能在 macOS 上走错分支。

## 8. 验收

- 三个平台各自打开以下页面：一个 IMMERSIVE bot（例如红包）、一个非沉浸式 bot、一个普通链接。检查：
  - 没有系统按钮；
  - 拖拽区能拖动窗口，双击没有反应；
  - 不能 resize，也不能最大化；
  - 胶囊的位置、尺寸和 light/dark 样式随 theme-color 正确切换。
- `•••`：
  - macOS、Windows、Wayland 上弹出共享引擎的 Flutter view，转发能选会话并发送 AppCard，刷新、关于都能用，授权菜单不显示，用户资料在 WebView 窗口内打开，转发选择器在主窗口打开；
  - 连续开关 20 次不崩、不泄漏；
  - 关闭窗口时 view 被销毁；
  - X11 上弹出降级菜单。
- 页面里点 `mixin://` 链接（转账、用户、app）能走 flutter-app 的处理逻辑；点 `mailto:` 能交给系统。
- `MixinContext.getContext()` 同步返回，且 `platform == "Desktop"`。签名和资产类方法立即回调失败值，页面不会挂起。
- `alert` / `confirm`、上传、下载在三个平台上都能用；macOS 沙盒包也要测。
