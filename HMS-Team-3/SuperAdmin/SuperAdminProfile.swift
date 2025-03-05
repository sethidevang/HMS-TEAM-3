//
//  SuperAdminProfile.swift
//  HMS-Team3
//
//  Created by DIWAKAR KUMAR on 12/02/25.
//

import SwiftUI
import Firebase
import FirebaseAuth

struct SuperAdminProfile: View {
    @State private var isLoggedOut = false
    var email: String = "Super Admin"
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Profile header
                VStack(spacing: 16) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .foregroundColor(.blue)
                        .shadow(color: .gray.opacity(0.3), radius: 4)
                    
                    Text(email)
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .shadow(color: .gray.opacity(0.2), radius: 4)
                )
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Menu items
                VStack(spacing: 16) {
                    NavigationLink(destination: SuperAdminChangePassword()) {
                        HStack {
                            Image(systemName: "lock.rotation")
                                .foregroundColor(.blue)
                                .frame(width: 24, height: 24)
                            
                            Text("Change Password")
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.system(size: 14))
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: logOut) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                                .frame(width: 24, height: 24)
                            
                            Text("Log Out")
                                .fontWeight(.medium)
                                .foregroundColor(.red)
                            
                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                        )
                    }
                }
                .padding()
                
                Spacer()
            }
            .background(Color(.systemGray6))
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .fullScreenCover(isPresented: $isLoggedOut) {
                LoginView() // Redirects user to login after logout
            }
        }
    }
    
    func logOut() {
        do {
            try Auth.auth().signOut()
            isLoggedOut = true // Redirect user to login
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}

struct SuperAdminProfile_Previews: PreviewProvider {
    static var previews: some View {
        SuperAdminProfile()
    }
}
