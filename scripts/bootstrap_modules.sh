#!/bin/bash
set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECTS_DIR="$ROOT_DIR/Projects"

echo "=== Devault - Module Bootstrap ==="

# ---------------------------------------------------------------
# 설정: Resources 디렉토리가 필요한 모듈
# ---------------------------------------------------------------
MODULES_WITH_RESOURCES=("DVDesign" "DVPresentation")

# 프레임워크 모듈 목록 (App 제외)
FRAMEWORK_MODULES=(
    "DVCore"
    "DVDesign"
    "DVNetwork"
    "DVStorage"
    "DVData"
    "DVDomain"
    "DVPresentation"
)

# ---------------------------------------------------------------
# 헬퍼 함수
# ---------------------------------------------------------------
has_resources() {
    local module=$1
    for m in "${MODULES_WITH_RESOURCES[@]}"; do
        [[ "$m" == "$module" ]] && return 0
    done
    return 1
}

gitkeep() {
    local dir=$1
    mkdir -p "$dir"
    if [ ! -f "$dir/.gitkeep" ]; then
        touch "$dir/.gitkeep"
    fi
}

# ---------------------------------------------------------------
# 모듈 디렉토리 생성
# ---------------------------------------------------------------
for MODULE in "${FRAMEWORK_MODULES[@]}"; do
    MODULE_DIR="$PROJECTS_DIR/$MODULE"

    if [ -d "$MODULE_DIR" ]; then
        echo "[skip] $MODULE already exists"
        continue
    fi

    echo "[create] $MODULE"

    gitkeep "$MODULE_DIR/Sources"
    gitkeep "$MODULE_DIR/Tests"

    if has_resources "$MODULE"; then
        gitkeep "$MODULE_DIR/Resources"
    fi

    # Project.swift 생성 (Resources 없는 모듈)
    if ! has_resources "$MODULE"; then
        cat > "$MODULE_DIR/Project.swift" << SWIFT_EOF
import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.project(
    name: DVModule.$MODULE.name,
    targets: [
        .target(
            name: DVModule.$MODULE.name,
            product: Project.product,
            sources: .sources
        ),
    ]
)
SWIFT_EOF

    # Project.swift 생성 (Resources 있는 모듈)
    else
        cat > "$MODULE_DIR/Project.swift" << SWIFT_EOF
import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.project(
    name: DVModule.$MODULE.name,
    targets: [
        .target(
            name: DVModule.$MODULE.name,
            product: Project.product,
            sources: .sources,
            resources: .default
        ),
    ]
)
SWIFT_EOF
    fi
done

echo ""
echo "Done! Run 'tuist generate' to generate the Xcode workspace."
