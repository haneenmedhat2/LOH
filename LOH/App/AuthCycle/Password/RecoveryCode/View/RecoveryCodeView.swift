import SwiftUI

struct RecoveryCodeView: View {
    @StateObject private var model: RecoveryCodeViewModel
    let onReturnToLogin: () -> Void
    @State private var showReset = false
    @State private var verificationCode = ""

    init(phone: String, countryCode: String, onReturnToLogin: @escaping () -> Void) {
        _model = StateObject(wrappedValue: RecoveryCodeViewModel(phone: phone, countryCode: countryCode))
        self.onReturnToLogin = onReturnToLogin
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image("lohRecoveryPhone").resizable().scaledToFit().frame(width: 44, height: 44)
                        .frame(width: 96, height: 96).background(Color("LOHRecoveryBlue"), in: Circle())
                        .accessibilityHidden(true)
                    Text(RecoveryCodeViewModel.title.localized).font(AppFont.extraBold(size: 22))
                    Text(RecoveryCodeViewModel.message.localized)
                        .font(AppFont.regular(size: 14)).foregroundStyle(AppColor.secondaryText)
                        .lineSpacing(4).multilineTextAlignment(.center)
                    Text(RecoveryCodeModel(phone: model.phone, countryCode: model.countryCode).formattedPhone)
                        .font(AppFont.bold(size: 15))
                        .environment(\.layoutDirection, .leftToRight)
                }
                .frame(maxWidth: .infinity)

                AuthCodeInput(code: $model.code, hasError: model.errorKey != nil, cellSize: 64)

                if let errorKey = model.errorKey {
                    Text(errorKey.localized)
                        .font(AppFont.regular(size: 13))
                        .foregroundStyle(AppColor.error)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }

                TimelineView(.periodic(from: .now, by: 1)) { timeline in
                    let seconds = model.remainingSeconds(now: timeline.date)
                    if seconds == 0 {
                        Button("recovery.resend".localized) {
                            Task { await model.resend() }
                        }
                        .disabled(model.submitting)
                        .font(AppFont.button)
                        .foregroundStyle(AppColor.primary)
                        .frame(maxWidth: .infinity, minHeight: 44)
                    } else {
                        Text(String(format: "recovery.resendIn".localized, homeNumber(seconds)))
                            .font(AppFont.regular(size: 14))
                            .foregroundStyle(AppColor.secondaryText)
                            .frame(maxWidth: .infinity)
                    }
                }

                MainAppButton(title: "api.continue".localized, action: {
                    Task {
                        if await model.activate() {
                            verificationCode = model.code
                            showReset = true
                        }
                    }
                }, isLoading: model.submitting, isEnabled: model.code.count == 4)
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
        .modifier(AppNavigationBarModifier(title: "recovery.codeTitle".localized))
        .toolbar(.visible, for: .navigationBar).toolbar(.hidden, for: .tabBar)
        .toolbarBackground(AppColor.surface, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationDestination(isPresented: $showReset) {
            ResetPasswordView(
                phone: model.phone,
                countryCode: model.countryCode,
                code: verificationCode,
                onReturnToLogin: onReturnToLogin)
        }
        .onAppear {
            model.startResendTimer()
        }
        .logScreen("ForgotPasswordOTPView")
    }
}
