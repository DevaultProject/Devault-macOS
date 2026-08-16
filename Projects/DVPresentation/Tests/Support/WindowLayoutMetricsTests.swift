// Copyright © 2026 Devault. All rights reserved

import Testing

@testable import DVPresentation

@Suite("WindowLayoutMetrics")
struct WindowLayoutMetricsTests {

  /// 창이 컬럼 하한의 합보다 좁으면 어느 컬럼이든 하한을 못 지켜 분할 뷰가 폭을 깎기 시작한다.
  @Test("창 최소 너비는 두 배치의 하한을 모두 담는다")
  func windowMinWidthCoversBothLayouts() {
    #expect(WindowLayoutMetrics.windowMinWidth >= WindowLayoutMetrics.browsingMinWidth)
    #expect(WindowLayoutMetrics.windowMinWidth >= WindowLayoutMetrics.creatingMinWidth)
  }

  /// 기본 크기가 하한보다 작으면 창이 열리자마자 하한으로 끌려 올라가 `defaultSize`가 무의미해진다.
  @Test("기본 크기는 최소 크기보다 크다")
  func defaultSizeExceedsMinimum() {
    #expect(WindowLayoutMetrics.windowDefaultWidth >= WindowLayoutMetrics.windowMinWidth)
    #expect(WindowLayoutMetrics.windowDefaultHeight >= WindowLayoutMetrics.windowMinHeight)
  }

  @Test("목록 컬럼 폭은 min ≤ ideal ≤ max")
  func listWidthsAreOrdered() {
    #expect(WindowLayoutMetrics.listMinWidth <= WindowLayoutMetrics.listIdealWidth)
    #expect(WindowLayoutMetrics.listIdealWidth <= WindowLayoutMetrics.listMaxWidth)
  }

  @Test("상세 컬럼 폭은 min ≤ ideal")
  func detailWidthsAreOrdered() {
    #expect(WindowLayoutMetrics.detailMinWidth <= WindowLayoutMetrics.detailIdealWidth)
  }
}
