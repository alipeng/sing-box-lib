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
      url: "https://github.com/alipeng/sing-box-lib/releases/download/1.13.11-fix/Libbox.xcframework.zip",
      checksum: "02e43efd9a9e1ac3a5f8b747656ec80474aa88723324b546dad535f2e544c2d0"
    )
  ]
)
