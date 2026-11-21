import SwiftUI

struct HomeMerchantAvatar: View {
    let image: String?
    var isNawaPreview = false

    var body: some View {
        Group {
            if isNawaPreview {
                VStack(spacing: 0) {
                    Image("lohMerchantProfileLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                    Text("NAWA")
                        .font(.system(size: 8, weight: .bold))
                        .tracking(1)
                    Text("CAFÉ")
                        .font(.system(size: 6))
                        .tracking(1)
                }
                .foregroundStyle(Color(red: 92 / 255, green: 74 / 255, blue: 50 / 255))
                .frame(width: 80, height: 80)
                .background(Color(red: 245 / 255, green: 240 / 255, blue: 232 / 255))
            } else {
                HomePhoto(asset: image ?? "", contentMode: .fit)
                    .frame(width: 80, height: 80)
            }
        }
        .clipShape(Circle())
        .padding(4)
        .background(AppColor.surface, in: Circle())
        .shadow(color: .black.opacity(0.15), radius: 8, y: 5)
    }
}
