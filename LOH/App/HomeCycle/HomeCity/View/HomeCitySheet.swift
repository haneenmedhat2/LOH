import SwiftUI

struct HomeCitySheet: View {
    @EnvironmentObject private var model: HomeViewModel
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var language = AppLanguageManager.shared
    @State private var query = ""
    @State private var selection: Int?
    @State private var options: [AuthOption] = []
    @State private var loading = false
    @State private var saving = false
    @State private var error: String?
    private var cities: [AuthOption] {
        options.filter { query.isEmpty || $0.name.localizedStandardContains(query) }
    }
    var body: some View {
        VStack(spacing: 16) {
            HomeCitySheetHeader(query: $query) {
                dismiss()
            }
            if loading {
                BrandLoaderView(size: 56)
            }
            if let error {
                HomeAPIError(message: error) {
                    Task {
                        await load()
                    }
                }
            }
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(cities) { city in
                        Button {
                            selection = city.id
                        } label: {
                            HStack(spacing: 12) {
                                HomeRadio(selected: selection == city.id)
                                Text(city.name)
                                    .font(AppFont.bold(size: 16))
                                Spacer()
                                if model.resolvedCityID == city.id {
                                    Text(homeText("currentCity"))
                                        .font(AppFont.caption)
                                        .foregroundStyle(AppColor.success)
                                }
                            }
                            .padding(16)
                            .background(AppColor.canvas, in: RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                    if cities.isEmpty && !loading && error == nil {
                        Text(homeText("noCities"))
                            .font(AppFont.regular(size: 14))
                    }
                }
            }
            MainAppButton(
                title: homeText("confirmCity"),
                action: {
                    Task {
                        await save()
                    }
                },
                isLoading: saving, isEnabled: selection != nil && !loading)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .disabled(saving)
        .background(AppColor.surface)
        .interactiveDismissDisabled(saving)
        .task(id: language.selectedLanguage) {
            await load()
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .logScreen("HomeCitySheet")
    }
    private func load() async {
        loading = true
        error = nil
        defer {
            loading = false
        }
        do {
            options = try await DefaultResponseHandler().data(
                from: HomeEndpoints.cities(token: UserDefaults.accessToken), language: language.apiLanguage)
            selection = model.resolvedCityID
        } catch {
            if !Task.isCancelled {
                self.error = error.localizedDescription
            }
        }
    }
    private func save() async {
        guard !saving, let option = options.first(where: { $0.id == selection }) else {
            return
        }
        saving = true
        error = nil
        defer {
            saving = false
        }
        do {
            try await model.selectCity(option)
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
