//
//  PlatformMenuChannel.swift
//  Runner
//
//  Created by Bin Yang on 2022/5/12.
//  Copyright © 2022 The Flutter Authors. All rights reserved.
//

import Cocoa
import FlutterMacOS
import Foundation

class PlatformMenuPlugin: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "mixin_desktop/platform_menus", binaryMessenger: registrar.messenger)
    let instance = PlatformMenuPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "showAbout":
      NSApplication.shared.orderFrontStandardAboutPanel()
      result(nil)
    case "showEmojiAndSymbols":
      NSApplication.shared.orderFrontCharacterPalette(nil)
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
