//
//  TabBarItem.swift
//  HMS-Team3
//
//  Created by DIWAKAR KUMAR on 12/02/25.
//

import SwiftUI

struct TabBarItem: View {
    var icon: String
    var title: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .blue : .gray)

                Text(title)
                    .font(.caption)
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
