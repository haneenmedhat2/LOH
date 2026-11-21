import SwiftUI

struct HomeOfferStatus: View {
    let text: String
    let isOpen: Bool?
    private var color: Color {
        isOpen == true ? AppColor.success : isOpen == false ? AppColor.error : AppColor.secondaryText
    }
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(text)
                .font(AppFont.regular(size: 11))
        }
        .foregroundStyle(color)
    }
}
