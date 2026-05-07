import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.project(
    name: DVModule.DVCore.name,
    targets: [
        .target(
            name: DVModule.DVCore.name,
            product: Project.product,
            sources: .sources
        ),
    ]
)
