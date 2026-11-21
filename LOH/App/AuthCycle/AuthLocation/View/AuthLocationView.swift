import SwiftUI

struct AuthLocationView: View {
    @EnvironmentObject private var coordinator: AuthCoordinator

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image("lohLocationIllustration")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 390, maxHeight: 240)
                    .accessibilityHidden(true)
                AuthTitle(
                    title: "auth.location.title".localized, accent: "auth.location.accent".localized,
                    message: "auth.location.message".localized)
                VStack(spacing: 20) {
                    benefit("mappin.and.ellipse", "nearby", "distance")
                    benefit("map", "cityFirst", "cityContent")
                    benefit("checkmark.shield", "privacy", "privacyDetail")
                }
                .padding(16)
                .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 16))
                Button("auth.location.manual".localized) {
                    coordinator.showCitySelection()
                }
                .font(AppFont.button)
                .foregroundStyle(AppColor.primary)
                .frame(maxWidth: .infinity, minHeight: 58)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(AppColor.primary))
                Text("auth.location.changeLater".localized)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.secondaryText)
            }
            .padding(20)
        }
        .background(
            AppColor.canvas
                .ignoresSafeArea()
        )
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden()
    }

    private func benefit(_ icon: String, _ title: String, _ subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(AppColor.primary)
                .frame(width: 40, height: 40)
                .background(AppColor.primary.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 4) {
                Text(("auth.location." + title).localized)
                    .font(AppFont.bold(size: 14))
                Text(("auth.location." + subtitle).localized)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.secondaryText)
            }
            Spacer()
        }
    }
}
