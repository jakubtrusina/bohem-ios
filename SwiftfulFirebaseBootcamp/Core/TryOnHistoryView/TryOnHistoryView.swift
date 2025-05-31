//
//  TryOnHistoryView.swift
//  SwiftfulFirebaseBootcamp
//
//  Created by Jakub Trusina on 5/25/25.
//

import SwiftUI
import FirebaseFirestore

struct TryOnHistoryView: View {
    @StateObject private var vm = TryOnHistoryViewModel()
    @StateObject private var productsVM = ProductsViewModel.shared

    var body: some View {
        ScrollView {
            placeholderContent
        }
        .onAppear {
            vm.fetchTryOnHistory()
            productsVM.loadFavoriteProductIds()
        }
        .navigationTitle("Zkoušené")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var placeholderContent: some View {
        VStack(spacing: 16) {
            Text("Zkoušené produkty")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top)

            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 200)
                .overlay(
                    Text("Placeholder for Try-On History Grid")
                        .foregroundColor(.gray)
                )
                .cornerRadius(12)
                .padding()
        }
        .padding()
    }
}
