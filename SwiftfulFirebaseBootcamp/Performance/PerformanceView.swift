//
//  PerformanceView.swift
//  SwiftfulFirebaseBootcamp
//
//

import SwiftUI
import FirebasePerformance

final class PerformanceManager {
    
    static let shared = PerformanceManager()
    private init() { }
    
    private var traces: [String:Trace] = [:]
    
    func startTrace(name: String) {
        let trace = Performance.startTrace(name: name)
        traces[name] = trace
    }
    
    func setValue(name: String, value: String, forAttribute: String) {
        guard let trace = traces[name] else { return }
        trace.setValue(value, forAttribute: forAttribute)
    }
    
    func stopTrace(name: String) {
        guard let trace = traces[name] else { return }
        trace.stop()
        traces.removeValue(forKey: name)
    }
}

struct PerformanceView: View {
    @StateObject private var viewModel = ProductsViewModel()
    @State private var title: String = "Some Title"

    var body: some View {
        Text("Hello, World!")
            .onAppear {
                configure()
                viewModel.downloadProductsAndUploadToFirebase()

                PerformanceManager.shared.startTrace(name: "performance_screen_time")
            }
            .onDisappear {
                PerformanceManager.shared.stopTrace(name: "performance_screen_time")
            }
    }
    
    private func configure() {
        PerformanceManager.shared.startTrace(name: "performance_view_loading")

        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            PerformanceManager.shared.setValue(name: "performance_view_loading", value: "Started downloading", forAttribute: "func_state")
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            PerformanceManager.shared.setValue(name: "performance_view_loading", value: "Finished downloading", forAttribute: "func_state")

            PerformanceManager.shared.stopTrace(name: "performance_view_loading")
        }
        
    }

}

struct PerformanceView_Previews: PreviewProvider {
    static var previews: some View {
        PerformanceView()
    }
}
