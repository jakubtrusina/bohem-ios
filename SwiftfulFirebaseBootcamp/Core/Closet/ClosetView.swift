//
//  Untitled.swift
//  SwiftfulFirebaseBootcamp
//
//  Created by Jakub Trusina on 5/25/25.
//

import SwiftUI
import Kingfisher

struct ClosetView: View {
    @StateObject private var viewModel = ClosetViewModel()

    private let grid = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: grid, spacing: 16) {
                ForEach(viewModel.closetItems) { item in
                    VStack(alignment: .leading) {
                        KFImage(URL(string: item.imageUrl))
                            .resizable()
                            .scaledToFill()
                            .frame(height: 220)
                            .clipped()
                            .cornerRadius(10)

                        Text(item.title)
                            .font(.subheadline)
                            .lineLimit(1)

                        Text("Velikost: \(item.size)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                }
            }
            .padding()
        }
        .navigationTitle("Šatník")
        .onAppear {
            viewModel.fetchCloset()
        }
        .background(Color.white.ignoresSafeArea())
    }
}
