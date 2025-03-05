//
//  Untitled.swift
//  HMS-Team3
//
//  Created by DIWAKAR KUMAR on 12/02/25.
//

import SwiftUI

struct HospitalCard: View {
    var name: String
    var location: String
    let adminName: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(name)
                    .font(.headline)
                    .fontWeight(.bold)

                Text(location)
                    .font(.subheadline)
                    .foregroundColor(.gray)

                Text("Admin : \(adminName)")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 1)
    }
}
