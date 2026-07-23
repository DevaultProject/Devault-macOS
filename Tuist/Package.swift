// swift-tools-version: 5.9
import PackageDescription

#if TUIST
import ProjectDescription
import ProjectDescriptionHelpers

let packageSettings = PackageSettings(
    productTypes: [
        "ComposableArchitecture": .staticFramework,
    ]
)
#endif

let package = Package(
    name: "Devault",
    dependencies: [
        .package(
            url: "https://github.com/pointfreeco/swift-composable-architecture",
            from: "1.26.0"
        ),
        .package(
            url: "https://github.com/airbnb/lottie-spm",
            from: "4.6.0"
        ),
    ]
)
