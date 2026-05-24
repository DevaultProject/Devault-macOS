import ProjectDescription

// MARK: - Attributes

let nameAttribute: Template.Attribute = .required("name")

// MARK: - Template

let template = Template(
    description: "TCA Feature (Reducer + View) — docs/TCA_GUIDELINES.md 준수",
    attributes: [
        nameAttribute,
    ],
    items: [
        .file(
            path: "Projects/DVPresentation/Sources/Features/\(nameAttribute)/\(nameAttribute)Feature.swift",
            templatePath: "Feature.stencil"
        ),
        .file(
            path: "Projects/DVPresentation/Sources/Features/\(nameAttribute)/\(nameAttribute)View.swift",
            templatePath: "View.stencil"
        ),
    ]
)
