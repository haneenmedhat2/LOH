import SwiftUI

/// The purchases-guest Figma state. No authenticated requests run from this view.
struct PurchasesGuestView: View {
    let onLogin: () -> Void
    let onRegister: () -> Void
    let onBrowse: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text(homeText("purchases"))
                .font(AppFont.navigationTitle)
                .frame(maxWidth: .infinity, minHeight: 50)
            HStack(spacing: 8) {
                ForEach([PurchaseFilter.all, .ready, .used]) { filter in
                    Text(homeText(filter.titleKey))
                        .font(AppFont.regular(size: 13))
                        .foregroundStyle(AppColor.secondaryText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(AppColor.border))
                }
                Spacer(minLength: 0)
            }
            .opacity(0.4)
            .accessibilityHidden(true)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    PurchasesGuestIllustration()
                    VStack(spacing: 6) {
                        Text(homeText("guestPurchasesTitle"))
                            .font(AppFont.black(size: 19))
                        Text(homeText("purchasesLoginHint"))
                            .font(AppFont.regular(size: 12))
                            .foregroundStyle(AppColor.secondaryText)
                            .lineSpacing(3)
                    }
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    MainAppButton(title: homeText("login"), action: onLogin, variant: .action, height: 45)
                    MainAppButton(title: homeText("register"), action: onRegister, variant: .outlined, height: 47)
                    VStack(alignment: .leading, spacing: 10) {
                        Text(homeText("guestBenefitsTitle"))
                            .font(AppFont.bold(size: 12))
                        VStack(spacing: 0) {
                            benefit("guestReadyBenefit", asset: "lohGuestReady")
                            Divider().overlay(AppColor.border.opacity(0.35))
                            benefit("guestHistoryBenefit", asset: "lohGuestHistory")
                            Divider().overlay(AppColor.border.opacity(0.35))
                            benefit("guestCodeBenefit", asset: "lohGuestCode")
                        }
                    }
                    .padding(14)
                    .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 16))
                    Button(homeText("guestExplore"), action: onBrowse)
                        .font(AppFont.regular(size: 12))
                        .foregroundStyle(AppColor.secondaryText)
                        .frame(minHeight: 44)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                .frame(maxWidth: 500)
                .frame(maxWidth: .infinity)
            }
        }
        .background(AppColor.canvas.ignoresSafeArea())
        .foregroundStyle(AppColor.text)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func benefit(_ key: String, asset: String) -> some View {
        HStack(spacing: 12) {
            Image(asset).resizable().scaledToFit().frame(width: 16, height: 16)
                .frame(width: 32, height: 32)
                .background(AppColor.errorSurface, in: RoundedRectangle(cornerRadius: 12))
                .accessibilityHidden(true)
            Text(homeText(key))
                .font(AppFont.regular(size: 12))
                .foregroundStyle(AppColor.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 10)
    }
}

private struct PurchasesGuestIllustration: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            RadialGradient(colors: [AppColor.primary.opacity(0.08), .clear], center: .center,
                           startRadius: 0, endRadius: 88)
            ZStack(alignment: .topLeading) {
                Image("lohGuestPhone").frame(width: 93.5, height: 133.5).offset(x: 3.25, y: 3.25)
                Image("lohGuestNotch").frame(width: 36, height: 7).offset(x: 32, y: 4)
                Image("lohGuestBag").frame(width: 56, height: 60).offset(x: 22, y: 40)
                Image("lohGuestHandle").frame(width: 35, height: 27).offset(x: 32.5, y: 14.5)
                Text("LOH").font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppColor.primary).frame(width: 56, height: 16).offset(x: 22, y: 66)
                Image("lohGuestDiscount").frame(width: 28, height: 24).offset(x: 52, y: 28)
                Text("%").font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppColor.surface).frame(width: 28, height: 24).offset(x: 52, y: 28)
            }
            .frame(width: 100, height: 140)
            .offset(x: 19, y: 6)
            Image("lohGuestLock").frame(width: 22, height: 22)
                .frame(width: 44, height: 44)
                .background(Color(red: 1, green: 0.8314, blue: 0.7608), in: Circle())
                .overlay(Circle().strokeBorder(AppColor.canvas, lineWidth: 3))
                .offset(x: 138, y: 121)
        }
        .frame(width: 192, height: 176)
        .environment(\.layoutDirection, .leftToRight)
        .accessibilityHidden(true)
    }
}
