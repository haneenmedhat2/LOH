import SwiftUI

struct AuthPreferencesView: View {
    let cities: Bool
    @EnvironmentObject private var coordinator: AuthCoordinator
    @EnvironmentObject private var appCoordinator: AppCoordinator
    @State private var options: [AuthOption] = []
    @State private var selection: Set<Int> = []
    @State private var loading = false
    @State private var submitting = false
    @State private var error: String?

    var body: some View {
        VStack(spacing: 20) {
            Text((cities ? "api.selectCities" : "api.selectInterests").localized)
                .font(AppFont.navigationTitle
                )
            if loading {
                BrandLoaderView(size: 56)
            }
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(options) { option in
                        Button {
                            if !selection.insert(option.id).inserted {
                                selection.remove(option.id)
                            }
                        } label: {
                            HStack {
                                Text(option.name)
                                Spacer()
                                Image(systemName: selection.contains(option.id) ? "checkmark.circle.fill" : "circle")
                            }
                            .padding()
                            .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(submitting)
                    }
                }
            }
            if let error {
                Text(error)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.error)
            }
            if options.isEmpty && !loading {
                Button("api.retry".localized) {
                    Task {
                        await load()
                    }
                }
            }
            MainAppButton(
                title: "api.continue".localized,
                action: {
                    Task {
                        await submit()
                    }
                },
                isLoading: submitting, isEnabled: !selection.isEmpty && !loading)
            Button("api.backToLogin".localized) {
                appCoordinator.forgetSession()
            }
            .disabled(submitting)
        }
        .padding(20)
        .background(
            AppColor.canvas
                .ignoresSafeArea()
        )
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await load()
        }
    }
    @MainActor private func load() async {
        guard !loading, let token = UserDefaults.accessToken else {
            return
        }
        loading = true
        error = nil
        defer {
            loading = false
        }
        do {
            options = try await DefaultResponseHandler().data(
                from: AuthEndpoints.options(cities: cities, token: token),
                language: AppLanguageManager.shared.apiLanguage)
            selection = Set(options.filter(\.isSelected).map(\.id))
            if options.isEmpty {
                error = "api.noOptions".localized
            }
        } catch {
            self.error = error.localizedDescription
        }
    }
    @MainActor private func submit() async {
        guard !submitting else {
            return
        }
        submitting = true
        error = nil
        defer {
            submitting = false
        }
        do {
            guard let token = UserDefaults.accessToken else { throw APIError.missingSession }
            if cities && selection.count != 1 { throw APIError.invalidResponse }
            let endpoint = cities
                ? AuthEndpoints.selectCity(id: selection.first ?? 0, token: token)
                : AuthEndpoints.selectInterests(ids: selection.sorted(), token: token)
            try await DefaultResponseHandler().perform(endpoint, language: AppLanguageManager.shared.apiLanguage)
            try await coordinator.refreshSessionAfterSelection()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
