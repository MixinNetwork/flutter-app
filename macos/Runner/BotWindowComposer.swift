import Cocoa
import FlutterMacOS
import desktop_webview_window

/// Lays out the app's browser windows like the mobile web view: no system
/// title bar, the `••• | ✕` capsule, and either a title row or, for immersive
/// pages, a strip to drag the window. `•••` asks Dart to show its menu in a
/// Flutter view that shares the main engine.
enum BotWindowComposer {
  private static let dragHeight: CGFloat = 28
  private static let titleRowHeight: CGFloat = 48

  private static var windows: [Int64: BotWindow] = [:]
  private static var channel: FlutterMethodChannel?
  private static weak var engine: FlutterEngine?
  private static var multiViewEnabled = false

  static func install(controller: FlutterViewController) {
    engine = controller.engine
    let channel = FlutterMethodChannel(
      name: "one.mixin/bot_window", binaryMessenger: controller.engine.binaryMessenger)
    channel.setMethodCallHandler(handle)
    self.channel = channel

    var composer = DWWComposer(
      user: nil,
      compose: { _, request in BotWindowComposer.compose(request!.pointee) },
      navigation_changed: { _, state in BotWindowComposer.navigationChanged(state!.pointee) },
      layout: nil,
      closing: { _, browser in BotWindowComposer.closing(browser) })
    dww_set_composer(&composer)
  }

  private static func compose(_ request: DWWComposeRequest) -> DWWComposeResult {
    // Base64 of a standard-codec map.
    guard let raw = request.arguments,
          let data = Data(base64Encoded: String(cString: raw)),
          let arguments = FlutterStandardMessageCodec.sharedInstance().decode(data)
            as? [String: Any] else {
      return DWW_COMPOSE_DEFAULT
    }
    let window = Unmanaged<NSWindow>.fromOpaque(request.window).takeUnretainedValue()
    let webView = Unmanaged<NSView>.fromOpaque(request.webview_view).takeUnretainedValue()
    windows[request.browser] = BotWindow(
      browser: request.browser, window: window, webView: webView, arguments: arguments)
    return DWW_COMPOSE_HANDLED
  }

  private static func navigationChanged(_ state: DWWNavigationState) {
    windows[state.browser]?.navigationChanged(state)
  }

  private static func closing(_ browser: Int64) {
    windows.removeValue(forKey: browser)?.tearDown()
  }

