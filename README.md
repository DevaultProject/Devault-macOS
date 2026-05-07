# Devault macOS

Devault macOS 레포지토리입니다.

---

## 개발 환경 세팅

> 처음 레포를 클론한 팀원은 아래 순서대로 진행해주세요.

### 요구 사항

- macOS 14.0 이상
- Xcode 15 이상

### 1. 레포 클론

```bash
git clone https://github.com/your-org/Devault-macOS.git
cd Devault-macOS
```

### 2. 개발 환경 세팅 (mise + Tuist 설치)

```bash
./setup.sh
```

- `mise`가 없으면 자동으로 설치합니다.
- `.mise.toml`에 명시된 Tuist `4.191.0`을 프로젝트 로컬로 설치합니다.

> `mise`를 처음 설치한 경우 터미널을 재시작하거나 아래 명령어를 실행해주세요.
>
> ```bash
> # zsh
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
mise exec -- tuist generate
```

- `Devault.xcworkspace`가 생성됩니다.
- 이후 Xcode에서 `Devault.xcworkspace`를 열어 작업합니다.

---

## 자주 쓰는 명령어

| 명령어 | 설명 |
|---|---|
| `mise exec -- tuist generate` | Xcode 워크스페이스 재생성 |
| `mise exec -- tuist clean` | Tuist 캐시 및 생성 파일 삭제 |
| `./scripts/bootstrap_modules.sh` | 새 모듈 디렉토리 초기화 |

---

## 프로젝트 구조

```
Devault-macOS/
├── Workspace.swift                         # 워크스페이스 정의
├── Tuist.swift                             # Tuist 설정
├── Tuist/
│   └── ProjectDescriptionHelpers/
│       ├── Project+Templates.swift         # bundleID, osVersion, project() 팩토리
│       ├── DVModule.swift                  # 모듈 목록 및 경로 정의
│       ├── Target+Templates.swift          # Target.target() 팩토리
│       ├── ResourceExtensions.swift        # ResourceFileElements.default
│       ├── TargetDependency+Module.swift   # 모듈 간 의존성 헬퍼
│       └── TargetDependency+External.swift # 외부 라이브러리 의존성 헬퍼
└── Projects/
    ├── Devault/         # 메인 앱
    ├── DVCore/          # 공통 유틸리티
    ├── DVDesign/        # 디자인 시스템
    ├── DVData/          # Data 레이어
    ├── DVDomain/        # Domain 레이어
    ├── DVPresentation/  # Presentation 레이어
    ├── DVNetwork/       # 네트워크 (추후 사용)
    └── DVStorage/       # 스토리지 (추후 사용)
```
