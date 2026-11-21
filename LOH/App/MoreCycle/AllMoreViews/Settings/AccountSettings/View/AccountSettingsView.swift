import SwiftUI

struct AccountSettingsView: View {
    @EnvironmentObject private var coordinator: MoreCoordinator
    private let viewModel = AccountSettingsViewModel()
    var body: some View {
        AccountPage(title: "more.Settings".localized, headerHeight: 60) {
            ForEach(visibleGroups) { group in
                settingsGroup(group.title.localized) {
                    ForEach(group.items) { item in
                        SettingsRow(
                            title: item.title.localized, subtitle: item.subtitle.isEmpty ? "" : item.subtitle.localized,
                            icon: item.icon, value: item.showsLanguage ? (AppLang.isRTL ? "العربية" : "English") : ""
                        ) {
                            coordinator.show(item.route)
                        }
                        if item.id != group.items.last?.id {
                            Divider()
                                .opacity(0.4)
                        }
                    }
                }
            }
            Text("more.Version".localized + " " + viewModel.version)
                .font(AppFont.regular(size: 11))
                .foregroundStyle(AppColor.mutedText)
                .frame(maxWidth: .infinity)
                .padding(.top, 28)
            if UserDefaults.accessToken != nil {
                Button("more.Delete account".localized) {
                    coordinator.show(.deleteAccount)
                }
                .font(AppFont.regular(size: 12))
                .foregroundStyle(AppColor.mutedText)
                .frame(maxWidth: .infinity, minHeight: 44)
            }
        }
    }
    private var visibleGroups: [AccountSettingsGroup] {
        viewModel.groups.compactMap { group in
            let items = group.items.filter { UserDefaults.accessToken != nil || !$0.route.requiresAccount }
            return items.isEmpty ? nil : AccountSettingsGroup(title: group.title, items: items)
        }
    }
    private func settingsGroup<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(AppFont.bold(size: 12))
                .foregroundStyle(AppColor.secondaryText)
                .padding(.horizontal, 4)
            VStack(spacing: 0, content: content)
                .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 16))
        }
        .padding(.bottom, 4)
    }
}
