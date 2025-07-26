//
//  Packege.swift
//  yandex_project
//
//  Created by ulwww on 26.07.25.
//

import PackageDescription

let package = Package(
    name: "yandex_project",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .executable(name: "yandex_project", targets: ["AppModule"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/airbnb/lottie-ios.git",
            from: "4.2.0"
        )
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            dependencies: [
                .product(name: "Lottie", package: "lottie-ios")
            ],
            path: ".",
            exclude: ["Package.swift"],
            resources: [
                .process("Resources/LaunchScreen.storyboard"),
                .process("Resources/splash.json")
            ]
        )
    ]
)
