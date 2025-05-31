import SwiftUI

struct HelpPageView: View {
    var body: some View {
        VStack(spacing: 0) {
            Text("Nápověda a podpora")
                .font(.largeTitle.bold())
                .padding(.top, 20)
                .foregroundColor(.black)

            List {
                Section {
                    NavigationLink(destination: HelpDetailView(
                        title: "Nákupy a objednávky",
                        content: """
                        Prohlížejte naše pečlivě vybrané kolekce, přidejte si produkty do košíku a dokončete nákup pomocí Apple Pay nebo platební karty. Každý produkt je před odesláním pečlivě zkontrolován. Stav objednávky můžete sledovat ve svém profilu.
                        """
                    )) {
                        HStack {
                            Image(systemName: "bag")
                            Text("Nákupy a objednávky")
                        }.foregroundColor(.black)
                    }
                }

                Section {
                    NavigationLink(destination: HelpDetailView(
                        title: "Doprava a doručení",
                        content: """
                        Nabízíme dopravu zdarma na všechny objednávky v rámci ČR. Doručení obvykle trvá 3–5 pracovních dnů. Jakmile bude objednávka odeslána, obdržíte e-mail s číslem pro sledování zásilky.
                        """
                    )) {
                        HStack {
                            Image(systemName: "truck")
                            Text("Doprava a doručení")
                        }.foregroundColor(.black)
                    }
                }

                Section {
                    NavigationLink(destination: HelpDetailView(
                        title: "Vrácení a výměna zboží",
                        content: """
                        Zboží můžete vrátit do 14 dnů od doručení. Musí být nenošené, v původním obalu a s visačkami. Pro zahájení vrácení nás kontaktujte na support@bohemapp.com a uveďte číslo objednávky.
                        """
                    )) {
                        HStack {
                            Image(systemName: "arrow.uturn.left")
                            Text("Vrácení a výměna zboží")
                        }.foregroundColor(.black)
                    }
                }

                Section {
                    NavigationLink(destination: HelpDetailView(
                        title: "Kontaktujte nás",
                        content: """
                        Máte dotaz? Rádi vám pomůžeme. Napište nám na support@bohemapp.com a odpovíme vám do 24 hodin.
                        """
                    )) {
                        HStack {
                            Image(systemName: "envelope")
                            Text("Kontaktujte nás")
                        }.foregroundColor(.black)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.white)
        }
        .background(Color.white)
    }
}

struct HelpDetailView: View {
    let title: String
    let content: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(content)
                    .font(.body)
                    .foregroundColor(.black)
                    .padding()
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.white)
    }
}
