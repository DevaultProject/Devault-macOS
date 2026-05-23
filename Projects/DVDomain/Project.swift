import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.project(
    name: DVModule.DVDomain.name,
    targets: [
        .target(
            name: DVModule.DVDomain.name,
            product: Project.product,
            sources: .sources,
            dependencies: [
                .core(),
            ]
        ),
        .tests(
            name: DVModule.DVDomain.name,
            dependencies: [DVModule.DVDomain.dependency]
        ),
    ]
)
