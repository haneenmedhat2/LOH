import SwiftUI

struct ResetPasswordView: View {
    @StateObject private var model: ResetPasswordViewModel
    let onReturnToLogin: () -> Void
    let screenModel = ResetPasswordModel()
    @State private var completed = false
    @Environment(\.dismiss) private var dismiss

    init(phone: String, countryCode: String, code: String, onReturnToLogin: @escaping () -> Void) {
        _model = StateObject(wrappedValue: ResetPasswordViewModel(
            phone: phone, countryCode: countryCode, code: code))
        self.onReturnToLogin = onReturnToLogin
    }

    var body: some View {
        if completed {
            PasswordChangedView(onReturnToLogin: onReturnToLogin)
        } else {
            resetContent
        }
    }

    private var resetContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Image("lohRecoveryShield").resizable().scaledToFit().frame(width: 44, height: 44)
                        .frame(width: 96, height: 96).background(Color("LOHRecoveryGreen"), in: Circle())
                        .frame(maxWidth: .infinity).accessibilityHidden(true)
                    Text(screenModel.title.localized).font(AppFont.extraBold(size: 22))
                    Text(screenModel.message.localized).font(AppFont.regular(size: 14))
                        .foregroundStyle(AppColor.secondaryText).lineSpacing(4)
                }

                RecoveryPasswordField(
                    title: "recovery.newPassword".localized,
                    placeholder: "recovery.newPasswordPlaceholder".localized,
                    text: $model.password)
                RecoveryPasswordField(
                    title: "recovery.confirmPassword".localized,
                    placeholder: "recovery.confirmPlaceholder".localized,
                    text: $model.confirmation)

                if !model.confirmation.isEmpty && model.password != model.confirmation {
                    Text("recovery.passwordError".localized)
                        .font(AppFont.regular(size: 12))
                        .foregroundStyle(AppColor.error)
                }
                if let key = model.errorKey {
                    Text(key.localized)
                        .font(AppFont.regular(size: 13))
                        .foregroundStyle(AppColor.error)
                }

                MainAppButton(
                    title: "recovery.save".localized,
                    action: {
                        Task { completed = await model.save() }
                    },
                    isLoading: model.submitting,
                    isEnabled: model.validPassword)
            }
            .padding(.horizontal, 20)
            .padding(.top, 32)
            .padding(.bottom, 24)
        }
        .disabled(model.submitting)
        .scrollDismissesKeyboard(.interactively)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.canvas.ignoresSafeArea())
        .foregroundStyle(AppColor.text)
        .modifier(AppNavigationBarModifier(title: "recovery.newPassword".localized))
        .toolbar(.visible, for: .navigationBar).toolbar(.hidden, for: .tabBar)
        .toolbarBackground(AppColor.surface, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .logScreen("ResetPasswordView")
    }
}
