import SwiftUI

struct PasswordRecoveryView: View {
    let onReturnToLogin: () -> Void
    @StateObject private var model = PasswordRecoveryViewModel()
    @State private var countries: [CountriesDataModel] = []
    @State private var selectedCountry: CountriesDataModel?
    @State private var countryLoadError: String?
    @State private var forceValidate = false
    @State private var showCode = false

    init(onReturnToLogin: @escaping () -> Void) {
        self.onReturnToLogin = onReturnToLogin
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Image("lohRecoveryLock").resizable().scaledToFit().frame(width: 44, height: 44)
                    .frame(width: 96, height: 96).background(Color("LOHRecoveryPeach"), in: Circle())
                    .frame(maxWidth: .infinity).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 8) {
                    Text("recovery.forgot".localized).font(AppFont.extraBold(size: 22))
                    Text("recovery.phoneMessage".localized).font(AppFont.regular(size: 14))
                        .foregroundStyle(AppColor.secondaryText).lineSpacing(4)
                }
                PhoneTextView(
                    title: "auth.phone".localized, placeHolder: "5xxxxxxxx", phone: $model.phone,
                    selectedCountry: $selectedCountry, forceValidate: $forceValidate,
                    hasError: model.errorKey == "recovery.invalidPhone", items: countries)
                if let countryLoadError {
                    Text(countryLoadError).font(AppFont.caption).foregroundStyle(AppColor.error)
                }
                MainAppButton(
                    title: "recovery.send".localized,
                    action: {
                        Task {
                            if await model.requestCode(countryCode: selectedCountry?.countryCode?.trimmedPlus ?? "966") {
                                showCode = true
                            }
                        }
                    },
                    isLoading: model.submitting,
                    isEnabled: model.validPhone && selectedCountry != nil)
                HStack(spacing: 8) {
                    Image("lohRecoveryNote").resizable().scaledToFit().frame(width: 14, height: 14)
                    Text("recovery.sendNote".localized)
                        .font(AppFont.regular(size: 12)).foregroundStyle(AppColor.mutedText)
                }
                .frame(maxWidth: .infinity)
                if let key = model.errorKey {
                    Text(key.localized).font(AppFont.regular(size: 13)).foregroundStyle(AppColor.error)
                }
            }
            .padding(.horizontal, 20).padding(.top, 32).padding(.bottom, 24)
        }
        .disabled(model.submitting)
        .scrollDismissesKeyboard(.interactively)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.canvas.ignoresSafeArea())
        .foregroundStyle(AppColor.text)
        .modifier(AppNavigationBarModifier(title: "recovery.title".localized))
        .toolbar(.visible, for: .navigationBar).toolbar(.hidden, for: .tabBar)
        .toolbarBackground(AppColor.surface, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationDestination(isPresented: $showCode) {
            RecoveryCodeView(
                phone: model.phone,
                countryCode: selectedCountry?.countryCode?.trimmedPlus ?? "966",
                onReturnToLogin: onReturnToLogin)
        }
        .task { await loadCountries() }
        .logScreen("ForgotPasswordView")
    }

    private func loadCountries() async {
        guard countries.isEmpty else { return }
        do {
            countries = try await DefaultResponseHandler().data(
                from: CountriesEndpoints.list(), language: AppLanguageManager.shared.apiLanguage)
            selectedCountry = countries.first(where: { $0.countryCode?.trimmedPlus == "966" }) ?? countries.first
        } catch { countryLoadError = error.localizedDescription }
    }
}
