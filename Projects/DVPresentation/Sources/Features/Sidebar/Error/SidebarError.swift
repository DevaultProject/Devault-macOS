// Copyright © 2026 Devault. All rights reserved

public enum SidebarError: Error, Equatable {
  case fetchFailed
  case createFailed
  case renameFailed
  case deleteFailed
  case nameTaken
}
