// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "SaaSquatch",
    platforms: [ .iOS(.v13) ],
    products: [
        .library(name: "SaaSquatch", targets: ["SaaSquatch"]),
        .library(name: "SaaSquatchWebView", targets: ["SaaSquatchWebView"])
    ],
    dependencies: [
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "4.0.0"),
    ],
    targets: [
        .target(name: "SaaSquatch", dependencies: [
            "SwiftyJSON",
        ]),
        .target(name: "SaaSquatchWebView", dependencies: [
            "SaaSquatch",
            "SwiftyJSON",
        ]),
        .testTarget(name: "SaaSquatchTests", dependencies: ["SaaSquatch"]),
    ]
)