  private static func handle(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let browser = (args["browserId"] as? NSNumber)?.int64Value,
          let window = windows[browser] else {
      result(FlutterError(code: "no_window", message: "Unknown browser window", details: nil))
      return
    }
    switch call.method {
    case "setChrome":
      window.setChrome(args)
      result(nil)
    case "showPopup":
      guard let engine = engine, enableMultiView(engine) else {
        result(FlutterError(
          code: "unsupported", message: "This Flutter engine cannot add views", details: nil))
        return
      }
      result(window.showPopup(engine: engine))
    case "hidePopup":
      window.hidePopup()
      result(nil)
    case "focus":
      window.focus()
      result(true)
    #if DEBUG
    case "debugProbe":
      result(window.debugProbe(points: args["points"] as? [[Double]] ?? []))
    case "debugMouse":
      let type = args["type"] as? String ?? ""
      let x = args["x"] as? Double ?? 0
      let y = args["y"] as? Double ?? 0
      // Flutter drops a hover where the pointer was just added: the move
      // needs a step before the point.
      if type == "moved" { window.debugMouse(type: type, x: x - 1, y: y) }
      window.debugMouse(type: type, x: x, y: y)
      result(nil)
    #endif
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  fileprivate static func moreTapped(_ browser: Int64) {
    channel?.invokeMethod("onMoreTapped", arguments: ["browserId": browser])
  }

  /// Dart hides the menu, then the popup through hidePopup.
  fileprivate static func dismissPopup(_ browser: Int64) {
    channel?.invokeMethod("onDismissPopup", arguments: ["browserId": browser])
  }

  /// FlutterMacOS adds views only to engines in multi-view mode, and its
  /// enableMultiView requires no view yet. Turning the same flag on after the
  /// main view keeps it the implicit view, which runApp and plugins using
  /// `registrar.view` rely on; later views get IDs from 1. The flag is private
  /// (checked against Flutter 3.47.7); without it the sheet is unavailable.
  private static func enableMultiView(_ engine: FlutterEngine) -> Bool {
    if multiViewEnabled { return true }
    guard let ivar = class_getInstanceVariable(FlutterEngine.self, "_multiViewEnabled"),
          let encoding = ivar_getTypeEncoding(ivar),
          ["B", "c"].contains(String(cString: encoding)) else {
      NSLog("BotWindowComposer: FlutterEngine has no _multiViewEnabled flag")
      return false
    }
    Unmanaged.passUnretained(engine).toOpaque()
      .advanced(by: ivar_getOffset(ivar))
      .storeBytes(of: 1, as: UInt8.self)
    multiViewEnabled = true
    return true
  }

  private final class BotWindow {
    let browser: Int64
    let followsPageTitle: Bool
    private weak var window: NSWindow?
    private let webView: NSView
    private let header = HeaderView()
    private let capsule: CapsuleView
    private let titleLabel = NSTextField(labelWithString: "")
    private let leading: LeadingView
    private var popup: PopupHostView?
    private var popupConstraints: [NSLayoutConstraint] = []
    private var canGoBack = false
    private var canGoForward = false
    private var eventMonitor: Any?
    private var resizeObserver: NSObjectProtocol?

    init(browser: Int64, window: NSWindow, webView: NSView, arguments: [String: Any]) {
      self.browser = browser
      self.window = window
      self.webView = webView
      followsPageTitle = arguments["followPageTitle"] as? Bool ?? false
      capsule = CapsuleView(
        onMore: { BotWindowComposer.moreTapped(browser) },
        onClose: { _ = dww_browser_close(browser) })
      leading = LeadingView(showsIcon: arguments["showIcon"] as? Bool ?? false) {
        _ = dww_browser_go_back(browser)
      }
      let immersive = arguments["immersive"] as? Bool ?? false

      // The requested size includes the header.
      let size = window.contentView?.frame.size ?? window.frame.size
      window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
      window.titlebarAppearsTransparent = true
      window.titleVisibility = .hidden
      window.acceptsMouseMovedEvents = true
      window.collectionBehavior.insert(.fullScreenNone)
      for button: NSWindow.ButtonType in [.closeButton, .miniaturizeButton, .zoomButton] {
        window.standardWindowButton(button)?.isHidden = true
      }
      window.setContentSize(size)
      // The size the window opens with is also the smallest it gets.
      window.contentMinSize = size

      let root = window.contentView!
      for view in [header, webView, capsule] {
        // Views draw past their bounds unless clipped (macOS 14), and the
        // page's background would cover the header.
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(view)
      }
      // The title row is dragged like the strip, so it needs no strip above.
      let headerHeight = immersive ? dragHeight : titleRowHeight
      NSLayoutConstraint.activate([
        header.topAnchor.constraint(equalTo: root.topAnchor),
        header.leadingAnchor.constraint(equalTo: root.leadingAnchor),
        header.trailingAnchor.constraint(equalTo: root.trailingAnchor),
        header.heightAnchor.constraint(equalToConstant: headerHeight),
        webView.topAnchor.constraint(equalTo: header.bottomAnchor),
        webView.leadingAnchor.constraint(equalTo: root.leadingAnchor),
        webView.trailingAnchor.constraint(equalTo: root.trailingAnchor),
        webView.bottomAnchor.constraint(equalTo: root.bottomAnchor),
        // Over the page 6 below the strip, or centred in the title row.
        capsule.topAnchor.constraint(
          equalTo: root.topAnchor, constant: immersive ? dragHeight + 6 : (titleRowHeight - 32) / 2),
        capsule.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -6),
        capsule.widthAnchor.constraint(equalToConstant: 88),
        capsule.heightAnchor.constraint(equalToConstant: 32),
      ])

      if !immersive {
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.lineBreakMode = .byTruncatingTail
        // Immersive pages have no row and offer going back themselves.
        let row = NSStackView(views: [leading, titleLabel])
        row.spacing = 8
        // A long title truncates instead of widening the window.
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        row.setClippingResistancePriority(.defaultLow, for: .horizontal)
        row.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(row)
        NSLayoutConstraint.activate([
          leading.widthAnchor.constraint(equalToConstant: 24),
          leading.heightAnchor.constraint(equalToConstant: 24),
          row.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 12),
          row.trailingAnchor.constraint(
            lessThanOrEqualTo: header.trailingAnchor, constant: -(88 + 6 + 8)),
          row.centerYAnchor.constraint(equalTo: header.centerYAnchor),
        ])
        leading.isHidden = !leading.showsIcon
      }

      // ⌘[ and ⌘], and the mouse's back and forward buttons, navigate in
      // every layout.
      eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .otherMouseUp]) {
        [weak self] event in
        guard let self = self, event.window === self.window,
              self.popup?.isHidden ?? true else { return event }
        let forward: Bool
        if event.type == .keyDown {
          guard event.modifierFlags.intersection(.deviceIndependentFlagsMask) == .command,
                let key = event.charactersIgnoringModifiers, key == "[" || key == "]"
          else { return event }
          forward = key == "]"
        } else {
          guard event.buttonNumber == 3 || event.buttonNumber == 4 else { return event }
          forward = event.buttonNumber == 4
        }
        if forward {
          guard self.canGoForward else { return event }
          _ = dww_browser_go_forward(self.browser)
        } else {
          guard self.canGoBack else { return event }
          _ = dww_browser_go_back(self.browser)
        }
        return nil
      }

