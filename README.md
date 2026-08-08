# Devault macOS

Devault macOS 레포지토리입니다.

---

## 개발 환경 세팅

> 처음 레포를 클론한 팀원은 아래 순서대로 진행해주세요.

### 요구 사항

- macOS 14.0 이상
- Xcode 16.0 이상 (Swift Testing 지원)

### 1. 레포 클론

```bash
git clone https://github.com/your-org/Devault-macOS.git
cd Devault-macOS
```

### 2. 개발 환경 세팅

```bash
./setup.sh
```

- `mise`가 없으면 자동으로 설치합니다.
- `.mise.toml`에 명시된 Tuist `4.191.0`을 프로젝트 로컬로 설치합니다.
- `Tuist/Package.swift`에 정의된 외부 패키지를 fetch합니다.

> `mise`를 처음 설치한 경우 터미널을 재시작하거나 아래 명령어를 실행해주세요.
>
> ```bash
> eval "$(~/.local/bin/mise activate zsh)"
> ```

### 3. 모듈 디렉토리 생성

```bash
./scripts/bootstrap_modules.sh
```

- 각 모듈의 `Sources/`, `Tests/`, `Resources/` 디렉토리와 `Project.swift`를 생성합니다.
- 이미 존재하는 모듈은 건드리지 않습니다.

### 4. Xcode 워크스페이스 생성

```bash
tuist generate
```

- `Devault.xcworkspace`가 생성됩니다.
- 이후 Xcode에서 `Devault.xcworkspace`를 열어 작업합니다.

#### Apple Developer 팀 시트가 없다면

앱 타겟은 iCloud(CloudKit) entitlement를 쓰기 때문에, 팀에 초대되지 않은 계정으로는 서명에 실패해 빌드되지 않습니다.
이 경우 `tuist generate` 대신 아래 명령으로 워크스페이스를 생성하세요.

```bash
generate-local
```

- iCloud entitlement를 떼고 ad-hoc 서명("Sign to Run Locally")으로 빌드합니다. Apple ID 자체가 필요 없습니다.
- 생성 이후 빌드/실행은 Xcode에서 평소와 동일합니다.
- iCloud 동기화 기능만 사용할 수 없습니다. 온보딩에서 동기화를 켜면 안내 알럿이 뜨고 넘어갑니다.
- 빌드마다 서명이 달라지므로 키체인 접근 허용을 다시 물어볼 수 있습니다.

> `generate-local`은 `.mise.toml`이 저장소 안에서만 `scripts/`를 PATH에 얹어주는 덕에 접두사 없이 실행됩니다.
> `command not found`가 뜨면 셸에 mise가 활성화되지 않은 것이니 `./setup.sh`를 먼저 실행하고,
> 최초 1회는 `mise trust`로 설정 파일을 신뢰해야 합니다.

---

## 자주 쓰는 명령어

| 명령어 | 설명 |
|---|---|
| `tuist generate` | Xcode 워크스페이스 재생성 |
| `generate-local` | iCloud entitlement 없이 재생성 (팀 시트 없는 경우) |
| `tuist install` | 외부 패키지 fetch (Package.swift 변경 시) |
| `tuist clean` | Tuist 캐시 및 생성 파일 삭제 |
| `./scripts/bootstrap_modules.sh` | 새 모듈 디렉토리 초기화 |

---

## 프로젝트 구조

```
Devault-macOS/
├── Workspace.swift                         # 워크스페이스 정의 (DVModule.allCases 기반)
├── Tuist.swift                             # Tuist 설정
├── Tuist/
│   ├── Package.swift                       # 외부 패키지 정의
│   └── ProjectDescriptionHelpers/
│       ├── Project+Templates.swift         # bundleID, osVersion, project() 팩토리
│       ├── DVModule.swift                  # 모듈 목록 및 경로/bundleId 정의
│       ├── Target+Templates.swift          # target() / tests() / sampleApp() 팩토리
│       ├── ResourceExtensions.swift        # ResourceFileElements.default
│       ├── TargetDependency+Module.swift   # 모듈 간 의존성 헬퍼
│       └── TargetDependency+External.swift # 외부 라이브러리 의존성 헬퍼
├── Projects/
│   ├── Devault/         # 메인 앱
│   ├── DVCore/          # 공통 유틸리티
│   ├── DVDesign/        # 디자인 시스템 (+ SampleApp)
│   ├── DVData/          # Data 레이어
│   ├── DVDomain/        # Domain 레이어 (+ Tests)
│   ├── DVPresentation/  # Presentation 레이어
│   ├── DVNetwork/       # 네트워크 (추후 사용)
│   └── DVStorage/       # 스토리지 (추후 사용)
└── scripts/
    └── bootstrap_modules.sh  # 모듈 디렉토리 초기화 스크립트
```

