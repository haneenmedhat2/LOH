import SwiftUI

struct HomeSearchView: View {
    @EnvironmentObject private var model: HomeViewModel
    @EnvironmentObject private var coordinator: HomeCoordinator
    @ObservedObject private var language = AppLanguageManager.shared
    @StateObject private var list: HomeOfferListModel
    @StateObject private var searchPage = HomeSearchPageModel()
    @State private var query: String
    @State private var categoryID: Int?
    @State private var submitted: Bool
    @State private var sort: OfferSort?
    @State private var filtersVisible = false
    @State private var quickFilter = "all"
    @State private var optionsError: String?
    @State private var loadingDiscount = false
    @FocusState private var focused: Bool
    var isTabRoot: Bool
    var feed: HomeOfferFeed

    init(
        initialQuery: String = "", initialCategory: OfferCategory = .all, showsResults: Bool = false,
        isTabRoot: Bool = false, feed: HomeOfferFeed = .search, categoryID: Int? = nil
    ) {
        _list = StateObject(wrappedValue: HomeOfferListModel())
        _query = State(
            initialValue: initialQuery.isEmpty && initialCategory != .all
                ? homeText(initialCategory.rawValue) : initialQuery)
        _categoryID = State(initialValue: categoryID)
        _submitted = State(initialValue: showsResults || isTabRoot)
        self.isTabRoot = isTabRoot
        self.feed = feed
    }
    private var request: HomeSearchRequest {
        // Editing any search field switches a curated feed to the search endpoint.
        let effectiveFeed: HomeOfferFeed =
            query.isEmpty && model.filters.count == 0 && sort == nil ? feed : .search
        return HomeSearchRequest(
            feed: effectiveFeed, query: query, cityID: model.resolvedCityID,
            categoryID: categoryID, filters: model.filters, sort: sort)
    }
    private var showsResults: Bool { submitted || !query.isEmpty }
    private var showsLoadingResults: Bool {
        !list.matches(request, language: language.apiLanguage)
            || (!list.hasLoaded && (list.loading || list.error == nil))
    }
    private var title: String {
        homeText(request.feed == .nearby ? "nearby" : request.feed == .endingSoon ? "endingSoon" : "searchTitle")
    }
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                HomeFilterButton(count: activeFilterCount) {
                    focused = false
                    filtersVisible = true
                }
                HStack(spacing: 8) {
                    LOHAsset.search.image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                    TextField(homeText("searchOffer"), text: $query)
                        .font(AppFont.regular(size: 15))
                        .focused($focused)
                        .submitLabel(.search)
                        .onSubmit {
                            search(query)
                        }
                        .autocorrectionDisabled()
                    Button {
                        query = ""
                        submitted = isTabRoot || feed != .search
                    } label: {
                        HomeIcon.close.view(16, color: AppColor.mutedText)
                    }
                    .frame(width: 32, height: 40)
                    .accessibilityLabel(homeText("clearSearch"))
                }
                .padding(.horizontal, 12)
                .frame(height: 46)
                .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColor.primary, lineWidth: 2))

            }
            .padding(.horizontal, 16)
            if showsResults {
                quickFilters
                if activeFilterCount > 0 { activeFilters }
            }
            ScrollView(showsIndicators: false) {
                if showsResults {
                    resultsContent
                } else {
                    suggestions
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .appRefreshable {
                await reload()
            }
        }
        .padding(.top, 12)
        .modifier(HomeScreenStyle(title: title))
        .alert(
            homeText("filterTitle"),
            isPresented: Binding(get: { optionsError != nil }, set: { if !$0 { optionsError = nil } })
        ) {
            Button("more.Done".localized, role: .cancel) {}
        } message: {
            Text(optionsError ?? "")
        }
        .sheet(isPresented: $filtersVisible) {
            HomeFilterSheet(initialCategoryID: categoryID) {
                categoryID = nil
                submitted = true
            }
        }
        .task(id: HomeSearchLoadKey(request: request, showsResults: showsResults, language: language.selectedLanguage))
        {
            do {
                try await Task.sleep(nanoseconds: 300_000_000)
            } catch {
                return
            }
            await reload()
        }
    }
    private func reload() async {
        guard showsResults else {
            await searchPage.load(language: language.apiLanguage, token: UserDefaults.accessToken)
            return
        }
        await list.reload(request, language: language.apiLanguage, token: UserDefaults.accessToken)
        if !Task.isCancelled {
            model.cache(list.offers)
        }
    }
    private var suggestions: some View {
        VStack(alignment: .leading, spacing: 24) {
            if !displayedRecentSearches.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text(searchPage.page?.recentSearches.title ?? homeText("recentSearches"))
                            .font(AppFont.bold(size: 17))
                        Spacer()
                        Button(searchPage.page?.recentSearches.clearTitle ?? homeText("clearAll")) {
                            model.clearRecentSearches()
                        }
                        .font(AppFont.regular(size: 13))
                        .foregroundStyle(AppColor.primary)
                    }
                    LazyVGrid(columns: searchPageColumns, spacing: 8) {
                        ForEach(displayedRecentSearches, id: \.self) { value in
                            HomeSearchRecentChip(title: value) {
                                search(value)
                            } remove: {
                                model.removeRecentSearch(value)
                            }
                        }
                    }
                }
            }
            if !suggestedKeywords.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Text(searchPage.page?.suggestions.title ?? homeText("suggestions"))
                        .font(AppFont.bold(size: 17))
                    LazyVGrid(columns: searchPageColumns, spacing: 8) {
                        ForEach(curatedSuggestions.indices, id: \.self) { index in
                            let suggestion = curatedSuggestions[index]
                            HomeSearchSuggestionTile(
                                title: homeText(suggestion.titleKey), image: suggestion.image
                            ) {
                                search(homeText(suggestion.titleKey))
                            }
                        }
                    }
                    LazyVGrid(columns: searchPageColumns, spacing: 8) {
                        ForEach(suggestedKeywords, id: \.self) { value in
                            Button { search(value) } label: {
                                HStack(spacing: 8) {
                                    HomeIcon.magnifier.view(15)
                                    Text(value).lineLimit(1)
                                    Spacer(minLength: 0)
                                }
                                .padding(12)
                                .frame(height: 48)
                                .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 14))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            if !mostSearchedItems.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Text(searchPage.page?.mostSearched.title ?? homeText("trending") + " " + model.displayedCityName)
                        .font(AppFont.bold(size: 17))
                    VStack(spacing: 0) {
                        ForEach(mostSearchedItems.indices, id: \.self) { index in
                            let item = mostSearchedItems[index]
                            HomeSearchTrendingRow(
                                rank: item.rank ?? (index + 1), keyword: item.keyword,
                                showsDivider: index < mostSearchedItems.count - 1
                            ) {
                                search(item.keyword)
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
    }

    private var searchPageColumns: [GridItem] {
        [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]
    }

    private var curatedSuggestions: [(titleKey: String, image: String)] {
        [
            ("coffeeBreakfast", "lohCategoryCoffeePhoto"),
            ("quickLunch", "lohCategoryBurgerPhoto"),
            ("relax", "lohCategorySpaPhoto"),
            ("weekend", "lohCategoryEntertainmentPhoto")
        ]
    }

    private var suggestedKeywords: [String] {
        searchPage.page?.suggestions.items.compactMap(\.query) ?? []
    }

    private var mostSearchedItems: [HomeSearchPageItem] {
        searchPage.page?.mostSearched.items.filter(\.isDisplayable) ?? []
    }

    private var displayedRecentSearches: [String] {
        let server = model.hidesServerRecentSearches
            ? [] : (searchPage.page?.recentSearches.items.compactMap(\.query) ?? [])
        var seen = Set<String>()
        return Array((model.recentSearches + server).filter {
            let key = $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return !model.hiddenServerRecentKeywords.contains(key) && seen.insert(key).inserted
        }.prefix(6))
    }
    private var resultsContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? homeText("offers") : query)
                        .font(AppFont.extraBold(size: 18))
                        .fixedSize(horizontal: false, vertical: true)
                    if !showsLoadingResults && list.hasLoaded && list.error == nil {
                        Text(
                            homeFormat(
                                "searchResultsCount", homeNumber(list.total), list.cityName ?? model.displayedCityName)
                        )
                        .font(AppFont.regular(size: 12))
                        .foregroundStyle(AppColor.secondaryText)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            if showsLoadingResults {
                HomeSearchLoadingView()
                    .padding(.horizontal, 16)
            } else {
                if let error = list.error {
                    HomeAPIError(message: error) {
                        Task {
                            await list.retry()
                            model.cache(list.offers)
                        }
                    }
                } else if list.hasLoaded && list.offers.isEmpty {
                    HomeEmptyResults {
                        query = ""
                        clearFilters()
                    }
                }

                LazyVStack(spacing: 12) {
                    ForEach(list.offers) { offer in
                        HomeOfferRow(offer: offer) {
                            model.remember(query)
                            focused = false
                            coordinator.show(.offer(offer))
                        }
                    }
                    if list.loading {
                        ProgressView()
                            .tint(AppColor.primary)
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else if list.hasMore {
                        Button("api.loadMore".localized) {
                            Task {
                                await list.loadMore()
                                model.cache(list.offers)
                            }
                        }
                        .font(AppFont.button)
                        .padding()
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.bottom, 20)
    }
    private var activeFilterCount: Int {
        var filters = model.filters
        filters.categoryID = filters.categoryID ?? categoryID
        return filters.count
    }

    private var quickFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(["all", "nearest", "highestDiscount", "available", "price"], id: \.self) { key in
                    HomeChip(title: homeText(key), selected: quickFilter == key, height: 42, cornerRadius: 16) {
                        focused = false
                        submitted = true
                        switch key {
                        case "all": clearFilters()
                        case "nearest":
                            sort = .nearest
                            quickFilter = key
                        case "price":
                            sort = .price
                            quickFilter = key
                        case "available":
                            model.filters.availableOnly.toggle()
                            quickFilter = model.filters.availableOnly ? key : sortQuickFilter
                        default: Task { await selectHighestDiscount() }
                        }
                    }
                    .disabled(key == "highestDiscount" && loadingDiscount)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func selectHighestDiscount() async {
        guard !loadingDiscount else { return }
        loadingDiscount = true
        defer { loadingDiscount = false }
        do {
            if model.filterGroups.isEmpty { try await model.loadFilterOptions(language: language.apiLanguage) }
            guard
                let option = model.filterGroups.first(where: { $0.type == "discount" })?.options
                    .max(by: {
                        ($0.minimum ?? 0) < ($1.minimum ?? 0)
                    })
            else {
                filtersVisible = true
                return
            }
            model.filters.discountOptionID = option.id
            model.filters.discount = Int(min(100, max(0, option.minimum ?? 0)))
            quickFilter = "highestDiscount"
        } catch { optionsError = error.localizedDescription }
    }

    private var distanceFilterLabel: String {
        let maximum = homeNumber(model.filters.distance, decimals: 0)
        if model.filters.minimumDistance == 0 {
            return homeFormat("searchDistanceLimit", maximum)
        }
        return homeFormat("distanceRange", homeNumber(model.filters.minimumDistance, decimals: 0), maximum)
    }

    private var priceFilterLabel: String {
        let minimum = model.filters.minimumPrice
        let hasMaximum = model.filters.hasMaximumPrice || model.filters.maximumPrice != 500
        if minimum > 0 && !hasMaximum { return homeFormat("priceFrom", homeMoney(minimum)) }
        if minimum == 0 && hasMaximum { return homeFormat("priceUpTo", homeMoney(model.filters.maximumPrice)) }
        return homeMoney(minimum) + " – " + homeMoney(model.filters.maximumPrice)
    }

    private var activeFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button(homeText("clearFilters"), action: clearFilters)
                    .font(AppFont.medium(size: 12))
                    .padding(.horizontal, 12)
                    .frame(minHeight: 32)
                    .overlay(Capsule().strokeBorder(AppColor.primary))
                if let id = model.filters.categoryID ?? categoryID {
                    filterTag(
                        (model.filterCategories + model.categories).first(where: { $0.id == id })?.name
                            ?? homeText("categories")
                    ) {
                        categoryID = nil
                        model.filters.categoryID = nil
                    }
                }
                if model.filters.minimumDistance > 0 || model.filters.distance < 10 {
                    filterTag(distanceFilterLabel) {
                        model.filters.minimumDistance = 0
                        model.filters.distance = 10
                    }
                }
                if model.filters.staticPriceID != nil || model.filters.minimumPrice > 0
                    || model.filters.maximumPrice != 500 || model.filters.hasMaximumPrice
                {
                    filterTag(priceFilterLabel) {
                        model.filters.staticPriceID = nil
                        model.filters.minimumPrice = 0
                        model.filters.maximumPrice = 500
                        model.filters.hasMaximumPrice = false
                    }
                }
                if model.filters.discountOptionID != nil {
                    filterTag(
                        optionName(type: "discount", id: model.filters.discountOptionID)
                            ?? homeFormat("discountFormat", homePercent(model.filters.discount))
                    ) {
                        model.filters.discountOptionID = nil
                        model.filters.discount = 0
                        quickFilter = sortQuickFilter
                    }
                }
                if model.filters.availableOnly {
                    filterTag(homeText("available")) {
                        model.filters.availableOnly = false
                        quickFilter = sortQuickFilter
                    }
                }
                if model.filters.endingToday {
                    filterTag(homeText("endsToday")) { model.filters.endingToday = false }
                }
                if model.filters.ratingOptionID != nil {
                    filterTag(
                        optionName(type: "rating", id: model.filters.ratingOptionID) ?? homeNumber(model.filters.rating)
                    ) {
                        model.filters.ratingOptionID = nil
                        model.filters.rating = 0
                    }
                }
            }
            .foregroundStyle(AppColor.primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 2)
        }
    }

    private func optionName(type: String, id: Int?) -> String? {
        model.filterGroups.first(where: { $0.type == type })?.options.first(where: { $0.id == id })?.name
    }

    private func filterTag(_ title: String, remove: @escaping () -> Void) -> some View {
        Button(action: remove) {
            Text(title)
                .font(AppFont.medium(size: 12))
                .padding(.horizontal, 12)
                .frame(minHeight: 30)
                .background(AppColor.accentSurface, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityHint(homeText("removeFilter"))
    }

    private var sortQuickFilter: String {
        switch sort {
        case .nearest: return "nearest"
        case .price: return "price"
        default: return "all"
        }
    }

    private func clearFilters() {
        categoryID = nil
        model.filters = OfferFilters()
        sort = nil
        quickFilter = "all"
        submitted = true
    }

    private func search(_ value: String) {
        query = value
        submitted = true
        focused = false
        model.remember(value)
    }
}
