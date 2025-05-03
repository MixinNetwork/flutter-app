// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
//  Generated file. Do not edit.
//

import PackageDescription

let package = Package(
    name: "FlutterGeneratedPluginSwiftPackage",
    platforms: [
        .iOS("12.0")
    ],
    products: [
        .library(name: "FlutterGeneratedPluginSwiftPackage", type: .static, targets: ["FlutterGeneratedPluginSwiftPackage"])
    ],
    dependencies: [
        .package(name: "audio_session", path: "/Users/yangbin/.pub-cache/hosted/pub.dev/audio_session-0.2.1/ios/audio_session"),
        .package(name: "file_picker", path: "/Users/yangbin/.pub-cache/hosted/pub.dev/file_picker-10.1.2/ios/file_picker"),
        .package(name: "file_selector_ios", path: "/Users/yangbin/.pub-cache/hosted/pub.dev/file_selector_ios-0.5.3+1/ios/file_selector_ios"),
        .package(name: "flutter_local_notifications", path: "/Users/yangbin/.pub-cache/hosted/pub.dev/flutter_local_notifications-19.1.0/ios/flutter_local_notifications"),
        .package(name: "image_picker_ios", path: "/Users/yangbin/.pub-cache/hosted/pub.dev/image_picker_ios-0.8.12+1/ios/image_picker_ios"),
        .package(name: "local_auth_darwin", path: "/Users/yangbin/.pub-cache/hosted/pub.dev/local_auth_darwin-1.4.2/darwin/local_auth_darwin"),
        .package(name: "network_info_plus", path: "/Users/yangbin/.pub-cache/hosted/pub.dev/network_info_plus-6.1.4/ios/network_info_plus"),
        .package(name: "package_info_plus", path: "/Users/yangbin/.pub-cache/hosted/pub.dev/package_info_plus-8.3.0/ios/package_info_plus"),
        .package(name: "path_provider_foundation", path: "/Users/yangbin/.pub-cache/hosted/pub.dev/path_provider_foundation-2.4.1/darwin/path_provider_foundation"),
        .package(name: "sentry_flutter", path: "/Users/yangbin/.pub-cache/hosted/pub.dev/sentry_flutter-8.14.2/ios/sentry_flutter"),
        .package(name: "sqlite3_flutter_libs", path: "/Users/yangbin/.pub-cache/hosted/pub.dev/sqlite3_flutter_libs-0.5.32/darwin/sqlite3_flutter_libs"),
        .package(name: "url_launcher_ios", path: "/Users/yangbin/.pub-cache/hosted/pub.dev/url_launcher_ios-6.3.2/ios/url_launcher_ios"),
        .package(name: "video_player_avfoundation", path: "/Users/yangbin/.pub-cache/hosted/pub.dev/video_player_avfoundation-2.6.5/darwin/video_player_avfoundation"),
        .package(name: "webview_flutter_wkwebview", path: "/Users/yangbin/.pub-cache/hosted/pub.dev/webview_flutter_wkwebview-3.20.0/darwin/webview_flutter_wkwebview")
    ],
    targets: [
        .target(
            name: "FlutterGeneratedPluginSwiftPackage",
            dependencies: [
                .product(name: "audio-session", package: "audio_session"),
                .product(name: "file-picker", package: "file_picker"),
                .product(name: "file-selector-ios", package: "file_selector_ios"),
                .product(name: "flutter-local-notifications", package: "flutter_local_notifications"),
                .product(name: "image-picker-ios", package: "image_picker_ios"),
                .product(name: "local-auth-darwin", package: "local_auth_darwin"),
                .product(name: "network-info-plus", package: "network_info_plus"),
                .product(name: "package-info-plus", package: "package_info_plus"),
                .product(name: "path-provider-foundation", package: "path_provider_foundation"),
                .product(name: "sentry-flutter", package: "sentry_flutter"),
                .product(name: "sqlite3-flutter-libs", package: "sqlite3_flutter_libs"),
                .product(name: "url-launcher-ios", package: "url_launcher_ios"),
                .product(name: "video-player-avfoundation", package: "video_player_avfoundation"),
                .product(name: "webview-flutter-wkwebview", package: "webview_flutter_wkwebview")
            ]
        )
    ]
)
