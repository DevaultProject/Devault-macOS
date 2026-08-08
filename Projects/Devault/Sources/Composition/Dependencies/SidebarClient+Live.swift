// Copyright © 2026 Devault. All rights reserved

import Foundation

import ComposableArchitecture
import DVData
import DVDomain
import DVPresentation

extension SidebarClient: @retroactive DependencyKey {
  public static let liveValue: SidebarClient = {
    let repo = LiveRepositories.project

    let fetchUseCase: any FetchProjectUseCase = FetchProjectUseCaseImpl(repository: repo)
    let createUseCase: any CreateProjectUseCase = CreateProjectUseCaseImpl(repository: repo)
    let renameUseCase: any RenameProjectUseCase = RenameProjectUseCaseImpl(repository: repo)
    let deleteUseCase: any DeleteProjectUseCase = DeleteProjectUseCaseImpl(repository: repo)
    let fetchSecretUseCase: any FetchSecretUseCase = FetchSecretUseCaseImpl(
      repository: LiveRepositories.secret,
      cryptoService: SecretCryptoServiceImpl(),
      authenticationService: LocalUserAuthenticationServiceImpl()
    )

    return SidebarClient(
      fetchProjects: {
        do {
          return try await fetchUseCase.fetchAll().map(ProjectItem.init)
        } catch {
          throw SidebarError.fetchFailed
        }
      },
      createProject: { name in
        do {
          return try await ProjectItem(createUseCase.execute(name: name))
        } catch let error as ProjectUseCaseError {
          if case .repositoryFailure(.duplicateName) = error { throw SidebarError.nameTaken }
          throw SidebarError.createFailed
        } catch {
          throw SidebarError.createFailed
        }
      },
      renameProject: { id, name in
        do {
          return try await ProjectItem(renameUseCase.rename(id: id, name: name))
        } catch let error as ProjectUseCaseError {
          if case .repositoryFailure(.duplicateName) = error { throw SidebarError.nameTaken }
          throw SidebarError.renameFailed
        } catch {
          throw SidebarError.renameFailed
        }
      },
      deleteProject: { id in
        do {
          try await deleteUseCase.delete(id: id)
        } catch {
          throw SidebarError.deleteFailed
        }
      },
      fetchCounts: { referenceDate, projectIDs in
        do {
          return try await makeCounts(
            useCase: fetchSecretUseCase,
            referenceDate: referenceDate,
            projectIDs: projectIDs
          )
        } catch {
          throw SidebarError.fetchFailed
        }
      }
    )
  }()
}

/// 필터 5종 + 프로젝트 N개의 개수를 집계한다.
/// 각 집계는 `fetchCount`로 개수만 세므로 엔티티를 메모리에 올리지 않는다.
private func makeCounts(
  useCase: any FetchSecretUseCase,
  referenceDate: Date,
  projectIDs: [ProjectItem.ID]
) async throws -> SecretCounts {
  var byFilter: [SidebarFilter: Int] = [:]
  for filter in SidebarFilter.allCases {
    byFilter[filter] = try await useCase.count(
      query: SecretQuery(collection: filter.collection(referenceDate: referenceDate))
    )
  }

  var byProject: [ProjectItem.ID: Int] = [:]
  for id in projectIDs {
    byProject[id] = try await useCase.count(query: SecretQuery(collection: .project(id: id)))
  }

  return SecretCounts(byFilter: byFilter, byProject: byProject)
}

private extension SidebarFilter {

  /// 필터 카드 → 도메인 컬렉션 매핑. `MainFeature.makeSecretListState`와 같은 기준을 유지해야
  /// 카드에 찍힌 개수와 목록에 뜨는 개수가 어긋나지 않는다.
  func collection(referenceDate: Date) -> SecretQuery.Collection {
    switch self {
    case .all:
      return .all
    case .starred:
      return .liked
    case .notice:
      // TODO: 도메인 레이어에 .notice collection 추가 후 연결 (MainFeature도 동일하게 .all로 매핑 중)
      return .all
    case .expired:
      // 목록의 Expired 탭과 같은 window 계산을 공유한다.
      return .expiringWindow(from: referenceDate)
    case .deleted:
      return .deleted
    }
  }
}
