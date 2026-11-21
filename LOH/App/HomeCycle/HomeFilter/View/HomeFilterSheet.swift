import SwiftUI

struct HomeFilterSheet: View {
    @EnvironmentObject private var model: HomeViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var draft = OfferFilters()
    @State private var minPrice = ""
    @State private var maxPrice = ""
    var initialCategoryID: Int? = nil
    let apply: () -> Void
    private var priceRange: HomePriceRangeInput { .init(minimumText: minPrice, maximumText: maxPrice) }
    private var validRange: Bool { priceRange.isValid }
    @ObservedObject private var language = AppLanguageManager.shared
    @State private var loading = true
    @State private var error: String?
    private func group(_ type: String) -> HomeFilterGroup? {
        model.filterGroups.first(where: { $0.type == type })
    }
    var body: some View {
        VStack(spacing: 0) {
            HomeSheetHandle()
            HStack(spacing: 8) {
                Text(homeText("filterTitle"))
                    .font(AppFont.extraBold(size: 18))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button(homeText("reset")) {
                    draft = OfferFilters()
                    minPrice = ""
                    maxPrice = ""
                }
                .font(AppFont.regular(size: 14))
                .foregroundStyle(AppColor.primary)
                HomeSheetClose {
                    dismiss()
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if loading {
                        BrandLoaderView(size: 56)
                    }
                    if let error {
                        HomeAPIError(message: error) {
                            Task {
                                await loadOptions()
                            }
                        }
                    }
                    filterSection("filterCategory") {
                        HomeFilterFlowLayout(spacing: 8) {
                            ForEach(model.filterCategories) { category in
                                HomeFilterChip(title: category.name, selected: draft.categoryID == category.id) {
                                    draft.categoryID = draft.categoryID == category.id ? nil : category.id
                                }
                            }
                        }
                    }
                    filterSection("distance") {
                        Text(distanceLabel(minimum: draft.minimumDistance, maximum: draft.distance))
                            .font(AppFont.bold(size: 13))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(AppColor.primary, in: Capsule())
                            .frame(maxWidth: .infinity)
                        HomeDistanceRangeSlider(minimum: $draft.minimumDistance, maximum: $draft.distance)
                        HStack {
                            Text(homeText("lessOneKilometer"))
                            Spacer()
                            Text(homeDistance(10))
                        }
                        .font(AppFont.regular(size: 12))
                        .foregroundStyle(AppColor.mutedText)
                        .environment(\.layoutDirection, .leftToRight)
                    }
                    filterSection("priceRange", serverTitle: group("price")?.title) {
                        HStack(spacing: 8) {
                            priceField("from", value: $minPrice)
                            Text("–")
                                .foregroundStyle(AppColor.mutedText)
                            priceField("to", value: $maxPrice)
                        }
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                            ForEach(group("price")?.options ?? []) { option in
                                HomeFilterChip(
                                    title: option.name, selected: draft.staticPriceID == option.id, expand: true
                                ) {
                                    let selected = draft.staticPriceID != option.id
                                    draft.staticPriceID = selected ? option.id : nil
                                    minPrice = selected ? option.minimum.map(priceText) ?? "" : ""
                                    maxPrice = selected ? option.maximum.map(priceText) ?? "" : ""
                                }
                            }
                        }
                        if !validRange {
                            Text(homeText("invalidRange"))
                                .font(AppFont.regular(size: 12))
                                .foregroundStyle(AppColor.error)
                        }
                    }
                    if let group = group("discount"), !group.options.isEmpty {
                        filterSection("discountRate", serverTitle: group.title) {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                                ForEach(group.options) { option in
                                    HomeFilterChip(
                                        title: option.name, selected: draft.discountOptionID == option.id, expand: true
                                    ) {
                                        draft.discountOptionID = draft.discountOptionID == option.id ? nil : option.id
                                        draft.discount =
                                            draft.discountOptionID == nil
                                            ? 0 : Int(min(100, max(0, option.minimum ?? 0)))
                                    }
                                }
                            }
                        }
                    }
                    filterSection("availability") {
                        Toggle(homeText("available"), isOn: $draft.availableOnly)
                        Toggle(homeText("endsToday"), isOn: $draft.endingToday)
                    }
                    .font(AppFont.regular(size: 15))
                    .tint(AppColor.primary)
                    if let group = group("rating"), !group.options.isEmpty {
                        filterSection("rating", serverTitle: group.title) {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                                ForEach(group.options) { option in
                                    HomeFilterChip(
                                        title: option.name, selected: draft.ratingOptionID == option.id, star: true,
                                        expand: true
                                    ) {
                                        draft.ratingOptionID = draft.ratingOptionID == option.id ? nil : option.id
                                        draft.rating = draft.ratingOptionID == nil ? 0 : (option.minimum ?? 0)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .foregroundStyle(AppColor.text)
        .background(AppColor.surface)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            MainAppButton(
                title: homeText("applyFilters"),
                action: {
                    guard validRange else { return }
                    draft.minimumPrice = priceRange.minimum ?? 0
                    draft.maximumPrice = priceRange.maximum ?? 500
                    draft.hasMaximumPrice = priceRange.hasMaximum
                    model.filters = draft
                    dismiss()
                    apply()
                }, isEnabled: validRange && !loading && error == nil, height: 58
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .background(AppColor.surface)
        }
        .task(id: language.selectedLanguage) {
            await loadOptions()
        }
        .onAppear {
            draft = model.filters
            draft.categoryID = draft.categoryID ?? initialCategoryID
            minPrice = draft.minimumPrice > 0 || draft.staticPriceID != nil ? priceText(draft.minimumPrice) : ""
            maxPrice = draft.hasMaximumPrice || draft.maximumPrice != 500 ? priceText(draft.maximumPrice) : ""
        }
        .presentationDetents([.fraction(0.9)])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(24)
    }
    private func loadOptions() async {
        loading = true
        error = nil
        defer {
            loading = false
        }
        do {
            try await model.loadFilterOptions(language: language.apiLanguage)
        } catch is CancellationError {} catch {
            if !Task.isCancelled {
                self.error = error.localizedDescription
            }
        }
    }
    private func distanceLabel(minimum: Double, maximum: Double) -> String {
        if minimum == 0 {
            return homeFormat("upToDistance", homeNumber(maximum, decimals: 0))
        }
        return homeFormat("distanceRange", homeNumber(minimum, decimals: 0), homeNumber(maximum, decimals: 0))
    }
    private func priceText(_ value: Double) -> String {
        homeNumber(value, decimals: value.rounded() == value ? 0 : 2)
    }
    private func priceField(_ label: String, value: Binding<String>) -> some View {
        HomePriceTextInput(
            text: Binding(get: { value.wrappedValue }, set: {
                value.wrappedValue = $0
                draft.staticPriceID = nil
            }), placeholder: homeText(label == "from" ? "minimumPricePlaceholder" : "maximumPricePlaceholder"))
        .padding(.horizontal, 12)
        .frame(height: 44)
        .frame(maxWidth: .infinity)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColor.border))
    }
    private func filterSection<Content: View>(
        _ title: String, serverTitle: String? = nil, @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(serverTitle ?? homeText(title))
                .font(AppFont.bold(size: 16))
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
