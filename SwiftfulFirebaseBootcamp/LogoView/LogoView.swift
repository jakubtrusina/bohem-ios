//
//  LogoView.swift
//  SwiftfulFirebaseBootcamp
//
//  Created by Jakub Trusina on 4/14/25.
//

import SwiftUI

struct LogoView: View {
    var body: some View {
        Image("LOGO")
            .resizable()
            .scaledToFit()
            .frame(height: 80) // Adjust size as needed
            .padding(.top, 8)
    }
}
