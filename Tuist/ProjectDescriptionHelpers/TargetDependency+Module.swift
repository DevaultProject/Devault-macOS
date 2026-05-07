import ProjectDescription

// MARK: - Core

extension TargetDependency {
    public static func core() -> TargetDependency {
        DVModule.DVCore.dependency
    }
}

// MARK: - DesignSystem

extension TargetDependency {
    public static func design() -> TargetDependency {
        DVModule.DVDesign.dependency
    }
}

// MARK: - Network

extension TargetDependency {
    public static func network() -> TargetDependency {
        DVModule.DVNetwork.dependency
    }
}

// MARK: - Storage

extension TargetDependency {
    public static func storage() -> TargetDependency {
        DVModule.DVStorage.dependency
    }
}

// MARK: - Data

extension TargetDependency {
    public static func data() -> TargetDependency {
        DVModule.DVData.dependency
    }
}

// MARK: - Domain

extension TargetDependency {
    public static func domain() -> TargetDependency {
        DVModule.DVDomain.dependency
    }
}

// MARK: - Presentation

extension TargetDependency {
    public static func presentation() -> TargetDependency {
        DVModule.DVPresentation.dependency
    }
}
