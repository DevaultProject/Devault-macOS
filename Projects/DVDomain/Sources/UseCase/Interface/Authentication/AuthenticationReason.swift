// Copyright © 2026 Devault. All rights reserved

/// 시스템 인증 시트(Touch ID·암호)에 표시할 문구.
///
/// 한곳에 모으는 이유는 **같은 동작이 경로에 따라 다른 문장을 보여주지 않게** 하려는 것이다.
/// 시크릿 값 열람은 첫 복호화(`RevealSecretPayloadUseCase`)와 인증 창 만료 후 재인증(조회 화면)으로
/// 갈리는데, 사용자에게는 눈 버튼 하나를 누른 것일 뿐이다.
///
/// 리터럴인 것은 `UserAuthenticationService`가 `String`을 받고 DVDomain에 문자열 카탈로그가
/// 없기 때문이다. 잠금 해제·온보딩 문구도 각 Client에 리터럴로 흩어져 있어, 인증 문구 전체를
/// 프레젠테이션에서 주입하도록 바꾸는 것은 별도 정리 대상이다.
public enum AuthenticationReason {

    /// 시크릿 값 열람. 첫 복호화와 재인증이 같은 문구를 쓴다.
    public static let revealSecret = "시크릿 값을 확인하려면 인증이 필요합니다"

    /// 시크릿 값 복사. 복사 시 인증 설정이 켜진 경우에만 사용한다.
    public static let copySecret = "시크릿 값을 복사하려면 인증이 필요합니다"
}
