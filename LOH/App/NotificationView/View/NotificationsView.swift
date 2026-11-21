import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject private var appCoordinator: AppCoordinator
    @EnvironmentObject private var notificationsCoordinator: NotificationsCoordinator
    @EnvironmentObject private var model: NotificationsViewModel
    @ObservedObject private var language = AppLanguageManager.shared
    @State private var login = false
    var onOpenOffer: ((Int) -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                LazyVStack(spacing: 12) {
                    if model.requiresSignIn {
                        Text("notifications.loginHint".localized)
                            .font(AppFont.regular(size: 14))
                            .padding(.top, 32)
                        MainAppButton(
                            title: homeText("login"),
                            action: {
                                login = true
                            })
                    } else {
                        if model.loading {
                            BrandLoaderView(size: 56)
                                .padding()
                        }
                        if let error = model.error {
                            HomeAPIError(message: error) {
                                Task {
                                    await model.retry(language: language.apiLanguage)
                                }
                            }
                        }
                        if model.countError != nil && model.error == nil {
                            HomeAPIError(message: "notifications.countUnavailable".localized) {
                                Task {
                                    await model.refreshCount(language: language.apiLanguage)
                                }
                            }
                        }
                        if !model.sections.isEmpty {
                            ForEach(model.sections) { section in
                                VStack(alignment: .leading, spacing: 8) {
                                    if !section.title.isEmpty {
                                        Text(section.title)
                                            .font(AppFont.bold(size: 15))
                                            .foregroundStyle(AppColor.secondaryText)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    ForEach(section.notifications) { item in
                                        NotificationCard(model: item) {
                                            open(item)
                                        }
                                    }
                                }
                            }
                        } else {
                            ForEach(model.notifications) { item in
                                NotificationCard(model: item) {
                                    open(item)
                                }
                            }
                        }
                        if model.loadingMore {
                            BrandLoaderView(size: 56)
                                .padding()
                        } else if model.hasMore && model.error == nil {
                            Button("api.loadMore".localized) {
                                Task {
                                    await model.loadMore()
                                }
                            }
                            .font(AppFont.medium(size: 14))
                            .foregroundStyle(AppColor.primary)
                            .padding(12)
                        }
                    }
                }
                .padding(16)
            }
            .appRefreshable {
                await model.refresh(language: language.apiLanguage)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                if !model.requiresSignIn && model.hasLoaded && model.notifications.isEmpty && !model.loading
                    && model.error == nil
                {
                    emptyPlaceholder
                        .padding(24)
                        .allowsHitTesting(false)
                }
            }
            .disabled(model.mutating)
        }
        .foregroundStyle(AppColor.text)
        .background(
            AppColor.accountCanvas
                .ignoresSafeArea()
        )
        .navigationTitle(homeText("notifications"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(AppColor.surface, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .appNativeNavigationAppearance()
        .toolbar {
            ToolbarItem(placement: .principal) {
                navigationTitle
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                if !model.notifications.isEmpty && !model.requiresSignIn {
                    Button {
                        Task {
                            await model.markAllAsRead(language: language.apiLanguage)
                        }
                    } label: {
                        Text("home.markAllRead".localized)
                            .font(AppFont.medium(size: 13))
                            .foregroundStyle(AppColor.primary)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("home.markAllRead".localized)
                    .disabled(model.mutating)
                }
            }
        }
        .environment(\.layoutDirection, language.layoutDirection)
        .environment(\.locale, Locale(identifier: language.selectedLanguage))
        .overlay {
            if model.mutating {
                BrandLoaderView(size: 56)
                    .padding(24)
                    .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 16))
            }
        }
        .task(id: language.selectedLanguage) {
            await model.refresh(language: language.apiLanguage)
        }
        .onReceive(NotificationCenter.default.publisher(for: .notificationsShouldRefresh)) { _ in
            Task {
                await model.reload(filter: model.filter, language: language.apiLanguage)
            }
        }
        .alert(
            "notifications_title".localized,
            isPresented: Binding(
                get: {
                    model.mutationError != nil
                },
                set: {
                    if !$0 {
                        model.mutationError = nil
                    }
                })
        ) {
            Button("cancel_title".localized, role: .cancel) {
                model.mutationError = nil
            }
        } message: {
            Text(model.mutationError ?? "")
        }
        .sheet(isPresented: $login) {
            HomeLoginSheet(hint: "loginNotificationsHint", destination: .home(.notifications))
        }
    }

    private var emptyPlaceholder: some View {
        VStack(spacing: 12) {
            HomeIcon.bell.view(40, color: AppColor.primary)
            Text("notifications.empty".localized)
                .font(AppFont.bold(size: 16))
            Text("notifications.emptyHint".localized)
                .font(AppFont.regular(size: 14))
                .foregroundStyle(AppColor.secondaryText)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }

    private var navigationTitle: some View {
        HStack(spacing: 8) {
            Text(homeText("notifications"))
                .font(AppFont.navigationTitle)
            if let count = model.count, count > 0 {
                Text(homeNumber(count))
                    .font(AppFont.bold(size: 11))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7)
                    .frame(minWidth: 22, minHeight: 22)
                    .background(AppColor.primary, in: Capsule())
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                ForEach(NotificationsFilter.allCases, id: \.self) { filter in
                    Button {
                        Task {
                            await model.reload(filter: filter, language: language.apiLanguage)
                        }
                    } label: {
                        Text(homeText(filter.rawValue))
                            .font(AppFont.medium(size: 13))
                            .foregroundStyle(model.filter == filter ? .white : AppColor.secondaryText)
                            .padding(.horizontal, 16)
                            .frame(height: 40)
                            .background(
                                model.filter == filter ? AppColor.primary : Color(.systemGray6),
                                in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(model.filter == filter ? .isSelected : [])
                }
                Spacer(minLength: 0)
            }
            .disabled(model.mutating || model.requiresSignIn)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppColor.surface)
    }

    private func open(_ item: NotificationModel) {
        Task {
            await model.markAsRead(id: item.id, language: language.apiLanguage)
        }
        openDestination(for: item)
    }

    private func openDestination(for item: NotificationModel) {
        guard let payload = PushPayload(notification: item) else { return }
        if let id = item.destinationCouponID, let onOpenOffer {
            onOpenOffer(id)
        } else {
            NotificationCenter.default.post(name: .pushDidTap, object: payload)
        }
    }
}

private struct NotificationCard: View {
    let model: NotificationModel
    let onTap: () -> Void

    var body: some View {
        Group {
            if model.destination != nil {
                Button(action: onTap) {
                    content
                }
                .buttonStyle(.plain)
            } else {
                content
            }
        }
    }

    private var content: some View {
        HStack(alignment: .top, spacing: 12) {
            notificationImage
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(model.title)
                        .font(AppFont.bold(size: 14))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(model.time)
                        .font(AppFont.regular(size: 11))
                        .foregroundStyle(AppColor.mutedText)
                        .fixedSize(horizontal: true, vertical: false)
                }
                Text(model.body)
                    .font(AppFont.regular(size: 12))
                    .foregroundStyle(AppColor.secondaryText)
                    .lineSpacing(3)
                if !model.categoryLabel.isEmpty {
                    Text(model.categoryLabel)
                        .font(AppFont.medium(size: 11))
                        .foregroundStyle(AppColor.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(AppColor.primary.opacity(0.1), in: Capsule())
                        .padding(.top, 6)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 16))
        .contentShape(Rectangle())
    }

    private var notificationImage: some View {
        Group {
            if let image = model.image, let url = URL(string: image) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        fallbackImage
                    }
                }
            } else {
                fallbackImage
            }
        }
        .frame(width: 56, height: 56)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppColor.border, lineWidth: 1)
        }
        .overlay(alignment: .topLeading) {
            if !model.isRead {
                Circle()
                    .fill(AppColor.primary)
                    .frame(width: 10, height: 10)
                    .overlay(Circle().stroke(AppColor.surface, lineWidth: 2))
                    .alignmentGuide(.top) { $0[VerticalAlignment.center] }
                    .alignmentGuide(.leading) { $0[HorizontalAlignment.center] }
                    .accessibilityHidden(true)
            }
        }
    }

    private var fallbackImage: some View {
        HomeIcon.bell.view(22, color: AppColor.primary)
            .frame(width: 56, height: 56)
            .background(AppColor.primary.opacity(0.1))
    }
}
