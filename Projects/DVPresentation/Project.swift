import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.project(
    name: DVModule.DVPresentation.name,
    targets: [
        .target(
            name: DVModule.DVPresentation.name,
            product: Project.product,
            sources: .sources,
            resources: .default
        ),
    ]
)
