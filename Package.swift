// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Menuminder",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "Menuminder", targets: ["Menuminder"])
    ],
    targets: [
        .executableTarget(
            name: "Menuminder",
            path: "Sources/Menuminder",
            resources: [.copy("Assets")]
        )
    ]
)
