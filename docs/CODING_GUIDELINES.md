# Coding Guidelines

Airbnb Swift Style Guide 기반의 macOS SwiftUI 프로젝트 코딩 가이드라인입니다.

---

## 핵심 원칙

- **성능**: 더 이상 상속되지 않을 `class`에는 반드시 `final` 키워드를 붙입니다.
- **안전성**: 강제 언래핑(`!`)을 사용하지 않습니다.
- **안전성**: `unowned` 캡처 대신 `[weak self]` + `guard let self else { return }` 패턴을 사용합니다.
- **명시성**: 약어와 생략을 지양합니다. (`VC` → `ViewController`)
- **명시성**: `extension`의 각 선언에 접근 제어를 개별적으로 명시합니다.
- **간결성**: 쉽게 추론 가능한 타입은 명시하지 않습니다.

---

## 1. 네이밍

### 이벤트 핸들러

이벤트 처리 함수는 **과거형** 형태로 이름을 짓습니다. 주어가 명확하면 생략할 수 있습니다.

```swift
// ✅ Good
private func didTapBookButton() { }
private func modelDidChange() { }

// ❌ Bad
private func handleBookButtonTap() { }
private func bookButtonTapped() { }
```

### 타입 힌트

이름만으로 타입을 추론하기 어려운 경우 타입 힌트를 이름에 포함합니다.

```swift
// ✅ Good
let titleText: String
let cancelButton: NSButton
let profileImageView: NSImageView

// ❌ Bad
let title: String
let cancel: NSButton
```

### 이름 순서

이름은 **일반적인 것 → 구체적인 것** 순으로 작성합니다.

```swift
// ✅ Good
let titleMarginLeft: CGFloat
let titleMarginRight: CGFloat
let bodyMarginLeft: CGFloat

// ❌ Bad
let leftTitleMargin: CGFloat
let rightTitleMargin: CGFloat
```

### 약어

약어로 시작하면 소문자, 그 외에는 모두 대문자로 표기합니다.

```swift
let userID: Int       // 중간 → 대문자
let urlString: String // 시작 → 소문자
let websiteURL: URL   // 끝 → 대문자
let html: String      // 시작 → 소문자
```

---

## 2. 접근 제어

가능한 가장 엄격한 수준으로 설정합니다. `internal`은 기본값이므로 생략합니다.

`public extension` 패턴은 내부 선언이 의도치 않게 공개될 수 있어 사용하지 않습니다.
각 선언에 직접 접근 제어를 명시합니다.

```swift
// ✅ Good
extension Universe {
  public func generateGalaxy() { }
  internal func resetGalaxy() { }
}

// ❌ Bad — generateGalaxy, resetGalaxy 모두 public이 되어버림
public extension Universe {
  func generateGalaxy() { }
  func resetGalaxy() { }
}
```

---

## 3. SwiftUI 뷰 구조

### body 규칙

`var body`에는 **최상위 컨테이너 Stack 하나**만 직접 포함합니다.
세부 레이아웃은 하위뷰 프로퍼티로 분리합니다.

```swift
// ✅ Good
var body: some View {
  VStack(spacing: 16) {
    headerSection
    contentSection
    footerSection
  }
}

// ❌ Bad
var body: some View {
  VStack {
    HStack {
      Image(systemName: "person")
      VStack(alignment: .leading) {
        Text("이름")
        Text("이메일")
      }
    }
    Divider()
    // ... 계속
  }
}
```

### 하위뷰 선언 규칙

하위뷰는 **`extension`에서 `private`으로** 선언합니다.

| 경우 | 선언 방법 |
|---|---|
| 파라미터가 없는 정적인 뷰 | `private var someView: some View` |
| 파라미터가 필요한 동적인 뷰 | `private func someView(param: Type) -> some View` |
| 복잡하거나 재사용되는 뷰 | 별도 View 파일로 분리 |

