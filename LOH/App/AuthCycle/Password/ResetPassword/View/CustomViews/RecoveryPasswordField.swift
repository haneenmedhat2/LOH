import SwiftUI

struct RecoveryPasswordField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var hasError = false
    var errorMessage = ""
    @State private var visible = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(AppFont.fieldLabel)
            HStack(spacing: 12) {
                Image("lohRecoveryFieldLock").resizable().scaledToFit().frame(width: 18, height: 18)
                CustomTextField(text: $text, placeholder: placeholder, isSecure: !visible, contentType: .newPassword)
                Button { visible.toggle() } label: {
                    Image("lohRecoveryEye").resizable().scaledToFit().frame(width: 18, height: 18).frame(width: 44, height: 44)
                }.buttonStyle(.plain)
            }
            .padding(.leading, 16).padding(.trailing, 4).frame(height: AppMetrics.fieldHeight)
            .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(hasError ? AppColor.error : AppColor.border, lineWidth: 1))
            if hasError && !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.error)
            }
        }
    }
}
