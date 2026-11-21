import SwiftUI

struct PurchaseUsageInstructions: View {
    let usage: PurchaseDetail.UsageInstructions

    var body: some View {
        CardContainer(padding: 16, cornerRadius: 16) {
            VStack(alignment: .leading, spacing: 16) {
                Text(usage.title)
                    .font(AppFont.bold(size: 15))
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(usage.steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 12) {
                            Text(homeNumber(index + 1))
                                .font(AppFont.bold(size: 12))
                                .foregroundStyle(.white)
                                .frame(width: 24, height: 24)
                                .background(AppColor.primary, in: Circle())
                            Text(step)
                                .font(AppFont.regular(size: 13))
                                .foregroundStyle(AppColor.secondaryText)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
