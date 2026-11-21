import SwiftUI

struct HomeOfferContent: View {
    @Environment(\.layoutDirection) private var layoutDirection
    @Environment(\.locale) private var locale
    let offer: HomeOffer
    @State private var showsTerms = false

    private var features: [HomeOfferFeature] {
        if offer.isRemote {
            return offer.features
        }
        return [
            .init(key: "one_time_use", title: homeText("singleUse")),
            .init(key: "valid_days", title: homeText("validDays")),
            .init(key: "secure_payment", title: homeText("securePayment"))
        ]
    }

    private var about: String? {
        if offer.isRemote {
            return offer.descriptionText
        }
        return offer.id == "nawa"
            ? homeText("nawaAboutOffer")
            : "\(offer.displayTitle) — \(offer.displayMerchant). \(homeText("exclusivePrice"))"
    }

    private var includes: [String] {
        if offer.isRemote {
            return offer.includedItems
        }
        return offer.id == "nawa"
            ? [homeText("coffeeMedium"), homeText("cookieChoice")]
            : [offer.displayTitle]
    }

    private var terms: [String] {
        if offer.isRemote {
            return offer.terms?.items ?? []
        }
        return [homeText("branchOnly"), homeText("noRefund"), homeText("showCode")]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !features.isEmpty {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                    ForEach(Array(features.enumerated()), id: \.offset) { _, feature in
                        VStack(spacing: 8) {
                            featureIcon(feature.key).view(22)
                            Text(feature.title)
                                .font(AppFont.regular(size: 11))
                                .foregroundStyle(AppColor.secondaryText)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: feature.key == "one_time_use" ? 60 : .infinity)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, minHeight: 88, alignment: .top)
                        .overlay {
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(AppColor.border.opacity(0.5))
                        }
                    }
                }
            }
            if let about, !about.isEmpty {
                separator
                textSection("aboutOffer", text: about)
            }
            if !includes.isEmpty {
                separator
                itemSection("includes", items: includes, color: AppColor.text)
            } else if let text = offer.includesText, !text.isEmpty {
                separator
                textSection("includes", text: text)
            }
            if !terms.isEmpty {
                separator
                VStack(alignment: .leading, spacing: 8) {
                    itemSection("conditions", items: Array(terms.prefix(3)))
                    Button {
                        showsTerms = true
                    } label: {
                        HStack(spacing: 4) {
                            Text(offer.terms?.viewAllLabel ?? homeText("viewAllTerms"))
                                .font(AppFont.medium(size: 13))
                            Image(systemName: "chevron.forward")
                                .font(.system(size: 9, weight: .semibold))
                        }
                        .foregroundStyle(AppColor.primary)
                        .frame(minHeight: 32)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            } else if let text = offer.conditionsText, !text.isEmpty {
                separator
                textSection("conditions", text: text)
            }
            if let branch = offer.branch {
                if branch.latitude != nil, branch.longitude != nil {
                    separator
                    HomeOfferBranchCard(branch: branch)
                }
            } else if !offer.isRemote {
                separator
                previewBranch
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sheet(isPresented: $showsTerms) {
            NavigationStack {
                ScrollView {
                    itemSection("conditions", items: terms)
                        .padding(20)
                }
                .background(Color.white)
                .navigationTitle(homeText("conditions"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(Color.white, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(homeText("close")) {
                            showsTerms = false
                        }
                    }
                }
            }
            .environment(\.layoutDirection, layoutDirection)
            .environment(\.locale, locale)
            .presentationBackground(Color.white)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    private var separator: some View {
        AppColor.border.opacity(0.5)
            .frame(height: 1)
            .padding(.vertical, 4)
    }

    private func featureIcon(_ key: String) -> HomeIcon {
        switch key {
        case "one_time_use": return .ticket
        case "valid_days": return .calendar
        case "secure_payment": return .lock
        default: return .check
        }
    }

    private func textSection(_ title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(homeText(title))
                .font(AppFont.bold(size: 16))
            Text(text)
                .font(AppFont.regular(size: 14))
                .foregroundStyle(AppColor.secondaryText)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func itemSection(_ title: String, items: [String], color: Color = AppColor.secondaryText) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(homeText(title))
                .font(AppFont.bold(size: 16))
            ForEach(Array(items.enumerated()), id: \.offset) { _, text in
                HStack(alignment: .top, spacing: 12) {
                    HomeIcon.check.view(16)
                    Text(text)
                        .font(AppFont.regular(size: 14))
                        .foregroundStyle(color)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var previewBranch: some View {
        HStack(spacing: 12) {
            Image("lohOfferBranchMap")
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 6) {
                Text("\(offer.displayMerchant) · \(homeText("branch"))")
                    .font(AppFont.bold(size: 13))
                HomeOfferStatus(text: homeText("available"), isOpen: true)
                Text(homeText("district"))
                    .font(AppFont.regular(size: 11))
                    .foregroundStyle(AppColor.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            HomeDirectionsButton(merchant: offer.displayMerchant, compact: true)
        }
        .padding(12)
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppColor.border.opacity(0.5))
        }
    }
}
