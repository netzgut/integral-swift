// swift-tools-version:5.3

import PackageDescription

let package = Package(name: "IntegralSwift",
                      platforms: [.iOS(.v11)],
                      products: [
                          .library(name: "IntegralSwift",
                                   targets: ["IntegralSwift"])
                      ],
                      dependencies: [],
                      targets: [
                          .target(name: "IntegralSwift",
                                  dependencies: []),
                          .testTarget(name: "IntegralSwiftTests",
                                      dependencies: ["IntegralSwift"])
                      ])
