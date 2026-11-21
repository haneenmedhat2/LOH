import SwiftUI

struct HomeCitySheetHeader: View {
    @Environment(\.layoutDirection) private var layoutDirection
    @Binding var query: String
    let close: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HomeSheetHandle()
            HStack {
                Text(homeText("chooseCity"))
                    .font(AppFont.bold(size: 18))
                Spacer()
                HomeSheetClose(action: close)
            }
            .padding(.vertical, AppSpacing.medium)

            Text(homeText("cityHint"))
                .font(AppFont.regular(size: 13))
                .foregroundStyle(AppColor.secondaryText)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, minHeight: 20, alignment: .leading)
                .padding(.bottom, AppSpacing.medium)

            HStack(spacing: AppSpacing.medium) {
                TextField(
                    homeText("searchCity"), text: $query,
                    prompt: Text(homeText("searchCity"))
                        .foregroundColor(AppColor.mutedText)
                )
                .font(AppFont.regular(size: 15))
                // Keep native input alignment explicit; the surrounding row still mirrors.
                .multilineTextAlignment(layoutDirection == .rightToLeft ? .trailing : .leading)
                .environment(\.layoutDirection, .leftToRight)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .accessibilityLabel(homeText("searchCity"))
                Image("lohHomeCitySearch")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, AppSpacing.standard)
            .padding(.vertical, AppSpacing.medium)
            .frame(minHeight: 48)
            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: AppRadius.standard))
        }
        .foregroundStyle(AppColor.text)
    }
}
