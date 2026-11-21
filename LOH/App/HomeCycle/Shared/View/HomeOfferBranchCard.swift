import SwiftUI

struct HomeOfferBranchCard: View {
    let branch: HomeOfferBranch
    var body: some View {
        HStack(spacing: 12) {
            Image("lohOfferBranchMap")
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                if let name = branch.name {
                    Text(name)
                        .font(AppFont.bold(size: 13))
                }
                if let status = branch.statusText {
                    HomeOfferStatus(text: status, isOpen: branch.isOpen)
                }
                if let address = branch.address, !address.isEmpty {
                    Text(address)
                        .font(AppFont.regular(size: 11))
                        .foregroundStyle(AppColor.secondaryText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if let url = branch.directionsDestination {
                Link(destination: url) {
                    HStack(spacing: 6) {
                        HomeIcon.directions.view(14)
                        Text(branch.directionsLabel ?? homeText("directions"))
                            .font(AppFont.medium(size: 12))
                    }
                    .padding(8)
                    .foregroundStyle(AppColor.primary)
                }
            }
        }
        .padding(12)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColor.border.opacity(0.5)))
    }
}
