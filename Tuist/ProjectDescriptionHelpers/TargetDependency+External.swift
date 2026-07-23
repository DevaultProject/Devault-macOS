import ProjectDescription

// MARK: - External Dependencies

public enum External: String {
    case ComposableArchitecture
    case Lottie
}

extension TargetDependency {
    public static func external(dependency: External) -> TargetDependency {
        .external(name: dependency.rawValue, condition: .when([.macos]))
    }

    public static func tca() -> TargetDependency {
        .external(dependency: .ComposableArchitecture)
    }

    public static func lottie() -> TargetDependency {
        .external(dependency: .Lottie)
    }
}
