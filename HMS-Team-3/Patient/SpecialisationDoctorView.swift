import SwiftUI
import Firebase
import FirebaseFirestore

struct SpecialisationDoctorView: View {
    let specialization: SpecializationModel
    @State private var doctors: [DoctorModel] = []
    var patientEmail:String
    var filteredDoctors: [DoctorModel] {
        doctors.filter { $0.specialization == specialization.name }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 16) {
                    Image(systemName: specialization.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.blue)
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    VStack(alignment: .leading) {
                        Text(specialization.name)
                            .font(.title)
                            .bold()
                        Text(specialization.description)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 20)

                Text("Available Doctors")
                    .font(.title2)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 20)

                ForEach(filteredDoctors, id: \.id) { doctor in
                    NavigationLink(destination: PatientDoctorDetailView(doctor: doctor, patientEmail: patientEmail)) {
                        DoctorCard(doctor: doctor)
                            .frame(maxWidth: 175, alignment: .leading)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.vertical)
        }
        .navigationBarTitle(specialization.name, displayMode: .inline)
        .onAppear {
            fetchDoctors()
        }
    }

    private func fetchDoctors() {
        let db = Firestore.firestore()
        db.collection("doctors")
            .whereField("specialization", isEqualTo: specialization.name)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching doctors: \(error.localizedDescription)")
                    return
                }

                if let documents = snapshot?.documents {
                    DispatchQueue.main.async {
                        doctors = documents.map { doc in
                            let data = doc.data()
                            return DoctorModel(
                                id: doc.documentID,
                                firstName: data["firstName"] as? String ?? "",
                                lastName: data["lastName"] as? String ?? "",
                                specialization: data["specialization"] as? String ?? "",
                                phone: data["phone"] as? String ?? "",
                                email: data["email"] as? String ?? "",
                                experience: data["experience"] as? String ?? "",
                                degrees: data["degrees"] as? [String] ?? [],
                                medicalLicenseId: data["medicalLicenseId"] as? String ?? "",
                                bankAccountNumber: data["bankAccountNumber"] as? String ?? "",
                                address: data["address"] as? String ?? ""
                            )
                        }
                    }
                }
            }
    }
}
