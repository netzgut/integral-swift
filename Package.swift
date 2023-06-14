// swift-tools-version:5.8

import PackageDescription

let package = Package(name: "IntegralSwift",
                      platforms: [.iOS(.v12)],
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
