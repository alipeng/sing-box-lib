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
      url: "https://github.com/alipeng/sing-box-lib/releases/download/1.13.12/Libbox.xcframework.zip",
      checksum: "0c663447b3493b59e2494e7e52b7c08f224c73320f2c4f7f33d7259c0431172d"
    )
  ]
)
