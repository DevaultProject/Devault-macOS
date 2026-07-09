import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.project(
    name: DVModule.Devault.name,
    targets: [
        .target(
            name: DVModule.Devault.name,
            product: .app,
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": .string("Devault"),
            ]),
            sources: .sources,
            resources: .default,
            dependencies: [
                // internal dependency
                .presentation(),
                .data(),
                .domain(),
                .core(),
                
                // 3rd-party dependency
                .tca(),
            ]
        ),
    ],
    schemes: [
        .scheme(
            name: DVModule.Devault.name,
            buildAction: .buildAction(targets: [.target(DVModule.Devault.name)]),
            runAction: .runAction(executable: .target(DVModule.Devault.name))
        ),
    ]
)
