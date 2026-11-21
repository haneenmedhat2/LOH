import SwiftUI

struct HomeSheetClose: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image("lohHomeSheetClose")
                .resizable()
                .scaledToFit()
                .frame(width: 14, height: 14)
                .frame(width: 32, height: 32)
                .background(Color(.systemGray6), in: Circle())
                .frame(width: 44, height: 32)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(homeText("close"))
    }
}
