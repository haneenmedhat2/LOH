import SwiftUI

struct HomeAPIError: View {
    let message: String
    let retry: () -> Void
    var body: some View {
        VStack(spacing: 10) {
            Text(message)
                .font(AppFont.regular(size: 14))
                .foregroundStyle(AppColor.error)
                .multilineTextAlignment(.center)
            Button("api.retry".localized, action: retry)
                .font(AppFont.button)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
    }
}
