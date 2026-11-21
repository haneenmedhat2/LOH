import SwiftUI

struct HomeCheckoutSteps: View {
    let step: Int
    var processing = false
    var verticalPadding: CGFloat = 20
    private let circleSize: CGFloat = 36
    private let stepWidth: CGFloat = 80
    private let lineHeight: CGFloat = 2

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(1...3, id: \.self) { index in
                VStack(spacing: 8) {
                    stepCircle(index)
                    Text(homeText(index == 1 ? "order" : index == 2 ? "payment" : "done"))
                        .font(index == step ? AppFont.bold(size: 12) : AppFont.regular(size: 12))
                        .foregroundStyle(
                            step == 3 ? AppColor.success : index == step ? AppColor.primary : AppColor.mutedText
                        )
                        .multilineTextAlignment(.center)
                }
                .frame(width: stepWidth)
            }
        }
        .background(alignment: .top) {
            // Each line joins two circle centers, independently of the labels below them.
            HStack(spacing: 0) {
                ForEach(2...3, id: \.self) { index in
                    Rectangle()
                        .fill(step == 3 ? AppColor.success : index <= step ? AppColor.primary : AppColor.border)
                        .frame(width: stepWidth, height: lineHeight)
                }
            }
            .offset(y: (circleSize - lineHeight) / 2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, verticalPadding)
        .background(AppColor.surface)
    }

    private func stepCircle(_ index: Int) -> some View {
        Group {
            if step == 3 && index == 3 {
                Circle()
                    .fill(AppColor.surface)
                    .frame(width: 12, height: 12)
            } else if processing && index == 2 {
                HomeCheckoutProgress()
            } else if index < step || step == 3 {
                LOHAsset.authStepCheck.image
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
            } else {
                Text(homeNumber(index))
                    .font(AppFont.bold(size: 15))
            }
        }
        .foregroundStyle(
            processing && index < step
                ? AppColor.success : index <= step ? AppColor.surface : AppColor.mutedText
        )
        .frame(width: circleSize, height: circleSize)
        .background(
            step == 3
                ? AppColor.success
                : processing
                    ? AppColor.surface : index <= step ? AppColor.primary : AppColor.surface,
            in: Circle()
        )
        .overlay {
            Circle()
                .strokeBorder(
                    processing && index != 2
                        ? AppColor.border : index <= step ? .clear : AppColor.border,
                    lineWidth: 2
                )
        }
    }
}
