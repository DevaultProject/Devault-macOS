import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.project(
    name: DVModule.Devault.name,
    targets: [
        .target(
            name: DVModule.Devault.name,
            product: .app,
            bundleId: "com.devault.app",
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": .string("Devault"),
                "NSFaceIDUsageDescription": .string("저장된 시크릿을 안전하게 보호하기 위해 Touch ID를 사용합니다."),
            ]),
            sources: .sources,
            resources: [.glob(pattern: "Resources/**", excluding: ["Resources/*.entitlements"])],
            entitlements: .file(path: "Resources/Devault.entitlements"),
            dependencies: [
                // internal dependency
                .presentation(),
                .data(),
                .domain(),
                .core(),

                // 3rd-party dependency
                .tca(),
            ],
            settings: .settings(base: [
                "DEVELOPMENT_TEAM": "UKY6HK6U6Y",
                "ASSETCATALOG_COMPILER_APPICON_NAME": "Devault_IC",
            ])
        ),
    ],
    schemes: [
        .scheme(
            name: DVModule.Devault.name,
            buildAction: .buildAction(targets: [.target(DVModule.Devault.name)]),
            runAction: .runAction(
                executable: .target(DVModule.Devault.name),
                arguments: .arguments(
                    launchArguments: [
                        .launchArgument(name: "-com.apple.CoreData.CloudKitDebug 1", isEnabled: true),
                    ]
                )
            )
        ),
    ]
)
