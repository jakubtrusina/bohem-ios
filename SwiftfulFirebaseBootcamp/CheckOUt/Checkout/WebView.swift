//
//  WebView.swift
//  SwiftfulFirebaseBootcamp
//
//  Created by Jakub Trusina on

import SwiftUI
import WebKit
import Foundation

struct WidgetWebView: UIViewRepresentable {
    var onPointSelected: (PickupPoint) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onPointSelected: onPointSelected)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.userContentController.add(context.coordinator, name: "pickupPointHandler")

        let webView = WKWebView(frame: .zero, configuration: config)
        if let htmlPath = Bundle.main.path(forResource: "zasilkovna", ofType: "html") {
            let htmlURL = URL(fileURLWithPath: htmlPath)
            webView.loadFileURL(htmlURL, allowingReadAccessTo: htmlURL)
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    class Coordinator: NSObject, WKScriptMessageHandler {
        var onPointSelected: (PickupPoint) -> Void

        init(onPointSelected: @escaping (PickupPoint) -> Void) {
            self.onPointSelected = onPointSelected
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "pickupPointHandler" else {
                print("❌ Unexpected message name: \(message.name)")
                return
            }

            print("📨 Raw message body:", message.body)

            guard let body = message.body as? [String: Any] else {
                print("❌ Message body is not a dictionary")
                return
            }

            // Try to print all keys and values
            for (key, value) in body {
                print("🔍 \(key): \(value)")
            }
            guard let id = body["id"] as? String,
                  let name = body["name"] as? String,
                  let street = body["street"] as? String,
                  let city = body["city"] as? String,
                  let zip = body["zip"] as? String,
                  let country = body["country"] as? String,
                  let lat = body["latitude"] as? Double,
                  let lon = body["longitude"] as? Double else {
                print("❌ Missing one or more required fields")
                return
            }


            let point = PickupPoint(
                id: id,
                name: name,
                address: street,
                city: city,
                zip: zip,
                country: country,
                latitude: lat,
                longitude: lon
            )

            onPointSelected(point)
        }
    }
}
