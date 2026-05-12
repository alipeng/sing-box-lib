// swift-tools-version: 5.7

import PackageDescription

let package = Package(
  name: "Libbox",
  platforms: [.iOS(.v12)],
  products: [
    .library(name: "Libbox", targets: ["Libbox"]),
  ],
  targets: [
    .binaryTarget(
      name: "Libbox",
      url: "https://github.com/alipeng/sing-box-lib/releases/download/1.13.11/Libbox.xcframework.zip",
      checksum: "987257404ca24fd552a1e109a562d13c9ef8912c4e8a732f09068921208a257e"
    )
  ]
)
