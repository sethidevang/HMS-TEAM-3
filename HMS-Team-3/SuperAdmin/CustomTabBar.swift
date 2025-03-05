//
//  CustomTabBar.swift
//  HMS-Team3
//
//  Created by DIWAKAR KUMAR on 12/02/25.
//

import SwiftUI

struct CustomTabBar: View {
    @State private var selectedTab: String = "Dashboard" // Track selected tab
    
    var body: some View {
        HStack {
            TabBarItem(
                icon: "plus.circle",
                title: "Dashboard",
                isSelected: selectedTab == "Dashboard",
                action: {
                    selectedTab = "Dashboard"
                }
            )

            // Uncomment and add navigation for other tabs if needed
            // TabBarItem(
            //     icon: "dollarsign.circle",
            //     title: "Financial",
            //     isSelected: selectedTab == "Financial",
            //     action: {
            //         selectedTab = "Financial"
            //     }
            // )

            NavigationLink(destination: SuperAdminProfile()) {
                TabBarItem(
                    icon: "person.crop.circle",
                    title: "Profile",
                    isSelected: selectedTab == "Profile",
                    action: {
                        selectedTab = "Profile"
                    }
                )
            }
        }
        .padding(.vertical, 10)
        .background(Color.gray.opacity(0.9)) // Dark Grey Background
        .shadow(radius: 2)
    }
}
