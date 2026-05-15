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
      url: "https://github.com/alipeng/sing-box-lib/releases/download/1.13.11-fix4/Libbox.xcframework.zip",
      checksum: "ea0c15aa65d099d845f600b006d70d5875e49f7a5f27a2d403e3fee708de00a0"
    )
  ]
)
