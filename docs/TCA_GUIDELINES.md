# TCA Guidelines

The Composable Architecture(이하 TCA) **1.25.0** (Observation 기반)을 사용하는 macOS SwiftUI 프로젝트의 컨벤션입니다.
이 문서는 **개발자가 Feature를 작성할 때의 기준**이자, **AI 에이전트가 PR을 리뷰할 때의 기준**입니다.

대상 모듈: `DVPresentation`
의존성 선언: `Tuist/Package.swift` (`from: "1.25.0"`)
관련 문서: [CODING_GUIDELINES.md](./CODING_GUIDELINES.md)

## 새 Feature 시작하기

Tuist scaffold를 사용해 가이드라인에 맞는 보일러플레이트를 생성합니다.

```bash
tuist scaffold feature --name ProjectList
```

생성 결과:

```
Projects/DVPresentation/Sources/Features/ProjectList/
├── ProjectListFeature.swift   // @Reducer + State/Action/Body 골격
└── ProjectListView.swift      // @Bindable store + content + Preview
```

생성된 파일은 본 문서의 [11절 체크리스트](#11-리뷰-체크리스트-ai-에이전트용) 기본 항목(`@Reducer`, `@ObservableState`, exhaustive switch, `delegate(_)` Action, `.task` 패턴 등)을 이미 통과한 상태입니다.
신규 Feature는 **반드시 scaffold로 시작**합니다.

---

## 핵심 원칙

1. **State는 값타입**이고, **변경은 오직 Reducer 안에서**만 이루어진다.
2. **Action은 "일어난 일"이지 "해야 할 일"이 아니다.** 명령형이 아닌 이벤트형으로 명명한다.
3. **Reducer는 순수 함수**다. 비동기 작업·외부 자원 접근은 전부 `Effect` 또는 `@Dependency`로 빼낸다.
4. **자식 Feature는 부모의 일부 가지**다. 자식 Store는 부모에서 `scope`로 내려준다.
5. **View는 표현(presentation)만** 한다. 비즈니스 로직·라우팅 분기·외부 호출은 Reducer가 책임진다.
6. **테스트는 `TestStore`로 한다.** Reducer는 Action 시퀀스로 검증한다.

---

## 1. 파일 구조

### 1.1 Feature 단위 디렉토리

하나의 Feature는 **하나의 디렉토리**로 묶고, 최소 `Feature.swift`와 `View.swift`를 함께 둡니다.

```
DVPresentation/Sources/Features/
├── AppFeature.swift                  // 루트 Reducer
├── AppView.swift
├── ProjectList/
│   ├── ProjectListFeature.swift
│   └── ProjectListView.swift
├── ProjectDetail/
│   ├── ProjectDetailFeature.swift
│   ├── ProjectDetailView.swift
│   └── Components/                   // 이 화면에서만 쓰이는 보조 View
│       └── ProjectMetaSection.swift
```

### 1.2 네이밍

| 대상 | 규칙 | 예시 |
|---|---|---|
| Reducer 타입 | `{도메인}Feature` | `ProjectListFeature` |
| Reducer 파일 | `{도메인}Feature.swift` | `ProjectListFeature.swift` |
| View 타입 | `{도메인}View` | `ProjectListView` |
| View 파일 | `{도메인}View.swift` | `ProjectListView.swift` |
| 자식 화면 enum 케이스 | 명사 (화면 이름) | `case detail(ProjectDetailFeature)` |

> Reducer 이름에 `ViewModel`, `Store`, `Reducer` 접미사는 붙이지 않습니다.
> Store는 런타임 인스턴스이지 타입이 아닙니다.

---

## 2. State

### 2.1 선언

- `@ObservableState`를 반드시 붙입니다. (`@Observable` 아님)
- `Equatable`을 채택합니다.
- **모든 프로퍼티는 값타입**이어야 합니다. (`class`, `ObservableObject` 금지)

```swift
// ✅ Good
@Reducer
struct ProjectListFeature {

  @ObservableState
  struct State: Equatable {
    var projects: IdentifiedArrayOf<Project> = []
    var isLoading = false
    var searchText = ""
    @Presents var destination: Destination.State?
  }
}

// ❌ Bad
struct State {                              // @ObservableState 없음
  var viewModel: SomeViewModel              // reference type
  var projects: [Project]                   // IdentifiedArray 미사용
}
```

### 2.2 컬렉션은 `IdentifiedArrayOf`

자식 Feature를 행으로 갖는 리스트는 **반드시** `IdentifiedArrayOf<Element>`를 씁니다.
ID 기반 접근·자식 Action 라우팅이 가능해야 하기 때문입니다.

```swift
// ✅ Good
var rows: IdentifiedArrayOf<RowFeature.State> = []

// ❌ Bad
var rows: [RowFeature.State] = []
```

### 2.3 파생 데이터는 computed property

State에 **계산 가능한 값을 저장하지 않습니다.** 항상 computed로 노출합니다.

```swift
// ✅ Good
struct State: Equatable {
  var projects: IdentifiedArrayOf<Project> = []
  var searchText = ""

  var filteredProjects: IdentifiedArrayOf<Project> {
    guard !searchText.isEmpty else { return projects }
    return projects.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
  }
}

// ❌ Bad — projects나 searchText가 바뀔 때마다 동기화 누락 위험
struct State: Equatable {
  var projects: IdentifiedArrayOf<Project> = []
  var searchText = ""
  var filteredProjects: IdentifiedArrayOf<Project> = []
}
```

### 2.4 옵셔널 vs 빈 컬렉션

- "값이 아직 로드되지 않음" → `Optional` 또는 명시적 상태(enum)
- "값은 있지만 비어 있음" → 빈 컬렉션

```swift
// ✅ Good — 로딩 전과 빈 결과를 구분
enum LoadingState<Value: Equatable>: Equatable {
  case idle
  case loading
  case loaded(Value)
  case failed(String)
}

var projects: LoadingState<IdentifiedArrayOf<Project>> = .idle
```

---

## 3. Action

### 3.1 네이밍 — "일어난 일"로 짓기

Action은 **명령(verb)이 아니라 사건(event)**입니다.
[CODING_GUIDELINES](./CODING_GUIDELINES.md)의 "이벤트 핸들러는 과거형" 규칙을 그대로 따릅니다.

| 분류 | 패턴 | 예시 |
|---|---|---|
| 사용자 입력 | `didTap{대상}`, `didChange{대상}` | `didTapAddButton`, `didChangeSearchText(String)` |
| 라이프사이클 | `{시점}` | `onAppear`, `task` |
| 비동기 응답 | `{대상}Response(Result)` | `projectsResponse(Result<[Project], Error>)` |
| 내부 흐름 | `_{동사}` (언더스코어 prefix) | `_setLoading(Bool)` |
| 자식 위임 | `delegate({이벤트})` | `delegate(.projectSaved(Project))` |
| 자식/네비게이션 | `{자식이름}({자식.Action})` | `destination(PresentationAction<Destination.Action>)` |

```swift
// ✅ Good — 일어난 일
enum Action {
  case didTapAddButton
  case didChangeSearchText(String)
  case projectsResponse(Result<[Project], Error>)
  case destination(PresentationAction<Destination.Action>)
  case delegate(Delegate)

  enum Delegate: Equatable {
    case projectDeleted(Project.ID)
  }
}

// ❌ Bad — 명령형 / 동작 지시
enum Action {
  case loadProjects
  case showAddSheet
  case handleResponse([Project])
}
```

### 3.2 케이스 분류 (권장 그룹)

큰 Feature의 Action은 의미별로 nested enum 또는 주석으로 그룹화합니다.

```swift
enum Action {
  // MARK: View
  case onAppear
  case didTapAddButton
  case didTapRow(id: Project.ID)

  // MARK: Internal
  case projectsResponse(Result<[Project], Error>)

  // MARK: Child
  case destination(PresentationAction<Destination.Action>)

  // MARK: Delegate
  case delegate(Delegate)
  enum Delegate: Equatable {
    case projectDeleted(Project.ID)
  }
}
```

### 3.3 Delegate Action 패턴

자식 Feature가 **부모에게 알려야 하는 결과**는 반드시 `delegate(_)`로 통일합니다.
부모는 자식의 일반 Action을 직접 듣지 않습니다.

```swift
// 자식 (ProjectDetailFeature)
case .didTapDelete:
  return .run { [id = state.id] send in
    try await projectClient.delete(id)
    await send(.delegate(.projectDeleted(id)))
  }

// 부모 (ProjectListFeature)
case .destination(.presented(.detail(.delegate(.projectDeleted(let id))))):
  state.projects.remove(id: id)
  return .none
```

> **Rule:** 자식이 부모의 State를 직접 알면 안 됩니다. 자식은 "내가 한 일"만 알리고, 부모가 그것을 어떻게 처리할지 결정합니다.

### 3.4 Equatable

Action은 **가능한 한 `Equatable`을** 채택합니다. `TestStore`에서 동등 비교가 필요하기 때문입니다.
`Error` 등 Equatable이 안 되는 타입은 별도 wrapper(`EquatableError`)로 감싸거나 `Result`의 동등 비교를 위해 Error를 의미 있는 enum으로 매핑합니다.

---

## 4. Reducer

### 4.1 형태

- `@Reducer` 매크로 사용
- `var body: some ReducerOf<Self>` 안에서 `Reduce { state, action in ... }`
- 자식 결합은 `Scope`, `ifLet`, `forEach` 등의 오퍼레이터로

```swift
@Reducer
struct ProjectListFeature {

  @ObservableState
  struct State: Equatable { /* ... */ }

  enum Action: Equatable { /* ... */ }

  @Dependency(\.projectClient) var projectClient

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      // ...
      }
    }
    .ifLet(\.$destination, action: \.destination) {
      Destination()
    }
  }
}
```

### 4.2 Reducer 안에서는 절대 하지 말 것

- ❌ `Task { ... }` 직접 띄우기 → `.run { send in ... }` 사용
- ❌ `URLSession`, `FileManager`, `Date()`, `UUID()` 직접 호출 → `@Dependency`
- ❌ State를 reducer 밖에서 변경 (View, Effect 클로저에서 직접 변경)
- ❌ View 표현 결정 (색·문자열) — 그건 View 책임
- ❌ 다른 Feature의 State를 직접 참조

### 4.3 case 본문은 짧게

case 본문이 5~10줄을 넘으면 **private helper**로 분리합니다.

```swift
// ✅ Good
case .projectsResponse(.success(let projects)):
  return handleProjectsLoaded(state: &state, projects: projects)

// helper
private func handleProjectsLoaded(
  state: inout State,
  projects: [Project]
) -> Effect<Action> {
  state.isLoading = false
  state.projects = IdentifiedArray(uniqueElements: projects)
  return .none
}
```

### 4.4 switch는 **반드시 exhaustive**

`default:`를 쓰지 않습니다. Action이 늘었을 때 컴파일러가 잡아주는 안전망을 포기하지 마세요.

```swift
// ❌ Bad
switch action {
case .didTapAddButton: ...
default: return .none
}

// ✅ Good — 모든 케이스 명시
switch action {
case .didTapAddButton: ...
case .didChangeSearchText(let text): ...
case .projectsResponse(.success(let projects)): ...
case .projectsResponse(.failure(let error)): ...
case .destination: return .none
case .delegate: return .none
}
```

---

## 5. Effect & 비동기

### 5.1 비동기는 `.run`

```swift
// ✅ Good
case .onAppear:
  state.isLoading = true
  return .run { send in
    await send(.projectsResponse(Result { try await projectClient.fetchAll() }))
  }

// ❌ Bad
case .onAppear:
  Task { @MainActor in
    let projects = try await projectClient.fetchAll()
    // state를 여기서 못 바꿈
  }
  return .none
```

### 5.2 취소 가능한 Effect

검색·디바운스 등 **이전 작업을 취소해야 하는 Effect**는 `cancellable(id:)`를 씁니다.
ID는 enum case 없는 `enum CancelID { case search }` 패턴으로 정의합니다.

```swift
private enum CancelID { case search }

case .didChangeSearchText(let text):
  state.searchText = text
  return .run { send in
    try await clock.sleep(for: .milliseconds(300))
    await send(.searchResponse(Result { try await projectClient.search(text) }))
  }
  .cancellable(id: CancelID.search, cancelInFlight: true)
```

### 5.3 State capture는 명시적으로

`.run` 클로저는 State 전체를 캡처할 수 없습니다(값타입이라 스냅샷). **필요한 값만 캡처 리스트에 명시**합니다.

```swift
// ✅ Good
return .run { [id = state.id, name = state.name] send in
  try await client.save(id: id, name: name)
  await send(.delegate(.projectSaved))
}

// ❌ Bad — state 전체를 캡처하려는 시도
return .run { send in
  try await client.save(id: state.id, name: state.name)  // ❌
}
```

### 5.4 에러는 Reducer에서 처리

`.run`에서 `try`로 던지면 `catch:` 클로저 또는 `Result`로 받습니다. Effect 안에서 묵살하지 않습니다.

```swift
return .run { send in
  await send(.projectsResponse(Result { try await projectClient.fetchAll() }))
}
// 또는
return .run { send in
  let projects = try await projectClient.fetchAll()
  await send(.projectsResponse(.success(projects)))
} catch: { error, send in
  await send(.projectsResponse(.failure(error)))
}
```

---

## 6. Dependency

### 6.1 모든 외부 의존은 `@Dependency`

`projectClient`, `clock`, `uuid`, `date`, `mainQueue` 등 **시간·랜덤·외부 자원은 전부 Dependency로**.

```swift
@Reducer
struct ProjectListFeature {
  @Dependency(\.projectClient) var projectClient
  @Dependency(\.uuid) var uuid
  @Dependency(\.continuousClock) var clock
  @Dependency(\.date.now) var now
}
```

### 6.2 Client 정의 패턴

DVDomain 또는 DVData의 인터페이스를 TCA `DependencyKey`로 감쌉니다.

```swift
// ProjectClient.swift  (DVPresentation 내부, 또는 별도 Dependencies 디렉토리)
@DependencyClient
struct ProjectClient: Sendable {
  var fetchAll: @Sendable () async throws -> [Project]
  var save: @Sendable (Project) async throws -> Void
  var delete: @Sendable (Project.ID) async throws -> Void
}

extension ProjectClient: DependencyKey {
  static let liveValue = ProjectClient(
    fetchAll: { try await /* DVData repository 호출 */ },
    save: { project in /* ... */ },
    delete: { id in /* ... */ }
  )

  static let testValue = ProjectClient()           // 모든 클로저 unimplemented
  static let previewValue = ProjectClient(
    fetchAll: { Project.mockList },
    save: { _ in },
    delete: { _ in }
  )
}

extension DependencyValues {
  var projectClient: ProjectClient {
    get { self[ProjectClient.self] }
    set { self[ProjectClient.self] = newValue }
  }
}
```

### 6.3 금지 사항

- ❌ Reducer 안에서 싱글톤 직접 호출 (`SomeService.shared.foo()`)
- ❌ DVDomain UseCase를 직접 `import` 후 호출 — Client로 감싸기
- ❌ `@Dependency`를 View나 외부 함수에서 읽기 — Reducer 안에서만 의미가 있음

---

## 7. Navigation & Composition

### 7.1 단일 자식 화면 — `@Presents` + `ifLet`

시트·풀스크린·알럿 등 **0~1개 떠 있는** 화면.

```swift
@ObservableState
struct State: Equatable {
  @Presents var destination: Destination.State?
}

@Reducer
enum Destination {
  case detail(ProjectDetailFeature)
  case addSheet(AddProjectFeature)
  case deleteAlert(AlertState<Action.Alert>)
}

var body: some ReducerOf<Self> {
  Reduce { state, action in /* ... */ }
    .ifLet(\.$destination, action: \.destination)
}
```

### 7.2 스택 네비게이션 — `StackState` + `forEach`

```swift
@ObservableState
struct State: Equatable {
  var path = StackState<Path.State>()
}

@Reducer
enum Path {
  case detail(ProjectDetailFeature)
  case settings(SettingsFeature)
}

var body: some ReducerOf<Self> {
  Reduce { state, action in /* ... */ }
    .forEach(\.path, action: \.path)
}
```

### 7.3 동등한 자식 컬렉션 — `forEach`

```swift
@ObservableState
struct State: Equatable {
  var rows: IdentifiedArrayOf<RowFeature.State> = []
}

enum Action {
  case rows(IdentifiedActionOf<RowFeature>)
}

var body: some ReducerOf<Self> {
  Reduce { /* ... */ }
    .forEach(\.rows, action: \.rows) {
      RowFeature()
    }
}
```

### 7.4 Composition 원칙

- **부모는 자식의 State를 alloc/dealloc하고, 자식의 delegate Action만 듣는다.**
- 자식의 일반 Action에 부모가 분기를 다는 일은 최소화한다.
- 두 자식이 서로 통신해야 하면 **공통 부모를 통해** 한다. 자식끼리 직접 연결하지 않는다.

---

## 8. View

### 8.1 Store 보유

- 루트 View: `let store: StoreOf<Feature>` 또는 `@Bindable var store`
- 양방향 바인딩이 필요한 화면: `@Bindable var store: StoreOf<Feature>`

```swift
struct ProjectListView: View {
  @Bindable var store: StoreOf<ProjectListFeature>

  var body: some View {
    NavigationStack {
      content
    }
    .task { store.send(.task) }
    .sheet(
      item: $store.scope(state: \.destination?.addSheet, action: \.destination.addSheet)
    ) { addStore in
      AddProjectView(store: addStore)
    }
  }
}
```

### 8.2 View 본문 규칙

[CODING_GUIDELINES §3](./CODING_GUIDELINES.md) 그대로 적용:
- `var body`에는 **최상위 컨테이너 하나**만
- 하위뷰는 `extension`에서 `private`로

### 8.3 View에서 절대 하지 말 것

- ❌ View에서 `Task { ... }` 띄우고 비동기 작업
- ❌ View에서 직접 `@Dependency` 읽기
- ❌ `store.state.foo` 형태로 깊이 읽기 — Observation이 알아서 추적하니까 `store.foo`로 충분
- ❌ `ViewStore`, `WithViewStore` 사용 (1.7+ Observation 시대엔 deprecated 패턴)
- ❌ View에서 `if let` 으로 자식 상태 분기 후 자체 분기 처리 — 그건 Destination enum의 일

```swift
// ✅ Good
Text(store.title)
Button("Add") { store.send(.didTapAddButton) }

// ❌ Bad
WithViewStore(store, observe: { $0 }) { viewStore in
  Text(viewStore.title)
}
```

### 8.4 바인딩

```swift
// ✅ Good — @ObservableState + @Bindable이면 $store.프로퍼티로 바로 바인딩
TextField("Search", text: $store.searchText)

// ❌ Bad — 옛날 방식
TextField("Search", text: viewStore.binding(get: \.searchText, send: ...))
```

> 이를 위해 Action에는 `BindableAction` + `binding(_:)` 케이스를 채택해도 좋습니다.

```swift
enum Action: BindableAction, Equatable {
  case binding(BindingAction<State>)
  case didTapAddButton
  // ...
}

var body: some ReducerOf<Self> {
  BindingReducer()
  Reduce { /* ... */ }
}
```

---

## 9. Testing

### 9.1 TestStore 기본형

```swift
@MainActor
func test_didTapAdd_presentsAddSheet() async {
  let store = TestStore(initialState: ProjectListFeature.State()) {
    ProjectListFeature()
  } withDependencies: {
    $0.projectClient.fetchAll = { [Project.mock1, Project.mock2] }
    $0.uuid = .incrementing
    $0.continuousClock = ImmediateClock()
  }

  await store.send(.didTapAddButton) {
    $0.destination = .addSheet(AddProjectFeature.State())
  }
}
```

### 9.2 규칙

- 모든 Dependency는 **테스트에서 명시적으로 override**한다. unimplemented 호출이 나면 테스트 실패.
- `await store.send(...)` 의 trailing closure에서 **State 변경을 정확히 기술**한다.
- 비동기 Effect 결과는 `await store.receive(\.액션)` 로 받는다.
- `store.exhaustivity = .off`는 **임시 디버깅용**. PR에 남기지 않는다.

### 9.3 권장 테스트 범위

- 사용자 입력 Action → State 변화
- Effect 응답 Action → State 변화 + 후속 Action
- Delegate Action → 부모의 처리
- 취소 가능한 Effect의 취소 동작

---

## 10. 안티패턴 모음

| 안티패턴 | 왜 안 되나 | 대안 |
|---|---|---|
| State에 `class` 또는 `ObservableObject` | 값 의미 깨짐, 테스트 불가 | struct + computed |
| Reducer 안에서 `Task { ... }` | 취소·테스트 불가 | `.run { send in ... }` |
| Action 이름이 동사 (`loadProjects`) | "해야 할 일"을 View가 결정하게 됨 | "일어난 일" (`didTapRefresh`) |
| 자식이 부모 State를 알고 변경 | 결합도 폭발 | `delegate(_)` Action |
| `default:` 케이스 | 새 Action 추가 시 누락 | exhaustive switch |
| `WithViewStore` 신규 사용 | 1.7+ 에선 deprecated 패턴 | `@ObservableState` + `@Bindable` |
| View에서 `Task { }` | 라이프사이클·취소 깨짐 | `.task { store.send(...) }` + Reducer Effect |
| 싱글톤 직접 호출 | 테스트 불가, mock 불가 | `@Dependency` |
| `[Element]`로 행 관리 | ID 라우팅 불가 | `IdentifiedArrayOf<Element>` |
| State에 캐시된 파생값 저장 | 동기화 누락 위험 | computed property |

---

## 11. 리뷰 체크리스트 (AI 에이전트용)

> AI 에이전트는 PR 또는 Feature 코드 리뷰 요청 시 아래 항목을 **순서대로** 점검하고, 위반 사항을 항목 번호와 함께 보고한다.
> 각 항목은 **위반 / 통과 / 해당 없음** 중 하나로 판정한다.

### A. 파일 구조

- [ ] **A1.** Feature 디렉토리에 `{이름}Feature.swift`와 `{이름}View.swift`가 함께 있는가?
- [ ] **A2.** Reducer 타입 이름이 `~Feature` 형태인가? (`~ViewModel`, `~Store`, `~Reducer` 금지)

### B. State

- [ ] **B1.** State에 `@ObservableState`가 붙어 있는가?
- [ ] **B2.** State가 `Equatable`을 채택했는가?
- [ ] **B3.** State 프로퍼티가 모두 값타입인가? (class/ObservableObject 사용 금지)
- [ ] **B4.** 자식 컬렉션이 `IdentifiedArrayOf<...>`인가?
- [ ] **B5.** 파생 데이터가 computed property로 노출되는가? (저장 금지)
- [ ] **B6.** "로딩 전"과 "빈 결과"가 구분되는 모델링인가?

### C. Action

- [ ] **C1.** Action 이름이 "일어난 일"(이벤트형, 과거형)로 작성됐는가?
- [ ] **C2.** 부모에게 전달할 결과가 `delegate(_)` Action으로 분리됐는가?
- [ ] **C3.** 자식 Feature 결합이 `destination`/`path`/`{자식}` 형태로 일관되게 명명됐는가?
- [ ] **C4.** Action이 가능한 한 `Equatable`인가?
- [ ] **C5.** Action enum이 의미별 그룹(View/Internal/Child/Delegate)으로 정리됐는가?

### D. Reducer

- [ ] **D1.** `@Reducer` 매크로를 사용했는가?
- [ ] **D2.** `Reduce` 안의 `switch`가 **exhaustive**한가? (`default` 금지)
- [ ] **D3.** 각 case 본문이 5~10줄 이내인가? (초과 시 helper로 분리)
- [ ] **D4.** Reducer 안에서 `Task { ... }`를 직접 띄우지 않는가?
- [ ] **D5.** Reducer 안에서 `URLSession`, `Date()`, `UUID()`, 싱글톤을 직접 호출하지 않는가?
- [ ] **D6.** 자식 결합이 `Scope`/`ifLet`/`forEach` 중 적절한 것으로 됐는가?
- [ ] **D7.** Reducer가 View 표현(색·문자열) 결정을 하지 않는가?

### E. Effect

- [ ] **E1.** 비동기 작업이 전부 `.run { send in ... }`로 표현됐는가?
- [ ] **E2.** State 캡처가 캡처 리스트 `[x = state.x]`로 명시됐는가? (`state.x` 직접 참조 금지)
- [ ] **E3.** 디바운스·중복 방지가 필요한 Effect가 `cancellable(id:cancelInFlight:)`을 쓰는가?
- [ ] **E4.** 에러가 묵살되지 않고 응답 Action(`Result`)으로 돌아오는가?
- [ ] **E5.** `CancelID`가 case 없는 enum으로 정의됐는가?

### F. Dependency

- [ ] **F1.** 외부 호출이 모두 `@Dependency`로 주입됐는가?
- [ ] **F2.** Client가 `@DependencyClient`로 정의되고 `liveValue`/`testValue`/`previewValue`를 제공하는가?
- [ ] **F3.** `DependencyValues` extension으로 키가 등록됐는가?
- [ ] **F4.** Reducer/View에서 싱글톤(`.shared`) 직접 호출이 없는가?

### G. Navigation

- [ ] **G1.** 0~1개 자식 화면이 `@Presents` + `ifLet`으로 구성됐는가?
- [ ] **G2.** 다중 화면 스택이 `StackState` + `forEach`로 구성됐는가?
- [ ] **G3.** 두 자식이 서로 통신할 때 공통 부모를 거치는가? (자식끼리 직접 연결 금지)

### H. View

- [ ] **H1.** View가 `let store` 또는 `@Bindable var store`로 Store를 보유하는가?
- [ ] **H2.** `WithViewStore`/`ViewStore`가 신규 코드에 사용되지 않았는가?
- [ ] **H3.** View가 직접 `Task { ... }`를 띄우지 않는가? (`.task { store.send(...) }` 사용)
- [ ] **H4.** View에서 `@Dependency`를 직접 읽지 않는가?
- [ ] **H5.** 바인딩이 `$store.프로퍼티` 또는 `BindingReducer` 패턴인가?
- [ ] **H6.** `var body`에 최상위 컨테이너 하나만 있고 하위뷰가 `private` extension으로 분리됐는가?

### I. Testing

- [ ] **I1.** Feature에 `TestStore` 기반 단위 테스트가 존재하는가?
- [ ] **I2.** 테스트에서 모든 Dependency가 명시적으로 override됐는가?
- [ ] **I3.** `store.exhaustivity = .off`가 코드에 남아 있지 않은가?
- [ ] **I4.** Delegate 동작에 대한 테스트가 있는가? (자식 → 부모 상호작용)

### J. 코드 스타일

- [ ] **J1.** [CODING_GUIDELINES.md](./CODING_GUIDELINES.md)의 규칙(접근 제어, MARK 구분, 임포트 순서)을 따르는가?
- [ ] **J2.** 강제 언래핑(`!`)이 없는가?
- [ ] **J3.** Action 이름이 [CODING_GUIDELINES §1](./CODING_GUIDELINES.md)의 "이벤트 핸들러 과거형" 규칙과 일치하는가?

---

## 12. 리뷰 출력 형식 (AI 에이전트용)

리뷰 결과는 아래 형식으로 작성한다.

```
## TCA Convention Review

### 🚨 Critical (반드시 수정)
- [D2] ProjectListFeature.swift:42 — switch에 default 케이스가 있음. 모든 Action을 명시적으로 처리해야 함.
- [E2] ProjectListFeature.swift:78 — .run 클로저 안에서 state.id를 직접 참조. 캡처 리스트로 옮길 것.

### ⚠️ Warning (개선 권장)
- [C1] Action `loadProjects` — 명령형. `onAppear` 또는 `didTapRefreshButton`으로 변경 권장.
- [B5] State.filteredProjects가 저장 프로퍼티. computed property로 변경.

### 💡 Suggestion (선택)
- [C5] Action enum이 그룹화되지 않음. View/Internal/Delegate 섹션으로 MARK 구분 권장.

### ✅ Passed
- @Reducer, @ObservableState 모두 적용
- TestStore 기반 테스트 존재 및 Dependency override 정상
```

각 지적에는 **항목 번호([D2] 등)**, **파일:라인**, **위반 내용**, **수정 방향**을 포함한다.
