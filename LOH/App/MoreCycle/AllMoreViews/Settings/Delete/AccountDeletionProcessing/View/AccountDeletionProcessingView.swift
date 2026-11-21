import SwiftUI

struct AccountDeletionProcessingView: View {
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 32) {
                    SettingsIcon(name: "DeletionProcessing", width: 256)
                    BrandLoaderView(size: 48)
                    VStack(spacing: 8) {
                        Text("deletion.Processing".localized)
                            .font(AppFont.black(size: 28))
                        Text("deletion.Please wait".localized)
                            .font(AppFont.regular(size: 14))
                            .foregroundStyle(AppColor.secondaryText)
                            .padding(.top, 4)
                        HStack(spacing: 8) {
                            SettingsIcon(name: "ProcessingNote", width: 14)
                            Text("deletion.Stay on page".localized)
                                .font(AppFont.regular(size: 13))
                                .foregroundStyle(AppColor.mutedText)
                        }
                    }
                    .multilineTextAlignment(.center)
                    HStack(spacing: 16) {
                        SettingsIcon(name: "ProcessingSecure", width: 24)
                            .frame(width: 48, height: 48)
                            .background(AppColor.accentSurface, in: RoundedRectangle(cornerRadius: 16))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("deletion.Secure processing".localized)
                                .font(AppFont.bold(size: 15))
                            Text("deletion.Secure processing message".localized)
                                .font(AppFont.regular(size: 13))
                                .foregroundStyle(AppColor.secondaryText)
                                .lineSpacing(3)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
                .frame(maxWidth: 440)
                .frame(maxWidth: .infinity)
                .frame(minHeight: geometry.size.height)
            }
        }
        .foregroundStyle(AppColor.text)
        .background(
            AppColor.canvas
                .ignoresSafeArea()
        )
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
    }
}
