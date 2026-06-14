import SwiftUI
import SwiftData

/// Settings tab: grouped list. Only "Manage categories" is wired for now; other rows
/// arrive with their features.
struct SettingsView: View {
    @AppStorage(currencyCodeKey) private var currencyCode = deviceCurrencyCode()

    var body: some View {
        NavigationStack {
            List {
                Section("Preferences") {
                    NavigationLink {
                        ManageCategoriesView()
                    } label: {
                        Label("Manage categories", systemImage: "tag.fill")
                    }
                    NavigationLink {
                        CurrencyView()
                    } label: {
                        HStack {
                            Label("Currency", systemImage: "dollarsign.circle.fill")
                            Spacer()
                            Text(currencyCode).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .scrollContentBackground(.hidden)
            .background(Palette.bg)
        }
        .tint(Palette.accent)
    }
}

#if DEBUG
#Preview { SettingsView().modelContainer(SampleData.previewContainer()) }
#endif
