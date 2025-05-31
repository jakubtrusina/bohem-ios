import SwiftUI

struct SideMenu: View {
    @Binding var isVisible: Bool
    @Binding var expandedCategory: String?
    var onCategorySelected: (String, String?) -> Void
    var onBrandSelected: (Brand) -> Void
    var onProfileTapped: () -> Void
    var onSettingsTapped: () -> Void

    private let mainCategories = [
        "Novinky",
        "Dámské Oblečení",
        "Dámské Plavky",
        "Doplňky",
        "O Značce",
        "Profil",
        "Nastavení"
    ]

    private let subcategories: [String: [String]] = [
        "Dámské Oblečení": ["Šaty", "Dámská Trička", "Kabát", "Kalhoty", "Mikiny", "Sukně"],
        "Dámské Plavky": ["Jednodílné", "Horní díl", "Spodní díl"],
        "Doplňky": ["Náhrdelníky", "Náramky", "Náušnice", "Pásky", "Prstýnky", "Tašky"]
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // MARK: - Close Button
            HStack {
                Button(action: {
                    AnalyticsManager.shared.logEvent(.buttonClick, params: [
                        "screen": "SideMenu",
                        "button_id": "close_menu"
                    ])
                    isVisible = false
                }) {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundColor(.black)
                }
                Text("Zavřít")
                    .font(.headline)
                    .foregroundColor(.black)
            }
            .padding(.horizontal)

            Divider()

            // MARK: - Categories
            ForEach(mainCategories, id: \.self) { category in
                VStack(alignment: .leading, spacing: 4) {
                    if let subs = subcategories[category] {
                        // Expandable
                        Button {
                            withAnimation {
                                expandedCategory = (expandedCategory == category) ? nil : category
                            }
                        } label: {
                            HStack {
                                Text(category)
                                Spacer()
                                Image(systemName: expandedCategory == category ? "chevron.up" : "chevron.down")
                            }
                            .foregroundColor(.black)
                            .font(.system(size: 18, weight: .medium))
                            .padding(.horizontal)
                        }

                        if expandedCategory == category {
                            ForEach(subs, id: \.self) { sub in
                                Button {
                                    AnalyticsManager.shared.logCustomEvent(name: "side_menu_nav", params: [
                                        "screen": "SideMenu",
                                        "main_category": category,
                                        "subcategory": sub
                                    ])
                                    onCategorySelected(category, sub)
                                    isVisible = false
                                } label: {
                                    Text("• \(sub)")
                                        .foregroundColor(.black)
                                        .padding(.leading, 40)
                                }
                            }
                        }
                    } else if category == "Profil" {
                        Button {
                            AnalyticsManager.shared.logCustomEvent(name: "side_menu_nav", params: [
                                "screen": "SideMenu",
                                "destination": "profile"
                            ])
                            onProfileTapped()
                            isVisible = false
                        } label: {
                            Text("Profil")
                                .foregroundColor(.black)
                                .font(.system(size: 18, weight: .medium))
                                .padding(.horizontal)
                        }
                    } else if category == "Nastavení" {
                        Button {
                            AnalyticsManager.shared.logCustomEvent(name: "side_menu_nav", params: [
                                "screen": "SideMenu",
                                "destination": "settings"
                            ])
                            onSettingsTapped()
                            isVisible = false
                        } label: {
                            HStack {
                                Image(systemName: "gearshape")
                                    .font(.body)
                                Text("Nastavení")
                                    .font(.system(size: 18, weight: .medium))
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal)
                        }
                    } else {
                        Button {
                            AnalyticsManager.shared.logCustomEvent(name: "side_menu_nav", params: [
                                "screen": "SideMenu",
                                "main_category": category
                            ])
                            handleStaticCategory(category)
                        } label: {
                            Text(category)
                                .foregroundColor(.black)
                                .font(.system(size: 18, weight: .medium))
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            Spacer()
        }
        .padding(.top)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.ignoresSafeArea())
    }

    // MARK: - Static Navigation Handler
    private func handleStaticCategory(_ category: String) {
        switch category {
        case "O Značce":
            Task {
                if let brand = try? await BrandManager.shared.getBrandByName("Terezie Trusinová") {
                    onBrandSelected(brand)
                }
            }
        case "Novinky":
            onCategorySelected("Dámské Oblečení", nil)
        default:
            onCategorySelected(category, nil)
        }

        isVisible = false
    }
}
