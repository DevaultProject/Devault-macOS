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
            name: "DVDomainTests",
            sources: ["Tests/Core/**"],
            dependencies: [
                .domain(),
            ]
        ),
        .tests(
            name: "DVDomainContentTests",
            sources: ["Tests/Content/**"],
            dependencies: [
                .domain(),
            ]
        ),
    ]
)
