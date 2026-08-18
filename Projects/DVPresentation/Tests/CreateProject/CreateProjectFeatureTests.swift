// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
import Foundation
import Testing

@testable import DVPresentation

@MainActor
@Suite("CreateProjectFeature")
struct CreateProjectFeatureTests {

  @Test("didTapCreate는 이름이 비어 있으면 아무 일도 안 한다")
  func createIgnoresBlankName() async {
    let store = TestStore(initialState: CreateProjectFeature.State()) {
      CreateProjectFeature()
    }

    await store.send(.didChangeName("   ")) {
      $0.name = "   "
    }
    await store.send(.didTapCreate)
  }

  @Test("didTapCreate는 성공하면 delegate로 알리고 dismiss한다")
  func createSucceedsAndDismisses() async {
    let item = ProjectItem(id: UUID(), name: "DeVault")
    var didDismiss = false
    let store = TestStore(initialState: CreateProjectFeature.State()) {
      CreateProjectFeature()
    } withDependencies: {
      $0.sidebarClient.createProject = { _ in item }
      $0.dismiss = DismissEffect { didDismiss = true }
    }

    await store.send(.didChangeName("DeVault")) { $0.name = "DeVault" }
    await store.send(.didTapCreate) { $0.isCreating = true }
    await store.receive(.createResponse(.success(item))) { $0.isCreating = false }
    await store.receive(.delegate(.projectCreated(item)))

    #expect(didDismiss)
  }

  @Test("didTapCreate는 이름 중복 실패 시 nameTaken alert를 띄운다")
  func createShowsNameTakenAlert() async {
    let store = TestStore(initialState: CreateProjectFeature.State()) {
      CreateProjectFeature()
    } withDependencies: {
      $0.sidebarClient.createProject = { _ in throw SidebarError.nameTaken }
    }

    await store.send(.didChangeName("DeVault")) { $0.name = "DeVault" }
    await store.send(.didTapCreate) { $0.isCreating = true }
    await store.receive(.createResponse(.failure(.nameTaken))) {
      $0.isCreating = false
      $0.alert = AlertState {
        TextState(String.module("This project name is already in use."))
      } actions: {
        ButtonState(role: .cancel) { TextState(String.module("OK")) }
      } message: {
        TextState(String.module("Please enter a different name."))
      }
    }
  }

  @Test("didTapCreate는 일반 실패 시 generic alert를 띄운다")
  func createShowsGenericAlertOnFailure() async {
    let store = TestStore(initialState: CreateProjectFeature.State()) {
      CreateProjectFeature()
    } withDependencies: {
      $0.sidebarClient.createProject = { _ in throw SidebarError.createFailed }
    }

    await store.send(.didChangeName("DeVault")) { $0.name = "DeVault" }
    await store.send(.didTapCreate) { $0.isCreating = true }
    await store.receive(.createResponse(.failure(.createFailed))) {
      $0.isCreating = false
      $0.alert = AlertState {
        TextState(String.module("Couldn't create the project."))
      } actions: {
        ButtonState(role: .cancel) { TextState(String.module("OK")) }
      } message: {
        TextState(String.module("Please try again in a moment."))
      }
    }
  }

  @Test("didTapCancel은 dismiss한다")
  func cancelDismisses() async {
    var didDismiss = false
    let store = TestStore(initialState: CreateProjectFeature.State()) {
      CreateProjectFeature()
    } withDependencies: {
      $0.dismiss = DismissEffect { didDismiss = true }
    }

    await store.send(.didTapCancel)

    #expect(didDismiss)
  }
}
