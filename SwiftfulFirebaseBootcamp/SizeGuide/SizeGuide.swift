import SwiftUI

struct SizeGuideView: View {
    let sizeHeaders = ["XS", "S", "M", "L", "XL", "2XL"]
    let underBust = ["63–67", "68–72", "73–77", "78–82", "83–87", "88–92"]
    let cupSizes: [(String, [String])] = [
        ("A", ["77–79", "82–84", "87–89", "92–94", "97–99", "102–104"]),
        ("B", ["79–81", "84–86", "89–91", "94–96", "99–101", "104–106"]),
        ("C", ["81–83", "86–88", "91–93", "96–98", "101–103", "106–108"]),
        ("D", ["83–85", "88–90", "93–95", "98–100", "103–105", "108–110"]),
        ("E", ["85–87", "90–92", "95–97", "100–102", "105–107", "110–112"]),
        ("F", ["87–89", "92–94", "97–99", "102–104", "107–109", "112–114"]),
        ("G", ["89–91", "94–96", "99–101", "104–106", "109–111", "114–116"]),
        ("H", ["91–93", "96–98", "101–103", "106–108", "111–113", "116–118"])
    ]

    let bottomSizeHeaders = ["XS", "S", "M", "L", "XL", "2XL"]
    let euSizes = ["36", "38", "40", "42", "44", "46"]
    let bust = ["82–87", "87–91", "91–95", "95–99", "99–103", "103–107"]
    let waist = ["66–68", "69–71", "72–74", "75–77", "78–80", "81–83"]
    let hips = ["92–94", "95–97", "98–100", "101–103", "104–106", "107–109"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("👙 Modelka na fotografiích: výška 178 cm, velikost TOP B75 a BOTTOM S")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // TOP sizing
                VStack(alignment: .leading, spacing: 12) {
                    Label("Horní díl (TOP sizing)", systemImage: "arrow.up.to.line.compact")
                        .font(.headline)

                    LazyVGrid(columns: [GridItem(.fixed(90))] + Array(repeating: GridItem(.flexible()), count: sizeHeaders.count), spacing: 4) {
                        Text("Košíček").bold().font(.caption2)
                        ForEach(sizeHeaders, id: \.self) { Text($0).bold().font(.caption2) }

                        Text("Under Bust").font(.caption2)
                        ForEach(underBust, id: \.self) { Text($0).font(.caption2) }

                        ForEach(cupSizes, id: \.0) { cup in
                            Text("Cup \(cup.0)").font(.caption2)
                            ForEach(cup.1, id: \.self) { Text($0).font(.caption2) }
                        }
                    }
                    .font(.caption2.monospacedDigit())
                }

                Divider()

                // BOTTOM sizing
                VStack(alignment: .leading, spacing: 12) {
                    Label("Spodní díl (BOTTOM sizing)", systemImage: "dress.fill")
                        .font(.headline)

                    LazyVGrid(columns: [GridItem(.fixed(90))] + Array(repeating: GridItem(.flexible()), count: bottomSizeHeaders.count), spacing: 4) {
                        Text("Size").bold().font(.caption2)
                        ForEach(bottomSizeHeaders, id: \.self) { Text($0).bold().font(.caption2) }

                        Text("EU Size").font(.caption2)
                        ForEach(euSizes, id: \.self) { Text($0).font(.caption2) }

                        Text("Over Bust (cm)").font(.caption2)
                        ForEach(bust, id: \.self) { Text($0).font(.caption2) }

                        Text("Waist (cm)").font(.caption2)
                        ForEach(waist, id: \.self) { Text($0).font(.caption2) }

                        Text("Hips (cm)").font(.caption2)
                        ForEach(hips, id: \.self) { Text($0).font(.caption2) }
                    }
                    .font(.caption2.monospacedDigit())
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Size Guide")
        .navigationBarTitleDisplayMode(.inline)
    }
}
