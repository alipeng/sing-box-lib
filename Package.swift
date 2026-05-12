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
      checksum: "2a8fccb801466c2f1ebdfe7e641837bd85cf39e241c2423adc55d58fbd23c3c5"
    )
  ]
)
