import SwiftUI

struct AppUpdateView: View {
    @ObservedObject var viewModel: AppUpdateViewModel
    @ObservedObject private var language = AppLanguageManager.shared
    @Environment(\.openURL) private var openURL
    @State private var storeOpenFailed = false

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 24) {
                    illustration

                    VStack(spacing: 10) {
                        Text("update.title".localized)
                            .font(AppFont.black(size: 26))
                            .foregroundStyle(AppColor.text)
                            .accessibilityAddTraits(.isHeader)
                        Text("update.description".localized)
                            .font(AppFont.regular(size: 14))
                            .foregroundStyle(AppColor.secondaryText)
                            .lineSpacing(3)
                    }
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                    improvements

                    MainAppButton(title: "update.now".localized, action: openStore, variant: .action, height: 56)

                    HStack(spacing: 8) {
                        Image("lohUpdateExternalLink")
                            .resizable()
                            .frame(width: 14, height: 14)
                            .accessibilityHidden(true)
                        Text("update.storeNote".localized)
                            .font(AppFont.regular(size: 12))
                    }
                    .foregroundStyle(AppColor.mutedText)
                    .frame(maxWidth: .infinity)

                    if storeOpenFailed {
                        Text("update.storeFailed".localized)
                            .font(AppFont.regular(size: 12))
                            .foregroundStyle(AppColor.error)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: 350)
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity, minHeight: geometry.size.height)
            }
            .scrollIndicators(.hidden)
        }
        .foregroundStyle(AppColor.text)
        .background(AppColor.canvas.ignoresSafeArea())
        .environment(\.layoutDirection, language.layoutDirection)
        .environment(\.locale, Locale(identifier: language.selectedLanguage))
    }

    private var illustration: some View {
        Image("lohUpdatePhone")
            .resizable()
            .scaledToFit()
            .frame(maxWidth: 350)
            .frame(height: 240)
            .overlay {
                Circle()
                    .fill(Color(red: 1, green: 240 / 255, blue: 232 / 255))
                    .frame(width: 224, height: 224)
                    .opacity(0.8)
            }
            .overlay(alignment: .bottomTrailing) {
                Image("lohUpdateClock")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .clipShape(Circle().inset(by: 2))
                    .padding(.trailing, 75)
                    .padding(.bottom, 40)
            }
            .environment(\.layoutDirection, .leftToRight)
            .accessibilityHidden(true)
    }

    private var improvements: some View {
        VStack(spacing: 0) {
            Text("update.whatsNew".localized)
                .font(AppFont.bold(size: 16))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)

            improvementRow("update.faster", icon: "lohUpdateSpeed")
            improvementRow("update.security", icon: "lohUpdateSecurity")
            improvementRow("update.fixes", icon: "lohUpdateFixes")
        }
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 16))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func improvementRow(_ key: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(icon)
                .resizable()
                .frame(width: 18, height: 18)
                .frame(width: 36, height: 36)
                .background(AppColor.accentSurface, in: RoundedRectangle(cornerRadius: 12))
                .accessibilityHidden(true)
            Text(key.localized)
                .font(AppFont.medium(size: 14))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .overlay(alignment: .top) {
            Color(red: 242 / 255, green: 242 / 255, blue: 247 / 255)
                .frame(height: 1)
        }
    }

    private func openStore() {
        guard let url = viewModel.requiredRelease?.url else { return }
        storeOpenFailed = false
        openURL(url) { accepted in
            if !accepted { storeOpenFailed = true }
        }
    }
}

#Preview("Required update") {
    AppUpdateView(viewModel: AppUpdateViewModel())
}
