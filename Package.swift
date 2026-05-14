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
      url: "https://github.com/alipeng/sing-box-lib/releases/download/1.13.11-fix3/Libbox.xcframework.zip",
      checksum: "9924acaa7e9d6b890cd4c097d783d75df6786862f983b67a90decb051cc44c01"
    )
  ]
)
