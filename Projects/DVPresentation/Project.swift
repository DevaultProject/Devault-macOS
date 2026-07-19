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
            ]
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
            ]
        ),
        .tests(
            name: "DVPresentationTests",
            dependencies: [
                .presentation(),
            ]
        ),
    ]
)
