import ProjectDescription

// MARK: - DVModule

public enum DVModule: String, CaseIterable {
    case Devault
    case DVCore
    case DVDesign
    case DVNetwork  // 당장은 안씀
    case DVStorage  // 당장은 안씀
    case DVData
    case DVDomain
    case DVPresentation
}

// MARK: - Module Properties

public extension DVModule {

    var name: String { rawValue }

    var bundleId: String {
        Project.bundleID + "." + rawValue.lowercased()
    }

    var path: ProjectDescription.Path {
        .relativeToRoot("Projects/\(rawValue)")
    }

    var dependency: TargetDependency {
        .project(target: rawValue, path: path)
    }
}
