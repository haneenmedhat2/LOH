import SwiftUI

struct MaintenanceView: View {
    @ObservedObject var viewModel: MaintenanceViewModel
    @ObservedObject private var language = AppLanguageManager.shared
    @Environment(\.openURL) private var openURL

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 24) {
                    Image("lohMaintenance")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 260, height: 230)
                        .frame(maxWidth: .infinity, minHeight: 260)
                        .accessibilityHidden(true)

                    message
                    reassurance

                    MainAppButton(
                        title: "maintenance.retry".localized,
                        action: { Task { await viewModel.retry() } },
                        variant: .action,
                        isLoading: viewModel.isRetrying,
                        height: 56
                    )

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(AppFont.body)
                            .foregroundStyle(AppColor.secondaryText)
                            .multilineTextAlignment(.center)
                            .accessibilityAddTraits(.updatesFrequently)
                    }

                    MainAppButton(
                        title: "maintenance.contactSupport".localized,
                        action: openContactPage,
                        variant: .outlined,
                        height: 56
                    )
                }
                .frame(maxWidth: 430)
                .padding(.horizontal, 20)
                .padding(.vertical, 32)
                .frame(maxWidth: .infinity, minHeight: geometry.size.height)
            }
            .scrollIndicators(.hidden)
        }
        .foregroundStyle(AppColor.text)
        .background(AppColor.canvas.ignoresSafeArea())
        .environment(\.layoutDirection, language.layoutDirection)
        .environment(\.locale, Locale(identifier: language.selectedLanguage))
    }

    private func openContactPage() {
        guard let url = URL(string: "https://upgrade.loh.com.sa/contact-us-page") else { return }
        openURL(url)
    }

    private var message: some View {
        VStack(spacing: 12) {
            Text("maintenance.title".localized)
                .font(AppFont.black(size: 28))
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 8) {
                Text("maintenance.description".localized)
                    .lineSpacing(5)
                Text("maintenance.tryLater".localized)
            }
            .font(AppFont.regular(size: 14))
            .foregroundStyle(AppColor.secondaryText)
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity)
    }

    private var reassurance: some View {
        HStack(spacing: 12) {
            Image("lohMaintenanceShield")
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .frame(width: 40, height: 40)
                .background(AppColor.accentSurface, in: RoundedRectangle(cornerRadius: 12))
                .accessibilityHidden(true)

            Text("maintenance.note".localized)
                .font(AppFont.regular(size: 14))
                .foregroundStyle(AppColor.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview("Maintenance") {
    MaintenanceView(viewModel: MaintenanceViewModel())
}
