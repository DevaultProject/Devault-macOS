import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.project(
    name: DVModule.DVStorage.name,
    targets: [
        .target(
            name: DVModule.DVStorage.name,
            product: Project.product,
            sources: .sources
        ),
    ]
)
