import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.project(
    name: DVModule.DVNetwork.name,
    targets: [
        .target(
            name: DVModule.DVNetwork.name,
            product: Project.product,
            sources: .sources
        ),
    ]
)
