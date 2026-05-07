import ProjectDescription

// MARK: - External Dependencies

public enum External: String {
    case Nimble
    case Quick
}

extension TargetDependency {
    public static func external(dependency: External) -> TargetDependency {
        .external(name: dependency.rawValue, condition: .when([.macos]))
    }
}
