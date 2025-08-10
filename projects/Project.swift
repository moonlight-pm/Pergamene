import ProjectDescription

let project = Project(
    name: "Pergamene",
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
                        "UnifrakturMaguntia-Regular.ttf",
                        "MedievalSharp.ttf"
                    ]
                ]
            ),
            sources: ["Pergamene/Sources/**"],
            resources: ["Pergamene/Resources/**"],
            dependencies: []
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
    ]
)
