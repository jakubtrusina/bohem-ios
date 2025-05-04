//
//  TabbarView.swift
//  SwiftfulFirebaseBootcamp
//
//  Created by Nick Sarno on 1/22/23.
//

import SwiftUI

struct TabbarView: View {
    
    @Binding var showSignInView: Bool
    
    var body: some View {
//        UnrealView()
        MainTryOnView(showSignInView: $showSignInView)
//        PerformanceView()
    }
    
    
//    var body: some View {
//        TabView {
//            NavigationStack {
//                ProductsView()
//            }
//            .tabItem {
//                Image(systemName: "cart")
//                Text("menu_products")
//            }
//            
//            NavigationStack {
//                FavoriteView()
//            }
//            .tabItem {
//                Image(systemName: "star.fill")
//                Text("Favorites")
//            }
//            
//            NavigationStack {
//                CartView()
//            }
//            .tabItem {
//                Image(systemName: "bag")
//                Text("Cart")
//            }
//            
//            NavigationStack {
//                ProfileView(showSignInView: $showSignInView)
//            }
//            .tabItem {
//                Image(systemName: "person")
//                Text("Profile")
//            }
//        }
//    }
}

struct TabbarView_Previews: PreviewProvider {
    static var previews: some View {
        TabbarView(showSignInView: .constant(false))
    }
}
