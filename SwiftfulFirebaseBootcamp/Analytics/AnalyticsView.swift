import SwiftUI

struct AnalyticsView: View {
    var body: some View {
        AnalyticsTrackedView(screenName: "AnalyticsView") {
            VStack(spacing: 40) {
                Button("Click me!") {
                    AnalyticsManager.shared.logEvent(.buttonClick, params: [
                        "button_id": "primary",
                        "screen": "AnalyticsView"
                    ])
                }

                Button("Click me too!") {
                    AnalyticsManager.shared.logEvent(.buttonClick, params: [
                        "button_id": "secondary",
                        "screen": "AnalyticsView",
                        "label": "Click me too!"
                    ])
                }
            }
        }
    }
}

struct AnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        AnalyticsView()
    }
}
