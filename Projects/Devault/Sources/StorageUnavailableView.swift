import SwiftUI

/// 임시 fallback UI
struct StorageUnavailableView: View {
    let error: Error

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("로컬 저장소를 열 수 없습니다")
                .font(.headline)
            
            Text("Devault가 암호화된 로컬 데이터베이스를 불러오지 못했습니다. 앱을 다시 실행하거나, 백업이 있다면 복원 절차를 진행해 주세요.")
                .font(.body)
            
            Text("오류 정보")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            
            Text(error.localizedDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        }
        .padding(24)
        .frame(minWidth: 420, idealWidth: 520, maxWidth: 640, alignment: .leading)
    }
}
