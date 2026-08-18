// Copyright © 2026 Devault. All rights reserved

import CoreGraphics

// MARK: - WindowLayoutMetrics

/// 창과 컬럼의 너비.
///
/// 창 최소 너비는 컬럼 하한의 합이라 서로 묶여 있다. **합은 직접 적지 않고 계산한다.**
///
/// 폼 안쪽(라벨·입력 슬롯) 너비는 `FormLayoutMetrics`가 갖는다. 여기는 분할 뷰가 나누는 단위만 다룬다.
public enum WindowLayoutMetrics {

  // MARK: - 사이드바

  /// 고정 폭. 범위를 주면 `.balanced`가 폭을 재분배해 가운데가 접힐 때 사이드바가 흔들린다.
  public static let sidebarWidth: CGFloat = 250

  // MARK: - 목록 컬럼

  /// 드래그 하한. 컬럼이 아니라 콘텐츠가 갖는다 — 컬럼 `min`은 접힐 때 `MaxSize <= 0`과 충돌한다.
  public static let listMinWidth: CGFloat = 300
  public static let listIdealWidth: CGFloat = 320
  public static let listMaxWidth: CGFloat = 350

  // MARK: - 상세 컬럼

  /// max는 두지 않는다 — 컬럼이 창을 못 채우면 윈도우 배경이 드러난다.
  public static let detailMinWidth: CGFloat = 420
  public static let detailIdealWidth: CGFloat = 480

  // MARK: - 생성 화면

  /// 이보다 좁으면 SelectSecretType 그리드의 카드가 겹친다.
  public static let createContentMinWidth: CGFloat = 700

  // MARK: - 창

  /// 구분선 두께와 반올림을 흡수하는 여유.
  private static let slack: CGFloat = 30

  public static let browsingMinWidth = sidebarWidth + listMinWidth + detailMinWidth
  public static let creatingMinWidth = sidebarWidth + createContentMinWidth

  /// 두 배치 중 넓은 쪽에 여유를 더한다.
  public static let windowMinWidth = max(browsingMinWidth, creatingMinWidth) + slack
  public static let windowMinHeight: CGFloat = 600

  // MARK: - 설정

  /// 설정 상세 콘텐츠 폭. 최소 창에서 상세 영역을 꽉 채우고, 그 이상에선 이 폭으로 캡한 뒤 가운데 정렬한다.
  public static let settingsDetailWidth = windowMinWidth - sidebarWidth

  /// 하한에 붙여 열면 3컬럼이 전부 최소 폭이라 답답하다.
  public static let windowDefaultWidth: CGFloat = 1120
  public static let windowDefaultHeight: CGFloat = 700
}
