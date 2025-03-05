//
//  DoctorDetail.swift
//  Doctor
//
//  Created by Shivam Dubey on 19/02/25.
//

import SwiftUI


// Sample Doctor Data
let doctorData = DoctorModel(
    id: "1", // Add missing 'id' field
    firstName: "Dr. Shaun",
    lastName: "Murphy",
    specialization: "Cardiologist",
    phone: "35 years",
    email: "9205 010 100",
    experience: "doctor@gmail.com",
    degrees: ["M.B.B.S.", "M.S.", "M.Ch."], // Change from String to [String]
    medicalLicenseId: "012893199", // Ensure field names match
    bankAccountNumber: "012893199XXXX",
    address: "Tower A, Unitech Business Park, Block - F, South City 1, Sector - 41, Gurgaon, Haryana - 122001"
)


struct DoctorDetailView: View {
    var doctor: DoctorModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Doctor Image
//                Image(doctor.profileImage)
//                    .resizable()
//                    .frame(width: 120, height: 120)
//                    .clipShape(Circle())

                // Doctor Name
                Text(doctor.firstName)
                    .font(.title)
                    .fontWeight(.bold)

                // Info Sections
                VStack(alignment: .leading, spacing: 12) {
                    DetailRow(title: "Specialization", value: doctor.specialization)
                    DetailRow(title: "Experience", value: doctor.experience)
                    DetailRow(title: "Phone", value: doctor.phone)
                    DetailRow(title: "Email", value: doctor.email)
                    DetailRow(title: "Degree", value: doctor.degrees.joined(separator: ", "))

                    DetailRow(title: "Medical License Id", value: doctor.medicalLicenseId)
                    DetailRow(title: "Bank Account No.", value: doctor.bankAccountNumber)
                    DetailRow(title: "Address", value: doctor.address)
                }
                .padding(.horizontal)
            }
            .padding(.top, 20)
        }
        .navigationTitle("Doctor Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Detail Row Component
//struct DetailRow: View {
//    let title: String
//    let value: String
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 4) {
//            Text(title)
//                .font(.subheadline)
//                .foregroundColor(.gray)
//            Text(value)
//                .font(.body)
//                .frame(maxWidth: .infinity, alignment: .leading)
//                .padding()
//                .background(Color(.systemGray6))
//                .cornerRadius(8)
//        }
//    }
//}

#Preview {
    NavigationStack {
        DoctorDetailView(doctor: doctorData)
    }
}
