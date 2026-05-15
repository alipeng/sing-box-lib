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
      url: "https://github.com/alipeng/sing-box-lib/releases/download/v1.13.11/Libbox.xcframework.zip",
      checksum: "af89b29c4bca032f75bda3f470565ee8baec3bc08373a40db70fa8c1c9828506"
    )
  ]
)
