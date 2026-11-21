import SwiftUI
import UIKit

struct HomeFavoritesView: View {
    @EnvironmentObject private var model: HomeViewModel
    @EnvironmentObject private var coordinator: HomeCoordinator
    var isTabRoot = false
    @ObservedObject private var language = AppLanguageManager.shared
    var body: some View {
        VStack(spacing: 0) {
            if isTabRoot {
                Text(homeText("favorites"))
                    .font(AppFont.navigationTitle)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(AppColor.surface)
            }
            ScrollView {
                if model.favoritesLoading && !model.favoritesLoaded {
                    BrandLoaderView(size: 56).frame(maxWidth: .infinity).padding(40)
                } else if let error = model.favoritesLoadError {
                    if model.favoritesNeedLogin {
                        VStack(spacing: 16) {
                            Text(homeText("loginFavoriteHint"))
                                .font(AppFont.regular(size: 15))
                                .multilineTextAlignment(.center)
                            MainAppButton(title: homeText("login"), action: { model.showsFavoritesLogin = true })
                        }
                        .padding(24)
                    } else {
                        HomeAPIError(message: error) { Task { await reload() } }
                    }
                } else if model.favoritesLoaded && model.savedOffers.isEmpty {
                    emptyState
                } else if model.favoritesLoaded {
                    savedContent
                }
            }
            .appRefreshable { await reload() }
            .task(id: language.apiLanguage) {
                await reload()
            }
        }
        .foregroundStyle(AppColor.text)
        .background(
            AppColor.canvas
                .ignoresSafeArea()
        )
        .navigationTitle(homeText("favorites"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(isTabRoot)
        .toolbar(isTabRoot ? .hidden : .visible, for: .navigationBar)
        .toolbarBackground(AppColor.surface, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .appNativeNavigationAppearance()
        .toolbar {
            if !isTabRoot {
                ToolbarItem(placement: .principal) {
                    Text(homeText("favorites"))
                        .font(AppFont.navigationTitle)
                        .foregroundStyle(AppColor.text)
                }
            }
        }
    }
    private func reload() async {
        await model.loadFavorites(language: language.apiLanguage)
    }
    private var savedContent: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                Text(homeFormat("savedOffersFormat", homeNumber(model.savedOffers.count)))
                    .font(AppFont.bold(size: 14))
                favoriteIcon("FavoriteCount", size: 18)
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                alignment: .leading, spacing: 12
            ) {
                ForEach(model.savedOffers) { offer in
                    FavoriteOfferCard(offer: offer) {
                        coordinator.show(.offer(offer))
                    }
                }
            }

        }
        .padding(16)
    }
    private var emptyState: some View {
        VStack(spacing: 20) {
            Circle()
                .fill(AppColor.accentSurface)
                .frame(width: 192, height: 192)
                .overlay { HomeIcon.heartFilled.view(64, color: AppColor.primary) }
                .frame(height: 200)
                .accessibilityHidden(true)
            VStack(spacing: 10) {
                Text(homeText("noFavorites"))
                    .font(AppFont.black(size: 24))
                Text(homeText("noFavoritesHint"))
                    .font(AppFont.regular(size: 14))
                    .foregroundStyle(AppColor.secondaryText)
                    .lineSpacing(4)
            }
            .multilineTextAlignment(.center)
            MainAppButton(
                title: homeText("exploreNow"),
                action: {
                    coordinator.show(.results("", .all))
                }, variant: .action, height: 56)
            VStack(spacing: 16) {
                Text(homeText("startHere"))
                    .font(AppFont.bold(size: 15))
                HStack(spacing: 12) {
                    emptyCategory(.restaurants, icon: .emptyRestaurant)
                    emptyCategory(.cafes, icon: .emptyCafe)
                    emptyCategory(.entertainment, icon: .emptyEntertainment)
                }
            }
            .padding(16)
            .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 16))
            HStack(spacing: 8) {
                favoriteIcon("FavoriteEmptyNote", size: 14)
                Text(homeText("unsaveAnytime"))
                    .font(AppFont.regular(size: 13))
                    .foregroundStyle(AppColor.mutedText)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity)
    }
    private func emptyCategory(_ category: OfferCategory, icon: HomeIcon) -> some View {
        Button {
            coordinator.show(.results("", category))
        } label: {
            VStack(spacing: 8) {
                icon.view(28)
                Text(homeText(category.rawValue))
                    .font(AppFont.regular(size: 13))
            }
            .frame(maxWidth: .infinity, minHeight: 82)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColor.border))
        }
        .buttonStyle(.plain)
    }
}

/// Present shared favorite confirmations and errors above Home and pushed offer screens.
struct HomeFavoriteFeedback: View {
    @ObservedObject var model: HomeViewModel
    @ObservedObject private var language = AppLanguageManager.shared
    var body: some View {
        Color.clear
            .overlay(alignment: .top) {
                if let notice = model.favoriteNotice {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(AppColor.primary)
                        Text(homeText(notice.isFavorite ? "favoriteAdded" : "favoriteRemoved"))
                            .font(AppFont.medium(size: 14))
                            .foregroundStyle(AppColor.text)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(AppColor.border))
                    .shadow(color: .black.opacity(0.1), radius: 8, y: 3)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .accessibilityElement(children: .combine)
                }
            }
            .allowsHitTesting(false)
            .task(id: model.favoriteNotice?.id) {
                guard let notice = model.favoriteNotice else { return }
                UIAccessibility.post(
                    notification: .announcement,
                    argument: homeText(notice.isFavorite ? "favoriteAdded" : "favoriteRemoved"))
                do { try await Task.sleep(nanoseconds: 3_000_000_000) } catch { return }
                model.dismissFavoriteNotice(id: notice.id)
            }
            .sheet(isPresented: $model.showsFavoritesLogin) {
                HomeLoginSheet(hint: "loginFavoriteHint", destination: .home(.favorites))
                    .environment(\.layoutDirection, language.layoutDirection)
                    .presentationBackground(AppColor.surface)
            }
            .alert(
                homeText("favorites"),
                isPresented: Binding(
                    get: { model.favoriteError != nil },
                    set: { if !$0 { model.favoriteError = nil } }
                )
            ) {
                Button(homeText("close"), role: .cancel) { model.favoriteError = nil }
            } message: {
                Text(model.favoriteError ?? "")
            }
    }
}