      // The menu hangs from where the capsule was when it opened.
      resizeObserver = NotificationCenter.default.addObserver(
        forName: NSWindow.didResizeNotification, object: window, queue: nil
      ) { [weak self] _ in
        guard let self = self, !(self.popup?.isHidden ?? true) else { return }
        BotWindowComposer.dismissPopup(self.browser)
      }

      setTitle(arguments["title"] as? String ?? "")
      setChrome(arguments)
    }

    func navigationChanged(_ state: DWWNavigationState) {
      canGoBack = state.can_go_back != 0
      canGoForward = state.can_go_forward != 0
      leading.setCanGoBack(canGoBack)
      if followsPageTitle { setTitle(state.title.map { String(cString: $0) } ?? "") }
    }

    func setTitle(_ title: String) {
      titleLabel.stringValue = title
      window?.title = title
    }

    func setChrome(_ args: [String: Any]) {
      if let value = (args["backgroundColor"] as? NSNumber)?.uint32Value {
        let color = NSColor(argb: value)
        header.color = color
        window?.backgroundColor = color
      }
      if let dark = args["dark"] as? Bool {
        capsule.dark = dark
        titleLabel.textColor = dark ? .white : .black
        leading.dark = dark
      }
      if let icon = (args["icon"] as? FlutterStandardTypedData)?.data,
         let image = NSImage(data: icon) {
        leading.icon = image
      }
    }

    /// Returns the Flutter view ID and the capsule's frame, top-left based,
    /// for the menu to hang from. The view is created on first use, then
    /// hidden and reused until the window closes.
    func showPopup(engine: FlutterEngine) -> Any? {
      let host = popup ?? {
        let controller = FlutterViewController(engine: engine, nibName: nil, bundle: nil)
        controller.backgroundColor = .clear
        let host = PopupHostView(controller: controller)
        // Covers the whole window, above the header, page and capsule, so
        // the menu's barrier blocks all of them.
        if let root = window?.contentView {
          root.addSubview(host)
          popupConstraints = [
            host.topAnchor.constraint(equalTo: root.topAnchor),
            host.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            host.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            host.bottomAnchor.constraint(equalTo: root.bottomAnchor),
          ]
        }
        popup = host
        return host
      }()
      host.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate(popupConstraints)
      window?.contentView?.layoutSubtreeIfNeeded()
      host.isHidden = false
      window?.makeFirstResponder(host.controller.view)
      let anchor = capsule.frame
      let height = window?.contentView?.bounds.height ?? 0
      return [
        "viewId": host.controller.value(forKey: "viewIdentifier") as Any,
        "anchor": [anchor.minX, height - anchor.maxY, anchor.width, anchor.height],
      ]
    }

    func hidePopup() {
      guard let popup = popup, !popup.isHidden else { return }
      popup.isHidden = true
      // A Flutter view waits for a frame at each new size, which would stall
      // every step of a resize or zoom; the hidden view keeps its size.
      NSLayoutConstraint.deactivate(popupConstraints)
      popup.autoresizingMask = []
      popup.translatesAutoresizingMaskIntoConstraints = true
      window?.makeFirstResponder(webView)
    }

    #if DEBUG
    /// For integration tests; the same on every platform. Points are
    /// top-left based, in window content coordinates. Reports what takes a
    /// click at each point, and the pixel drawn there by the whole window,
    /// title bar container included.
    func debugProbe(points: [[Double]]) -> [String: Any] {
      guard let root = window?.contentView, let frameView = root.superview else { return [:] }
      let bitmap = frameView.bitmapImageRepForCachingDisplay(in: frameView.bounds)?
        .retagging(with: .sRGB)
      if let bitmap = bitmap { frameView.cacheDisplay(in: frameView.bounds, to: bitmap) }
      let probes: [[String: Any]] = points.map { point in
        let local = NSPoint(x: point[0], y: root.bounds.height - point[1])
        let inFrame = root.convert(local, to: frameView)
        var probe: [String: Any] = [
          "hit": debugRole(frameView.hitTest(inFrame)),
        ]
        if let bitmap = bitmap {
          let scale = CGFloat(bitmap.pixelsWide) / frameView.bounds.width
          let color = bitmap.colorAt(
            x: Int(inFrame.x * scale), y: Int((frameView.bounds.height - inFrame.y) * scale))
          probe["color"] = color?.usingColorSpace(.sRGB)?.argb ?? 0
        }
        return probe
      }
      return [
        "probes": probes,
        "headerColor": header.color.usingColorSpace(.sRGB)?.argb ?? 0,
        "popupHidden": popup?.isHidden ?? true,
        "popupOrigin": popup.map { [Double($0.frame.minX), Double(root.bounds.height - $0.frame.maxY)] }
          ?? [0.0, 0.0],
        "leading": leading.debugState,
        "width": Double(root.bounds.width),
        "firstResponder": window?.firstResponder.map { String(describing: type(of: $0)) } ?? "nil",
        "isKey": window?.isKeyWindow ?? false,
      ]
    }

    private func debugRole(_ view: NSView?) -> String {
      switch view {
      case nil: return "nil"
      case is PopupHostView: return "popup"
      case is CapsuleView: return "capsule"
      case is LeadingView: return "leading"
      case is HeaderView: return "header"
      case let view? where view.isDescendant(of: webView): return "page"
      case let view?: return String(describing: type(of: view))
      }
    }

    /// Delivers a synthetic mouse event through NSWindow.sendEvent, so it
    /// takes the same route as a real one without needing the window in
    /// front.
    func debugMouse(type: String, x: Double, y: Double) {
      guard let window = window, let root = window.contentView else { return }
      let point = root.convert(NSPoint(x: x, y: root.bounds.height - y), to: nil)
      let eventType: NSEvent.EventType
      switch type {
      case "down": eventType = .leftMouseDown
      case "up": eventType = .leftMouseUp
      default: eventType = .mouseMoved
      }
      guard let event = NSEvent.mouseEvent(
        with: eventType, location: point, modifierFlags: [],
        timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: window.windowNumber,
        context: nil, eventNumber: 0, clickCount: eventType == .mouseMoved ? 0 : 1,
        pressure: eventType == .leftMouseDown ? 1 : 0) else { return }
      window.sendEvent(event)
    }
    #endif

    func focus() {
      NSApp.activate(ignoringOtherApps: true)
      window?.makeKeyAndOrderFront(nil)
    }

    func tearDown() {
      if let monitor = eventMonitor { NSEvent.removeMonitor(monitor) }
      eventMonitor = nil
      if let observer = resizeObserver { NotificationCenter.default.removeObserver(observer) }
      resizeObserver = nil
      // Releasing the controller removes its view from the engine.
      popup?.removeFromSuperview()
      popup = nil
    }
  }

  /// Hosts a popup's Flutter view. In a window that is not the engine's
  /// main window, AppKit's default forwarding from the Flutter view never
  /// reaches its controller, so button and scroll events are taken here and
  /// handed to the controller, including moves used for Flutter hover states.
  private final class PopupHostView: NSView {
    let controller: FlutterViewController

    init(controller: FlutterViewController) {
      self.controller = controller
      super.init(frame: .zero)
      let view = controller.view
      view.frame = bounds
      view.autoresizingMask = [.width, .height]
      addSubview(view)
    }

    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
      !isHidden && frame.contains(point) ? self : nil
    }

    override var mouseDownCanMoveWindow: Bool { false }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseDown(with event: NSEvent) { controller.mouseDown(with: event) }
    override func mouseMoved(with event: NSEvent) { controller.mouseMoved(with: event) }
    override func mouseUp(with event: NSEvent) { controller.mouseUp(with: event) }
    override func mouseDragged(with event: NSEvent) { controller.mouseDragged(with: event) }
    override func rightMouseDown(with event: NSEvent) { controller.rightMouseDown(with: event) }
    override func rightMouseUp(with event: NSEvent) { controller.rightMouseUp(with: event) }
    override func rightMouseDragged(with event: NSEvent) {
      controller.rightMouseDragged(with: event)
    }
    override func otherMouseDown(with event: NSEvent) { controller.otherMouseDown(with: event) }
    override func otherMouseUp(with event: NSEvent) { controller.otherMouseUp(with: event) }
    override func otherMouseDragged(with event: NSEvent) {
      controller.otherMouseDragged(with: event)
    }
    override func scrollWheel(with event: NSEvent) { controller.scrollWheel(with: event) }
    override func magnify(with event: NSEvent) { controller.magnify(with: event) }
    override func rotate(with event: NSEvent) { controller.rotate(with: event) }
  }

  /// The drag strip and title row. Double-clicks act like the title bar's.
  private final class HeaderView: NSView {
    var color: NSColor = .windowBackgroundColor {
      didSet { needsDisplay = true }
    }

    override var mouseDownCanMoveWindow: Bool { false }

    // The icon and title drag the window too; only `‹` takes clicks.
    override func hitTest(_ point: NSPoint) -> NSView? {
      let hit = super.hitTest(point)
      return hit is LeadingView || hit == nil ? hit : self
    }

    override func draw(_ dirtyRect: NSRect) {
      color.setFill()
      dirtyRect.fill()
    }

    override func mouseDown(with event: NSEvent) {
      if event.clickCount == 1 {
        window?.performDrag(with: event)
      } else if event.clickCount == 2 {
        // System Settings > Desktop & Dock > Double-click a window's title bar.
        switch UserDefaults.standard.string(forKey: "AppleActionOnDoubleClick") {
        case "Minimize": window?.miniaturize(nil)
        case "None": break
        default: window?.zoom(nil)
        }
      }
    }
  }

  /// The 24 × 24 slot before the title: the bot's icon, which turns into `‹`
  /// while the page can go back. Pages without an icon show the slot only
  /// for `‹`.
  private final class LeadingView: NSView {
    let showsIcon: Bool
    private let onBack: () -> Void
    private let iconView = NSImageView()
    private let backView = NSImageView()
    private var canGoBack = false
    private var hovered = false

    var icon: NSImage? {
      get { iconView.image }
      set {
        iconView.image = newValue
        updateColors()
      }
    }

    var dark = false {
      didSet { updateColors() }
    }

    init(showsIcon: Bool, onBack: @escaping () -> Void) {
      self.showsIcon = showsIcon
      self.onBack = onBack
      super.init(frame: .zero)
      wantsLayer = true
      layer?.cornerRadius = 12
      layer?.masksToBounds = true
      addSubview(iconView)
      addSubview(backView)
      iconView.imageScaling = .scaleProportionallyUpOrDown
      backView.image = NSImage(systemSymbolName: "chevron.backward", accessibilityDescription: "Back")?
        .withSymbolConfiguration(.init(pointSize: 15, weight: .semibold))
      backView.alphaValue = 0
      iconView.isHidden = !showsIcon
      updateColors()
    }

    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    // Autoresizing would grow the views by the slot's own growth from zero.
    override func layout() {
      super.layout()
      iconView.frame = bounds
      backView.frame = bounds
    }

    func setCanGoBack(_ value: Bool) {
      guard value != canGoBack else { return }
      canGoBack = value
      NSAnimationContext.runAnimationGroup { context in
        context.duration = 0.15
        context.allowsImplicitAnimation = true
        iconView.animator().alphaValue = value ? 0 : 1
        backView.animator().alphaValue = value ? 1 : 0
        if !showsIcon {
          isHidden = !value
          superview?.layoutSubtreeIfNeeded()
        }
      }
      updateColors()
    }

    private func updateColors() {
      backView.contentTintColor = dark ? .white : .black
      let fill: NSColor
      if canGoBack {
        fill = hovered ? NSColor(argb: dark ? 0x26FF_FFFF : 0x14000000) : .clear
      } else {
        // Holds the icon's place until it loads, or if it never does.
        fill = showsIcon && iconView.image == nil
          ? NSColor(argb: dark ? 0x26FF_FFFF : 0x14000000) : .clear
      }
      layer?.backgroundColor = fill.cgColor
    }

    #if DEBUG
    var debugState: [String: Any] {
      [
        "shown": !isHidden, "hasIcon": iconView.image != nil,
        // Once its fade-in completes.
        "back": backView.alphaValue == 1,
      ]
    }
    #endif

    override func updateTrackingAreas() {
      super.updateTrackingAreas()
      trackingAreas.forEach(removeTrackingArea)
      addTrackingArea(NSTrackingArea(
        rect: bounds, options: [.mouseEnteredAndExited, .activeAlways], owner: self))
    }

    override func mouseEntered(with event: NSEvent) {
      hovered = true
      updateColors()
    }

    override func mouseExited(with event: NSEvent) {
      hovered = false
      updateColors()
    }

    override var mouseDownCanMoveWindow: Bool { false }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func hitTest(_ point: NSPoint) -> NSView? {
      canGoBack ? super.hitTest(point).map { _ in self } : nil
    }

    override func mouseDown(with event: NSEvent) {}

    override func mouseUp(with event: NSEvent) {
      if canGoBack, bounds.contains(convert(event.locationInWindow, from: nil)) { onBack() }
    }
  }

  /// `••• | ✕`, 88 × 32, styled like Android's WebControlView.
  private final class CapsuleView: NSView {
    private let onMore: () -> Void
    private let onClose: () -> Void
    private var pressed: Bool?  // true: •••, false: ✕

    var dark = false {
      didSet { needsDisplay = true }
    }

    init(onMore: @escaping () -> Void, onClose: @escaping () -> Void) {
      self.onMore = onMore
      self.onClose = onClose
      super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    override var isFlipped: Bool { true }
    override var mouseDownCanMoveWindow: Bool { false }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func draw(_ dirtyRect: NSRect) {
      let rect = bounds.insetBy(dx: 0.5, dy: 0.5)
      let shape = NSBezierPath(roundedRect: rect, xRadius: rect.height / 2, yRadius: rect.height / 2)
      NSColor(argb: dark ? 0xFF24_262A : 0xC7F9_F9F9).setFill()
      shape.fill()
      NSColor(argb: dark ? 0x0FFF_FFFF : 0x0F00_0000).setStroke()
      shape.lineWidth = 1
      shape.stroke()

      let half = bounds.width / 2
      if let pressed = pressed {
        NSGraphicsContext.saveGraphicsState()
        NSBezierPath(rect: NSRect(x: pressed ? 0 : half, y: 0, width: half, height: bounds.height))
          .addClip()
        NSColor(argb: dark ? 0x1FFF_FFFF : 0x1400_0000).setFill()
        shape.fill()
        NSGraphicsContext.restoreGraphicsState()
      }

      NSColor(argb: dark ? 0x33FF_FFFF : 0x1F00_0000).setFill()
      NSRect(x: half - 0.5, y: 8, width: 1, height: bounds.height - 16).fill()

      let icon: NSColor = dark ? .white : .black
      icon.setFill()
      let center = NSPoint(x: half / 2, y: bounds.midY)
      for dx: CGFloat in [-6, 0, 6] {
        NSBezierPath(ovalIn: NSRect(x: center.x + dx - 1.75, y: center.y - 1.75, width: 3.5, height: 3.5))
          .fill()
      }
      icon.setStroke()
      let cross = NSBezierPath()
      let c = NSPoint(x: half * 1.5, y: bounds.midY)
      cross.move(to: NSPoint(x: c.x - 5, y: c.y - 5))
      cross.line(to: NSPoint(x: c.x + 5, y: c.y + 5))
      cross.move(to: NSPoint(x: c.x + 5, y: c.y - 5))
      cross.line(to: NSPoint(x: c.x - 5, y: c.y + 5))
      cross.lineWidth = 1.6
      cross.lineCapStyle = .round
      cross.stroke()
    }

    private func isMore(_ event: NSEvent) -> Bool {
      convert(event.locationInWindow, from: nil).x < bounds.width / 2
    }

    override func mouseDown(with event: NSEvent) {
      pressed = isMore(event)
      needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
      let target = pressed
      pressed = nil
      needsDisplay = true
      guard let target = target, bounds.contains(convert(event.locationInWindow, from: nil)),
            isMore(event) == target else { return }
      // Last: closing removes this view.
      target ? onMore() : onClose()
    }
  }
}

private extension NSColor {
  var argb: UInt32 {
    func channel(_ value: CGFloat) -> UInt32 { UInt32((value * 255).rounded()) }
    return channel(alphaComponent) << 24 | channel(redComponent) << 16
      | channel(greenComponent) << 8 | channel(blueComponent)
  }

  convenience init(argb: UInt32) {
    self.init(
      srgbRed: CGFloat((argb >> 16) & 0xFF) / 255,
      green: CGFloat((argb >> 8) & 0xFF) / 255,
      blue: CGFloat(argb & 0xFF) / 255,
      alpha: CGFloat(argb >> 24) / 255)
  }
}
