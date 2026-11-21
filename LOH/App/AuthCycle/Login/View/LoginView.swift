import SwiftUI

struct LoginView: View {
    @StateObject var viewModel = LoginViewModel()
    @EnvironmentObject var authCoordinator: AuthCoordinator

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    AuthHeader(showsLanguage: true)
                    LOHAsset.logo.image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 38)
                        .padding(.top, 20)
                        .padding(.bottom, 20)
                    AuthTitle(
                        title: "auth.login.title".localized, accent: "auth.login.accent".localized,
                        message: "auth.login.message".localized
                    )
                    .padding(.horizontal, 20)
                    VStack(spacing: 20) {
                        PhoneTextView(
                            title: "auth.phone".localized, placeHolder: "5X XXX XXXX",
                            phone: $viewModel.phone, selectedCountry: $viewModel.selectedCountry,
                            forceValidate: $viewModel.forceValidatePhone,
                            hasError: viewModel.phoneHasError, errorMessage: viewModel.phoneError,
                            items: viewModel.countries)
                        RecoveryPasswordField(
                            title: "auth.password".localized,
                            placeholder: "auth.passwordPlaceholder".localized,
                            text: $viewModel.password,
                            hasError: !viewModel.passwordError.isEmpty,
                            errorMessage: viewModel.passwordError)
                        Button("recovery.forgot".localized) {
                            authCoordinator.push(.passwordRecovery)
                        }
                        .font(AppFont.mediumButton)
                        .foregroundStyle(AppColor.primary)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .trailing)
                        MainAppButton(
                            title: "auth.login".localized,
                            action: {
                                viewModel.validateLogin(
                                    model: UserRegisterModel(
                                        phone: viewModel.phone,
                                        countryCode: viewModel.selectedCountry?.countryCode))
                            }, isLoading: viewModel.submitting, isEnabled: viewModel.selectedCountry != nil)
                        MainAppButton(
                            title: "auth.guest".localized, action: authCoordinator.continueAsGuest,
                            variant: .secondary, icon: LOHAsset.person.image)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 32)
                    Spacer(minLength: 48)
                    HStack(spacing: 4) {
                        Text("auth.noAccount".localized)
                            .foregroundStyle(AppColor.text)
                        Button("auth.create".localized) {
                            authCoordinator.push(.register)
                        }
                        .foregroundStyle(AppColor.primary)
                        .font(AppFont.button)
                        .frame(minHeight: 44)
                    }
                    .font(AppFont.body)
                    Spacer(minLength: 32)
                    AuthSecurityNote(text: "auth.secureLogin".localized)
                }
                .frame(minHeight: geometry.size.height)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .disabled(viewModel.submitting)
        .background(
            AppColor.canvas
                .ignoresSafeArea()
        )
        .toolbar(.hidden, for: .navigationBar)
        .alert(for: viewModel)
        .task {
            await viewModel.getCountries()
        }
        .onReceive(viewModel.$authResponse) { response in
            guard let response else {
                return
            }
            viewModel.authResponse = nil
            authCoordinator.handle(
                response, phone: viewModel.phone, countryCode: viewModel.selectedCountry?.countryCode ?? "966")
        }
    }
}
