import SwiftUI

struct VerificationCodeView: View {
    @EnvironmentObject var authCoordinator: AuthCoordinator
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel: VerificationCodeViewModel
    let onNeedRegister: (String, String) -> Void

    init(
        phone: String, countryCode: String, type: AuthVerificationType,
        registration: UserRegisterModel? = nil,
        onNeedRegister: @escaping (String, String) -> Void = { _, _ in }
    ) {
        self.onNeedRegister = onNeedRegister
        _viewModel = StateObject(
            wrappedValue: VerificationCodeViewModel(
                phone: phone, countryCode: countryCode,
                type: type, registration: registration))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                AuthStepIndicator(completed: false)
                LOHAsset.otpIllustration.image
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 390)
                    .accessibilityHidden(true)
                VStack(spacing: 8) {
                    AuthTitle(
                        title: "auth.otp.title".localized, accent: "auth.otp.accent".localized,
                        message: "auth.otp.message".localized)
                    HStack(spacing: 8) {
                        Text("+\(viewModel.countryCode.trimmedPlus) \(viewModel.phone)")
                            .font(AppFont.bold(size: 14))
                            .environment(\.layoutDirection, .leftToRight)
                        Button("auth.edit".localized) {
                            dismiss()
                        }
                        .font(AppFont.button)
                        .foregroundStyle(AppColor.primary)
                        .frame(minHeight: 44)
                    }
                    AuthCodeInput(code: $viewModel.code, hasError: !viewModel.inlineError.isEmpty)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                    if !viewModel.inlineError.isEmpty {
                        Text(viewModel.inlineError)
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.error)
                            .multilineTextAlignment(.center)
                    }
                    if !viewModel.canResendCode {
                        (Text("auth.resendIn".localized)
                            .foregroundColor(AppColor.secondaryText)
                            + Text(" " + viewModel.formattedRemainingTime)
                            .foregroundColor(AppColor.primary))
                            .font(AppFont.regular(size: 13))
                    }
                    HStack(spacing: 4) {
                        Text("auth.noCode".localized)
                            .foregroundStyle(AppColor.secondaryText)
                        Button("auth.resend".localized, action: viewModel.handleResend)
                            .font(AppFont.mediumButton)
                            .foregroundStyle(viewModel.canResendCode ? AppColor.primary : AppColor.mutedText)
                            .disabled(!viewModel.canResendCode || viewModel.submitting)
                            .frame(minHeight: 44)
                    }
                    .font(AppFont.regular(size: 13))
                    MainAppButton(
                        title: "auth.confirmCode".localized, action: viewModel.handleConfirm,
                        isLoading: viewModel.submitting, isEnabled: viewModel.code.count == 4)
                    AuthSecurityNote(text: "auth.codeSecure".localized)
                }
                .padding(.horizontal, 20)
            }
        }
        .disabled(viewModel.submitting)
        .scrollDismissesKeyboard(.interactively)
        .background(
            AppColor.canvas
                .ignoresSafeArea()
        )
        .appNavigationBar("auth.verifyPhone".localized)
        .alert(for: viewModel)
        .onAppear {
            viewModel.resumeTimer()
        }
        .onDisappear {
            viewModel.stopTimer()
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                viewModel.resumeTimer()
            }
        }
        .onChange(of: viewModel.code) { _ in
            viewModel.inlineError = ""
        }
        .onReceive(viewModel.$authResponse) { response in
            guard let response else {
                return
            }
            viewModel.authResponse = nil
            if response.key == "needActive" {
                authCoordinator.handle(response, phone: viewModel.phone, countryCode: viewModel.countryCode)
            } else {
                authCoordinator.handle(
                    response,
                    phone: viewModel.phone,
                    countryCode: viewModel.countryCode,
                    registration: viewModel.registration != nil)
            }
        }
    }
}
