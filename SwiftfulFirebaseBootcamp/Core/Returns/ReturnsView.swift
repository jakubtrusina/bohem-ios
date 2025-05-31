//
//  Untitled.swift
//  SwiftfulFirebaseBootcamp
//
//  Created by Jakub Trusina on 5/25/25.
//

import SwiftUI

struct ReturnsView: View {
    @StateObject private var viewModel = ReturnsViewModel()

    var body: some View {
        VStack {
            if viewModel.returns.isEmpty {
                Spacer()
                Text("Zatím jste nepožádali o vrácení.")
                    .foregroundColor(.gray)
                    .padding()
                Spacer()
            } else {
                List {
                    ForEach(viewModel.returns) { returnRequest in
                        Section(header: Text("Vrácení • \(returnRequest.timestamp.formatted(date: .abbreviated, time: .shortened))")) {
                            ForEach(returnRequest.items) { item in
                                VStack(alignment: .leading) {
                                    Text(item.title)
                                        .font(.subheadline)
                                    Text("Velikost: \(item.size)  •  Množství: \(item.quantity)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 4)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Důvod: \(returnRequest.reason)")
                                    .font(.caption)
                                Text("Stav: \(returnRequest.status.capitalized)")
                                    .font(.caption.bold())
                                    .foregroundColor(returnRequest.status == "approved" ? .green : .orange)
                            }
                            .padding(.top, 4)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
        }
        .navigationTitle("Vrácení")
        .onAppear {
            viewModel.fetchReturns()
        }
        .background(Color.white.ignoresSafeArea())
    }
}
