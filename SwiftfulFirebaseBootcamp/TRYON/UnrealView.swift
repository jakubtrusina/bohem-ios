import SwiftUI
import UnrealBridge   // ✅ Now this is real!

 struct UnrealView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        return CreateUnrealViewController()  // ✅ Should now work!
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