---

## 외부 의존성

| 패키지 | 용도 |
|---|---|
| [swift-composable-architecture](https://github.com/pointfreeco/swift-composable-architecture) | TCA - DVPresentation 상태 관리 |

---

## 새 모듈 추가하기

> 예시: `DVFeatureVault` 모듈을 새로 추가하는 경우

### 1. `DVModule.swift`에 케이스 추가

```swift
// Tuist/ProjectDescriptionHelpers/DVModule.swift
public enum DVModule: String, CaseIterable {
    ...
    case DVFeatureVault  // 추가
}
```

`name`, `bundleId`, `path`, `dependency`는 자동으로 생성됩니다.

### 2. `TargetDependency+Module.swift`에 헬퍼 추가

```swift
// Tuist/ProjectDescriptionHelpers/TargetDependency+Module.swift
extension TargetDependency {
    public static func featureVault() -> TargetDependency {
        DVModule.DVFeatureVault.dependency
    }
}
```

### 3. 모듈 디렉토리 생성

```bash
./scripts/bootstrap_modules.sh
```

`DVFeatureVault/` 디렉토리와 기본 `Project.swift`가 자동 생성됩니다.

### 4. `Project.swift` 수정 (필요 시)

bootstrap으로 생성된 기본 `Project.swift`를 필요에 맞게 수정합니다.

```swift
// Projects/DVFeatureVault/Project.swift
import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.project(
    name: DVModule.DVFeatureVault.name,
    targets: [
        .target(
            name: DVModule.DVFeatureVault.name,
            product: Project.product,
            sources: .sources,
            dependencies: [
                .domain(),
                .design(),
            ]
        ),
        .tests(
            name: DVModule.DVFeatureVault.name,
            dependencies: [DVModule.DVFeatureVault.dependency]
        ),
    ]
)
```

### 5. 워크스페이스 재생성

```bash
tuist generate
```

`Workspace.swift`는 `DVModule.allCases`를 자동으로 순회하므로 별도 수정이 필요 없습니다.

---

## 외부 라이브러리 추가하기

> 예시: `Alamofire`를 추가하는 경우

### 1. `Tuist/Package.swift`에 패키지 추가

```swift
// Tuist/Package.swift
let packageSettings = PackageSettings(
    productTypes: [
        "ComposableArchitecture": .staticFramework,
        "Alamofire": .staticFramework,  // 추가
    ]
)

let package = Package(
    name: "Devault",
    dependencies: [
        .package(
            url: "https://github.com/pointfreeco/swift-composable-architecture",
            from: "1.15.0"
        ),
        .package(
            url: "https://github.com/Alamofire/Alamofire",  // 추가
            from: "5.0.0"
        ),
    ]
)
```

> `productTypes`에 추가하면 정적 프레임워크로 링크됩니다. 동적 프레임워크가 필요한 경우 생략하세요.

### 2. `TargetDependency+External.swift`에 케이스 추가

```swift
// Tuist/ProjectDescriptionHelpers/TargetDependency+External.swift
public enum External: String {
    case ComposableArchitecture
    case Alamofire  // 추가
}
```

### 3. 패키지 fetch

```bash
tuist install
```

### 4. 사용할 모듈의 `Project.swift`에 의존성 추가

```swift
.target(
    name: DVModule.DVNetwork.name,
    product: Project.product,
    sources: .sources,
    dependencies: [
        .external(dependency: .Alamofire),
    ]
)
```

### 5. 워크스페이스 재생성

```bash
tuist generate
```

---

## 테스트

Swift Testing을 사용합니다.

```swift
import Testing
@testable import DVDomain

@Suite("UseCase 이름")
struct SomeUseCaseTest {
    @Test("성공 시 올바른 값을 반환한다")
    func success() {
        #expect(result == expected)
    }
}
```

테스트 타겟은 `Project.swift`에서 `.tests()` 템플릿으로 추가합니다.

```swift
.tests(
    name: DVModule.DVDomain.name,
    dependencies: [DVModule.DVDomain.dependency]
)
```
