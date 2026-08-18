// Copyright © 2026 Devault. All rights reserved

import Testing

@testable import DVPresentation

@Suite("AppMenuCommand")
struct AppMenuCommandTests {

  // MARK: - Catalog

  @Test("all은 New Secret·New Project·Lock·Settings 순서로 구성된다")
  func allContainsCommandsInDisplayOrder() {
    #expect(AppMenuCommand.all == [.newSecret, .newProject, .lockVault, .openSettings])
  }

  // MARK: - displayKeys (Shortcuts 설정 화면에 표시될 문자열)

  @Test("New Secret의 표시 단축키는 ⌘N이다")
  func newSecretDisplayKeys() {
    #expect(AppMenuCommand.newSecret.displayKeys == "⌘N")
  }

  @Test("New Project의 표시 단축키는 ⇧⌘N이다 (Shift가 Command 앞)")
  func newProjectDisplayKeys() {
    #expect(AppMenuCommand.newProject.displayKeys == "⇧⌘N")
  }

  @Test("Lock의 표시 단축키는 ⌃⌘L이다 (Control이 Command 앞)")
  func lockDisplayKeys() {
    #expect(AppMenuCommand.lockVault.displayKeys == "⌃⌘L")
  }

  @Test("Settings의 표시 단축키는 ⌘,이다")
  func settingsDisplayKeys() {
    #expect(AppMenuCommand.openSettings.displayKeys == "⌘,")
  }

  // MARK: - action (메뉴 선택 시 store로 보낼 액션)

  @Test("New Secret은 사이드바 추가 버튼 액션을 보낸다")
  func newSecretAction() {
    #expect(AppMenuCommand.newSecret.action == .main(.sidebar(.didTapAddButton)))
  }

  @Test("New Project는 사이드바 프로젝트 추가 액션을 보낸다")
  func newProjectAction() {
    #expect(AppMenuCommand.newProject.action == .main(.sidebar(.didTapAddProject)))
  }

  @Test("Lock은 잠금 액션을 보낸다")
  func lockAction() {
    #expect(AppMenuCommand.lockVault.action == .main(.didTapLock))
  }

  @Test("Settings는 사이드바 설정 액션을 보낸다")
  func settingsAction() {
    #expect(AppMenuCommand.openSettings.action == .main(.sidebar(.didTapSettings)))
  }
}
