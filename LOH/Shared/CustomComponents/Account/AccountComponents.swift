import SwiftUI

struct AccountPage<Content: View>: View {
    let title: String
    var back = true
    var hidesTabBar = true
    var headerHeight: CGFloat = 56
    var topContent: AnyView? = nil
    var headerBackground: Color = AppColor.surface
    var canvas: Color = AppColor.accountCanvas
    var contentSpacing: CGFloat = 12
    var contentTopPadding: CGFloat = 16
    var onRefresh: (@MainActor () async -> Void)? = nil
    @ViewBuilder var content: Content
    var body: some View {
        VStack(spacing: 0) {
            if !back {
                Text(title)
                    .font(AppFont.navigationTitle)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: headerHeight)
                    .background(headerBackground)
            }
            if let topContent {
                topContent
            }
            if let onRefresh {
                contentScrollView
                    .scrollBounceBehavior(.always)
                    .appRefreshable(action: onRefresh)
            } else {
                contentScrollView
            }
        }
        .font(AppFont.regular(size: 14))
        .foregroundStyle(AppColor.text)
        .background(
            canvas
                .ignoresSafeArea()
        )
        .navigationTitle(back ? title : "")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(!back)
        .toolbar(back ? .visible : .hidden, for: .navigationBar)
        .toolbarBackground(headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .tint(AppColor.primary)
        .appNativeNavigationAppearance()
        .toolbar {
            if back {
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .font(AppFont.navigationTitle)
                        .foregroundStyle(AppColor.text)
                }
            }
        }
        .toolbar(hidesTabBar ? .hidden : .visible, for: .tabBar)
    }

    private var contentScrollView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: contentSpacing) {
                content
            }
            .padding(.horizontal, 16)
            .padding(.top, contentTopPadding)
            .padding(.bottom, 16)
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

struct AccountIcon: View {
    let asset: LOHAsset
    var size: CGFloat = 32
    var body: some View {
        asset.image
            .resizable()
            .scaledToFit()
            .frame(width: size * 0.56, height: size * 0.56)
            .frame(width: size, height: size)
            .background(AppColor.accentSurface, in: RoundedRectangle(cornerRadius: 12))
            .accessibilityHidden(true)
    }
}
struct AccountFooter: View {
    let title: String
    var enabled = true
    let action: () -> Void
    var body: some View {
        MainAppButton(title: title, action: action, variant: .action, isEnabled: enabled, height: 56)
            .padding(16)
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
            .background(AppColor.surface)
    }
}
struct AccountRequestState: ViewModifier {
    @EnvironmentObject private var account: AccountRequestController
    func body(content: Content) -> some View {
        content
            .disabled(account.busy)
            .overlay {
                if account.busy {
                    BrandLoaderView(size: 56)
                        .padding(24)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
            }
            .alert(
                "accountAPI.error".localized,
                isPresented: Binding(
                    get: {
                        account.error != nil
                    },
                    set: {
                        if !$0 {
                            account.error = nil
                        }
                    })
            ) {
                Button("more.Done".localized, role: .cancel) {
                    account.error = nil
                }
            } message: {
                Text(account.error ?? "")
            }
    }
}
