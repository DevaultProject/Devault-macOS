// Copyright © 2026 Devault. All rights reserved

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
      }
    )
  }()
}
