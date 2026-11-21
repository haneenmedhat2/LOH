import SwiftUI

struct CompleteRegisterDataView: View {
    @StateObject private var viewModel: CompleteRegisterDataViewModel
    @EnvironmentObject var authCoordinator: AuthCoordinator

    init(phone: String = "", countryCode: String = "+966", phoneAlreadyVerified: Bool = false) {
        _viewModel = StateObject(
            wrappedValue: CompleteRegisterDataViewModel(
                phone: phone, countryCode: countryCode, phoneAlreadyVerified: phoneAlreadyVerified))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                LOHAsset.logo.image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 90, height: 34)
                AuthTitle(
                    title: "auth.register.accent".localized, accent: "auth.register.title".localized,
                    message: "auth.register.message".localized, accentFirst: true)
                VStack(spacing: 16) {
                    MainAppTextFieldView(
                        text: $viewModel.name, title: "auth.name".localized,
                        placeHolder: "auth.namePlaceholder".localized, submitLabel: .next,
                        keyboardType: .default, leadingImage: LOHAsset.person.image,
                        hasError: !viewModel.nameError.isEmpty, errorMessage: viewModel.nameError)
                    PhoneTextView(
                        title: "auth.phone".localized, placeHolder: "5X XXX XXXX",
                        phone: $viewModel.phone, selectedCountry: $viewModel.selectedCountry,
                        forceValidate: .constant(true), hasError: !viewModel.phoneError.isEmpty,
                        errorMessage: viewModel.phoneError, items: viewModel.countries
                    )
                    .disabled(viewModel.phoneAlreadyVerified)
                    MainAppTextFieldView(
                        text: $viewModel.email, title: "auth.email".localized,
                        placeHolder: "name@example.com", submitLabel: .next, keyboardType: .emailAddress,
                        leadingImage: LOHAsset.mail.image, hasError: !viewModel.emailError.isEmpty,
                        errorMessage: viewModel.emailError)
                    VStack(alignment: .leading, spacing: 8) {
                        RecoveryPasswordField(
                            title: "auth.password".localized,
                            placeholder: "auth.newPasswordPlaceholder".localized,
                            text: $viewModel.password,
                            hasError: !viewModel.passwordError.isEmpty,
                            errorMessage: viewModel.passwordError)
                        PasswordRequirementsView(
                            hasMinimumLength: viewModel.passwordHasMinimumLength,
                            hasUppercase: viewModel.passwordHasUppercase,
                            hasNumber: viewModel.passwordHasNumber)
                    }
                    HStack(spacing: 0) {
                        Button {
                            viewModel.acceptTerms.toggle()
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(viewModel.acceptTerms ? AppColor.primary : AppColor.surface)
                                RoundedRectangle(cornerRadius: 4)
                                    .strokeBorder(AppColor.border)
                                if viewModel.acceptTerms {
                                    Image("lohAuthStepCheck")
                                        .resizable()
                                        .scaledToFit()
                                        .padding(3)
                                }
                            }
                            .frame(width: 20, height: 20)
                            .frame(width: 44, height: 44)
                        }
                        .accessibilityLabel("auth.acceptTerms".localized)
                        .accessibilityValue(
                            viewModel.acceptTerms ? "auth.accepted".localized : "auth.notAccepted".localized)
                        Button {
                            authCoordinator.push(.terms)
                        } label: {
                            (Text("auth.agree".localized)
                                .foregroundColor(AppColor.text)
                                + Text(" ")
                                + Text("auth.terms".localized)
                                .foregroundColor(AppColor.primary))
                                .font(AppFont.regular(size: 12))
                                .multilineTextAlignment(.leading)
                        }
                        Spacer(minLength: 0)
                    }
                    if !viewModel.termsError.isEmpty {
                        Text(viewModel.termsError)
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.error)
                    }
                    MainAppButton(
                        title: "auth.createNew".localized, action: viewModel.submit,
                        isLoading: viewModel.submitting, isEnabled: viewModel.acceptTerms)
                    HStack(spacing: 4) {
                        Text("onboarding.haveAccount".localized)
                            .font(AppFont.body)
                        Button("auth.login".localized) {
                            authCoordinator.returnToLogin()
                        }
                        .font(AppFont.button)
                        .foregroundStyle(AppColor.primary)
                        .frame(minHeight: 44)
                    }
                    AuthSecurityNote(text: "auth.dataSecure".localized)
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 16)
        }
        .disabled(viewModel.submitting)
        .scrollDismissesKeyboard(.interactively)
        .background(
            AppColor.canvas
                .ignoresSafeArea()
        )
        .modifier(AppNavigationBarModifier(title: "", background: AppColor.canvas))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                AuthLanguageButton()
            }
        }
        .alert(for: viewModel)
        .task {
            await viewModel.loadCountries()
        }
        .onReceive(viewModel.verificationRequested) { model in
            authCoordinator.registrationDraft = model
            authCoordinator.push(.verification(phone: model.phone ?? "", countryCode: model.countryCode ?? ""))
        }
        .onReceive(viewModel.$isRegisterSuccess) { success in
            if success {
                authCoordinator.showAccountSuccess()
            }
        }
    }
}
