//
//  Untitled.swift
//  SwiftfulFirebaseBootcamp
//
//  Created by Jakub Trusina on 4/15/25.
//

import SwiftUI

struct AnalyticsTrackedView<Content: View>: View {
    let screenName: String
    let content: Content
    @State private var startTime: Date?

    init(screen: String, @ViewBuilder content: () -> Content) {
        self.screenName = screen
        self.content = content()
    }

    var body: some View {
        content
            .onAppear {
                startTime = Date()
                AnalyticsManager.shared.logEvent(.screenView, params: ["screen_name": screenName])
            }
            .onDisappear {
                if let startTime {
                    let duration = Date().timeIntervalSince(startTime)
                    AnalyticsManager.shared.logCustomEvent(name: "screen_time", params: [
                        "screen_name": screenName,
                        "duration_seconds": duration
                    ])
                }
            }
    }
}
