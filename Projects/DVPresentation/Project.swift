import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.project(
    name: DVModule.DVPresentation.name,
    targets: [
        .target(
            name: DVModule.DVPresentation.name,
            product: Project.product,
            sources: .sources,
            resources: .default,
            dependencies: [
                // internal dependency
                .domain(),
                .design(),
                .core(),

                // 3rd-party dependency
                .tca(),
                .lottie(),
            ],
            // 기본값(NO)이면 String.module(_:) 콜사이트가 Localizable.xcstrings로 추출되지 않는다.
            settings: .settings(base: [
                "SWIFT_EMIT_LOC_STRINGS": "YES",
                "LOCALIZATION_PREFERS_STRING_CATALOGS": "YES",
            ])
        ),
        .tests(
            name: "DVPresentationTests",
            dependencies: [
                // SUT
                .presentation(),

                // internal dependency
                .domain(),
                .core(),

                // 3rd-party dependency
                .tca(),
                .lottie(),
            ]
        ),
    ]
)
