// swift-tools-version:5.9

import PackageDescription

let package = Package(name: "IntegralSwift",
                      platforms: [.iOS(.v15)],
                      products: [
                        .library(name: "IntegralSwift",
                                 targets: ["IntegralSwift"])
                      ],
                      dependencies: [],
                      targets: [
                        .target(name: "IntegralSwift",
                                dependencies: [],
                                resources: [
                                    .copy("Resources/PrivacyInfo.xcprivacy")
                                ]),
                        .testTarget(name: "IntegralSwiftTests",
                                    dependencies: ["IntegralSwift"])
                      ])
