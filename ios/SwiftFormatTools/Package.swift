// swift-tools-version:5.1
import PackageDescription

let package = Package(name: "SwiftFormatTools",
                      platforms: [.macOS(.v10_11)],
                      dependencies: [
                         .package(url: "https://github.com/nicklockwood/SwiftFormat",
                                  .exact("0.37.2")),
                      ],
                      targets: [.target(name: "SwiftFormatTools", path: "")])
