//
//  AnalyticsView.swift
//  SwiftfulFirebaseBootcamp
//
//  Created by Nick Sarno on 1/26/23.
//

import SwiftUI
import FirebaseAnalytics
import FirebaseAnalyticsSwift

struct AnalyticsView: View {
    @State private var appearTime: Date?

    var body: some View {
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
        .analyticsScreen(name: "AnalyticsView")
        .onAppear {
            appearTime = Date()

            AnalyticsManager.shared.logEvent(.screenView, params: [
                "screen_name": "AnalyticsView"
            ])
        }
        .onDisappear {
            if let appearTime = appearTime {
                let duration = Date().timeIntervalSince(appearTime)
                AnalyticsManager.shared.logCustomEvent(name: "screen_time", params: [
                    "screen_name": "AnalyticsView",
                    "duration_seconds": duration
                ])
            }
        }
    }
}


struct AnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        AnalyticsView()
    }
}
