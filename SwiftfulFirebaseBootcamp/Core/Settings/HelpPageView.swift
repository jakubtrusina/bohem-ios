import SwiftUI

struct HelpPageView: View {
    var body: some View {
        List {
            NavigationLink("🛍️ Shopping & Orders") {
                HelpDetailView(
                    title: "Shopping & Orders",
                    content: """
                    Browse our curated collections, add items to your cart, and check out using Apple Pay or card. Every item is quality-checked before shipping. Orders can be tracked in your profile.
                    """
                )
            }

            NavigationLink("🚚 Shipping Information") {
                HelpDetailView(
                    title: "Shipping Information",
                    content: """
                    We offer free standard shipping on all domestic orders. Delivery takes 3–5 business days. Once shipped, you’ll receive a tracking number by email.
                    """
                )
            }

            NavigationLink("🔁 Returns & Exchanges") {
                HelpDetailView(
                    title: "Returns & Exchanges",
                    content: """
                    We accept returns within 14 days of delivery. Items must be unused, in original packaging, and with tags. To start a return, email us at support@bohemapp.com with your order number.
                    """
                )
            }

            NavigationLink("📞 Contact Us") {
                HelpDetailView(
                    title: "Contact Us",
                    content: """
                    Have a question? We’re happy to help. Email us at support@bohemapp.com and we’ll get back to you within 24 hours.
                    """
                )
            }
        }
        .navigationTitle("Help & Support")
    }
}


struct HelpDetailView: View {
    let title: String
    let content: String

    var body: some View {
        ScrollView {
            Text(content)
                .padding()
                .font(.body)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
