import ProjectDescription
import ProjectDescriptionHelpers

// MARK: - Signing

/// Apple Developer 팀 시트가 없는 팀원을 위한 로컬 빌드 스위치.
///
/// `TUIST_LOCAL_SIGNING=1 tuist generate`로 켜면 iCloud entitlement를 떼고 ad-hoc 서명으로 빌드한다.
/// entitlement가 없으면 CloudKit 계정 조회가 `.configurationUnavailable`로 떨어져 동기화가 켜지지 않으므로,
/// iCloud를 제외한 나머지 기능은 그대로 확인할 수 있다.
///
/// TODO: 팀 시트를 전원에게 발급하면 이 분기와 아래 두 설정 딕셔너리를 제거한다. (#64)
let isLocalSigning = Environment.localSigning.getBoolean(default: false)

let teamSigningSettings: SettingsDictionary = [
    "ASSETCATALOG_COMPILER_APPICON_NAME": "Devault_IC",
    "DEVELOPMENT_TEAM": "UKY6HK6U6Y",
    // Tuist가 macOS 타겟에 CODE_SIGN_IDENTITY = "-"(ad-hoc)를 기본으로 넣는데,
    // iCloud entitlement는 프로비저닝 프로파일을 요구하므로 그대로 두면 서명 단계에서 빌드가 실패한다.
    "CODE_SIGN_STYLE": "Automatic",
    "CODE_SIGN_IDENTITY": "Apple Development",
]

let localSigningSettings: SettingsDictionary = [
    "ASSETCATALOG_COMPILER_APPICON_NAME": "Devault_IC",
    "CODE_SIGN_STYLE": "Manual",
    // Sign to Run Locally. 프로비저닝 프로파일 없이 서명하므로 Apple ID 자체가 필요 없다.
    "CODE_SIGN_IDENTITY": "-",
]

// MARK: - Project

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
            entitlements: isLocalSigning ? nil : .file(path: "Resources/Devault.entitlements"),
            dependencies: [
                // internal dependency
                .presentation(),
                .data(),
                .domain(),
                .core(),

                // 3rd-party dependency
                .tca(),
            ],
            settings: .settings(base: isLocalSigning ? localSigningSettings : teamSigningSettings)
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
