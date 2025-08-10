import ProjectDescription

// Check if developer config exists
import Foundation
let developerConfigPath = Path("DeveloperConfig.xcconfig")
let configPath = FileManager.default.fileExists(atPath: developerConfigPath.pathString) ? developerConfigPath : nil

let project = Project(
    name: "Pergamene",
    settings: .settings(
        base: [
            "DEVELOPMENT_TEAM": "$(DEVELOPMENT_TEAM)",
            "CODE_SIGN_STYLE": "Automatic",
        ],
        configurations: [
            .debug(name: "Debug", settings: [:], xcconfig: configPath),
            .release(name: "Release", settings: [:], xcconfig: configPath)
        ]
    ),
    targets: [
        .target(
            name: "Pergamene",
            destinations: .iOS,
            product: .app,
            bundleId: "pm.moonlight.Pergamene",
            deploymentTargets: .iOS("15.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                    "UISupportedInterfaceOrientations": ["UIInterfaceOrientationPortrait"],
                    "UIRequiresFullScreen": true,
                    "CFBundleDisplayName": "Pergamene",
                    "CFBundleShortVersionString": "1.0.0",
                    "CFBundleVersion": "1",
                    "UIAppFonts": [
                        "Cardo-Regular.ttf",
                        "Cardo-Bold.ttf",
                        "Cardo-Italic.ttf",
                        "UnifrakturMaguntia-Book.ttf",
                        "MedievalSharp.ttf"
                    ]
                ]
            ),
            sources: ["Pergamene/Sources/**"],
            resources: ["Pergamene/Resources/**"],
            dependencies: [],
            settings: .settings(
                base: [
                    "CODE_SIGN_IDENTITY": "iPhone Developer",
                    "CODE_SIGN_STYLE": "Automatic",
                    "DEVELOPMENT_TEAM": "$(DEVELOPMENT_TEAM)",
                    "PROVISIONING_PROFILE_SPECIFIER": ""
                ]
            )
        ),
        .target(
            name: "PergameneTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "pm.moonlight.Pergamene.tests",
            deploymentTargets: .iOS("15.0"),
            infoPlist: .default,
            sources: ["Pergamene/Tests/**"],
            resources: [],
            dependencies: [.target(name: "Pergamene")]
        ),
        .target(
            name: "PergameneUITests",
            destinations: .iOS,
            product: .uiTests,
            bundleId: "pm.moonlight.Pergamene.uitests",
            deploymentTargets: .iOS("15.0"),
            infoPlist: .default,
            sources: ["Pergamene/Tests/PergameneUITests.swift"],
            resources: [],
            dependencies: [.target(name: "Pergamene")]
        ),
    ]
)
