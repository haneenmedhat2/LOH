import SwiftUI

struct HomeEmptyResults: View {
    let clear: () -> Void
    var body: some View {
        VStack(spacing: 18) {
            ZStack(alignment: .topTrailing) {
                HomeIcon.emptySearch.image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 90)
                HomeIcon.magnifier.view(72)
                    .offset(x: 32, y: -20)
            }
            .frame(height: 160)
            Text(homeText("noResults"))
                .font(AppFont.heading)
            Text(homeText("noResultsHint"))
                .font(AppFont.regular(size: 14))
                .foregroundStyle(AppColor.secondaryText)
                .multilineTextAlignment(.center)
            MainAppButton(title: homeText("clearSearch"), action: clear, variant: .action)
        }
        .padding(16)
        .padding(.top, 30)
    }
}
