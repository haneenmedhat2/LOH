import SwiftUI

struct AccountSecurityView: View {
    @EnvironmentObject private var coordinator: MoreCoordinator
    @ObservedObject private var language = AppLanguageManager.shared
    @StateObject private var document = AccountDocumentViewModel()
    private let viewModel = AccountSecurityViewModel()

    var body: some View {
        AccountPage(
            title: "more.Security and privacy".localized,
            hidesTabBar: true, headerHeight: 56,
            headerBackground: AppColor.accountCanvas, contentTopPadding: 0
        ) {
            if document.loading {
                BrandLoaderView(size: 56)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else if let error = document.error {
                VStack(spacing: 12) {
                    Text(error)
                        .foregroundStyle(AppColor.error)
                        .multilineTextAlignment(.center)
                    Button("accountAPI.retry".localized) {
                        Task {
                            await reload()
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else if let content = document.content {
                AccountSecurityContentView(content: content) {
                    coordinator.show(viewModel.policyRoute)
                }
            }
        }
        .task(id: language.selectedLanguage) {
            await reload()
        }
    }

    private func reload() async {
        await document.load(endpoint: viewModel.content.endpoint, language: language.apiLanguage)
    }
}
