//
//  OrdersView.swift
//  SwiftfulFirebaseBootcamp
//
//  Created by Jakub Trusina on 5/25/25.
//

import SwiftUI

struct OrdersView: View {
    @StateObject private var viewModel = OrdersViewModel()

    var body: some View {
        VStack {
            if viewModel.orders.isEmpty {
                Spacer()
                Text("Zatím nemáte žádné objednávky.")
                    .foregroundColor(.gray)
                    .padding()
                Spacer()
            } else {
                List {
                    ForEach(viewModel.orders) { order in
                        Section(header: Text("Objednávka • \(order.timestamp.formatted(date: .abbreviated, time: .shortened))")) {
                            ForEach(order.items) { item in
                                VStack(alignment: .leading) {
                                    Text(item.title)
                                        .font(.subheadline)
                                    Text("Velikost: \(item.size)  •  Množství: \(item.quantity)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text("Cena: \(item.price, specifier: "%.2f") CZK")
                                        .font(.caption)
                                }
                                .padding(.vertical, 4)
                            }

                            HStack {
                                Spacer()
                                Text("Celkem: \(order.total, specifier: "%.2f") CZK")
                                    .font(.subheadline.bold())
                                    .padding(.top, 4)
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
        }
        .navigationTitle("Objednávky")
        .onAppear {
            viewModel.fetchOrders()
        }
        .background(Color.white.ignoresSafeArea())
    }
}
