import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.project(
    name: DVModule.DVDesign.name,
    targets: [
        .target(
            name: DVModule.DVDesign.name,
            product: Project.product,
            sources: .sources,
            resources: .default
        ),
        .sampleApp(
            name: DVModule.DVDesign.name,
            dependencies: [DVModule.DVDesign.dependency]
        ),
    ]
)
