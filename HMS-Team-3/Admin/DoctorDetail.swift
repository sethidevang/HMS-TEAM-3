//
//  DoctorDetail.swift
//  hms
//
//  Created by Yuktika Sood on 12/02/25.
//

import SwiftUI

// MARK: - Doctor Detail View
struct DoctorDetail: View {
    let doctor: DoctorModel
    let hospitalId: String
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 120, height: 120)
                        .overlay(
                            Image(systemName: "person.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.gray)
                        )
                    
                    Text("\(doctor.firstName) \(doctor.lastName)")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    VStack(spacing: 10) {
                        ProfileRow(title: "Specialization", value: doctor.specialization)
                        ProfileRow(title: "Experience", value: doctor.experience)
                        ProfileRow(title: "Phone", value: doctor.phone)
                        ProfileRow(title: "Email", value: doctor.email)
                        ProfileRow(title: "Degrees", value: doctor.degrees.joined(separator: "\n"))
                        ProfileRow(title: "Medical License Id", value: doctor.medicalLicenseId)
                        ProfileRow(title: "Bank Account No.", value: doctor.bankAccountNumber)
                        ProfileRow(title: "Address", value: doctor.address)
                    }
                    .padding()
                }
                .padding()
            }
            .background(Color(.systemGray6))
            .navigationTitle("Doctor Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: EditDoctor(hospitalId: hospitalId, doctor: doctor)) {
                        Text("Edit")
                    }
                }
            }
        }
    }
}

// MARK: - Profile Row Component
struct ProfileRow: View {
    var title: String
    var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white)
                .cornerRadius(10)
        }
    }
}

// MARK: - Preview
struct DoctorDetail_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            DoctorDetail(
                doctor: DoctorModel(
                    id: UUID().uuidString,
                    firstName: "Shaun",
                    lastName: "Murphy",
                    specialization: "Cardiology",
                    phone: "9205 010 100",
                    email: "doctor@gmail.com",
                    experience: "35 years",
                    degrees: ["M.B.B.S.", "M.S.", "M.Ch."],
                    medicalLicenseId: "012893199",
                    bankAccountNumber: "012893199XXXX",
                    address: "Tower A, Unitech Business Park, Block - F, South City 1, Sector - 41, Gurgaon, Haryana - 122001"
                ),
                hospitalId: ""
            )
        }
    }
}
