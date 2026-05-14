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
      checksum: "21469d8ff910d4b68c43d23e1fa7ca709ee44d40f766d654b83da732a9591c86"
    )
  ]
)
