import SwiftUI

struct AuthCitySelectionView: View {
    @EnvironmentObject private var coordinator: AuthCoordinator
    @StateObject private var viewModel = AuthCitySelectionViewModel()

    var body: some View {
        VStack(spacing: 20) {
            AuthHeader(title: "auth.location.chooseCity".localized)
            Image("lohLocationIllustration")
                .resizable()
                .scaledToFit()
                .frame(height: 120)
                .accessibilityHidden(true)
            Text("auth.location.chooseCity".localized)
                .font(AppFont.heading)
            Text("auth.location.cityMessage".localized)
                .font(AppFont.regular(size: 15))
                .foregroundStyle(AppColor.secondaryText)
                .multilineTextAlignment(.center)
            TextField("auth.location.search".localized, text: $viewModel.query)
                .font(AppFont.regular(size: 14))
                .padding(14)
                .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 12))
            if viewModel.loading {
                BrandLoaderView(size: 56)
            }
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.filteredOptions) { option in
                        Button {
                            viewModel.selected = option.id
                        } label: {
                            HStack {
                                Text(option.name)
                                    .font(AppFont.bold(size: 16))
                                Spacer()
                                Image(
                                    systemName: viewModel.selected == option.id
                                        ? "largecircle.fill.circle" : "circle")
                                    .foregroundStyle(AppColor.primary)
                            }
                            .padding(16)
                            .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                    if !viewModel.loading && viewModel.filteredOptions.isEmpty {
                        Text("api.noOptions".localized)
                            .font(AppFont.caption)
                    }
                }
            }
            if let error = viewModel.error {
                Text(error)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.error)
                if viewModel.options.isEmpty {
                    Button("api.retry".localized) {
                        Task {
                            await viewModel.load()
                        }
                    }
                }
            }
            AuthSecurityNote(text: "auth.location.privacyDetail".localized)
            MainAppButton(
                title: "api.continue".localized,
                action: {
                    Task {
                        if await viewModel.submit() {
                            coordinator.loginSucceeded()
                        }
                    }
                },
                isLoading: viewModel.submitting,
                isEnabled: viewModel.selected != nil && !viewModel.loading)
        }
        .padding(20)
        .disabled(viewModel.submitting)
        .background(
            AppColor.canvas
                .ignoresSafeArea()
        )
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden()
        .task {
            await viewModel.load()
        }
    }
}