```swift
struct ContentView: View {

  // MARK: - Body

  var body: some View {
    VStack(spacing: 16) {
      headerSection
      userList
      emptyStateView(message: "데이터가 없습니다")
    }
  }
}

// MARK: - Subviews

extension ContentView {

  private var headerSection: some View {
    HStack {
      Text("타이틀")
        .font(.title)
      Spacer()
    }
  }

  private var userList: some View {
    List(users) { user in
      UserRowView(user: user)
    }
  }

  private func emptyStateView(message: String) -> some View {
    Text(message)
      .foregroundStyle(.secondary)
  }
}
```

### 컴포넌트 분리 기준

다음 조건 중 하나라도 해당하면 별도 View 파일로 분리합니다.

1. 동일한 뷰가 **2곳 이상**에서 사용될 때
2. 하위뷰 자체가 **독립적인 State나 로직**을 갖고 있을 때
3. 분리한 뷰가 **50줄 이상**이 될 것으로 예상될 때

---

## 4. 패턴

### 옵셔널 처리

강제 언래핑 대신 `guard let` / `if let` / `??`를 사용합니다.
동일한 이름으로 바인딩할 때는 단축 구문을 사용합니다.

```swift
// ✅ Good
guard let user else { return }
let name = user.name ?? "Unknown"

// ❌ Bad
let name = user!.name
guard let user = user else { return }
```

값을 사용하지 않을 경우 optional binding 대신 nil 체크를 사용합니다.

```swift
// ✅ Good
if thing != nil { doThing() }

// ❌ Bad
if let _ = thing { doThing() }
```

### 불변성

가능하면 `var` 대신 `let`을 사용하고, 컬렉션 변환 시 `map` / `compactMap` / `filter`를 선호합니다.

```swift
// ✅ Good
let results = input.map { transform($0) }
let active = items.filter { $0.isActive }

// ❌ Bad
var results = [SomeType]()
for element in input {
  results.append(transform(element))
}
```

### 프로퍼티 옵저버

복잡한 프로퍼티 옵저버는 별도 메서드로 추출합니다.

```swift
// ✅ Good
var text: String? {
  didSet { textDidUpdate(from: oldValue) }
}

private func textDidUpdate(from oldValue: String?) {
  guard oldValue != text else { return }
  // side effects
}

// ❌ Bad
var text: String? {
  didSet {
    guard oldValue != text else { return }
    // 긴 side effects 로직...
  }
}
```

### 네임스페이스

전역 상수·함수 그룹화에는 케이스 없는 `enum`을 사용합니다.
`struct`는 인스턴스화가 가능하므로 네임스페이스 용도에 적합하지 않습니다.

```swift
// ✅ Good
enum Constants {
  enum Layout {
    static let padding: CGFloat = 16
    static let cornerRadius: CGFloat = 8
  }
  enum Animation {
    static let duration: CGFloat = 0.3
  }
}

// ❌ Bad
struct Constants {
  static let padding: CGFloat = 16
}
```

---

## 5. 파일 구성

### 코드 순서

파일 내 코드는 아래 순서로 구성합니다.

```text
1. 프로퍼티 (stored → computed 순)
2. init
3. body (SwiftUI View의 경우)
4. 메서드 (public → internal → private 순)
```

### MARK 구분

`// MARK: -` 로 각 섹션을 구분합니다. MARK 위아래에는 반드시 빈 줄을 넣습니다.

```swift
final class ProfileViewModel: ObservableObject {

  // MARK: - Properties

  @Published private(set) var user: User?
  private let userService: UserService

  // MARK: - Init

  init(userService: UserService) {
    self.userService = userService
  }

  // MARK: - Actions

  func didTapLoadButton() {
    Task { await loadUser() }
  }

  // MARK: - Private

  private func loadUser() async { }
}
```

### 임포트 순서

내장 프레임워크를 먼저, 빈 줄로 구분하여 서드파티 프레임워크를 임포트합니다. 각 그룹 내에서 알파벳 순으로 정렬합니다.

```swift
import AppKit
import SwiftUI

import Alamofire
import SnapKit
```
