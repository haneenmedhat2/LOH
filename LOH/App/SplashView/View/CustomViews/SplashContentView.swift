import SwiftUI

struct SplashContentView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                AppColor.canvas
                Circle()
                    .fill(Color(red: 1, green: 0.65, blue: 0.45).opacity(0.09))
                    .frame(width: 300, height: 300)
                    .blur(radius: 85)
                    .position(x: geometry.size.width / 2, y: geometry.size.height * 450 / 844)
                    .accessibilityHidden(true)
                VStack(spacing: 0) {
                    LOHAsset.splashBrandLogo.image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 215, height: 81.47)
                        .accessibilityLabel("LOH")
                    Text("آخر ساعة")
                        .font(AppFont.bold(size: 30))
                        .frame(height: 36)
                        .padding(.top, 41.53)
                    Text("LAST ONE HOUR")
                        .font(AppFont.brandTagline)
                        .tracking(2.4)
                        .padding(.top, 12)
                }
                .foregroundStyle(AppColor.text)
                .position(x: geometry.size.width / 2, y: geometry.size.height * 420 / 844)
                BrandLoaderView(size: 44)
                    .position(x: geometry.size.width / 2, y: geometry.size.height - 58)
            }
        }
        .ignoresSafeArea()
    }
}
