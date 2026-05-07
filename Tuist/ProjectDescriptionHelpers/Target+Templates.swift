import ProjectDescription

// MARK: - Target Factory

extension Target {
    public static func target(
        name: String,
        product: Product,
        bundleId: String? = nil,
        infoPlist: InfoPlist? = .default,
        sources: SourceFilesList? = nil,
        resources: ResourceFileElements? = nil,
        entitlements: Entitlements? = nil,
        scripts: [TargetScript] = [],
        dependencies: [TargetDependency] = [],
        settings: Settings? = nil
    ) -> Target {
        Target.target(
            name: name,
            destinations: .macOS,
            product: product,
            bundleId: bundleId ?? Project.bundleID + "." + name.lowercased(),
            deploymentTargets: .macOS(Project.osVersion),
            infoPlist: infoPlist,
            sources: sources,
            resources: resources,
            entitlements: entitlements,
            scripts: scripts,
            dependencies: dependencies,
            settings: settings
        )
    }
}

// MARK: - SourceFilesList

extension SourceFilesList {
    public static let sources: SourceFilesList = ["Sources/**"]
    public static let tests: SourceFilesList = ["Tests/**"]
}
