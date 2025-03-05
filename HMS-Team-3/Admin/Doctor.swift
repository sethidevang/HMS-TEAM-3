import SwiftUI
import Firebase
import FirebaseFirestore

// MARK: - Doctor Model
//struct DoctorModel: Identifiable, Equatable {
//    let id: String
//    var firstName: String
//    var lastName: String
//    var specialization: String
//    var phone: String
//    var email: String
//    var experience: String
//    var degrees: [String]
//    var medicalLicenseId: String
//    var bankAccountNumber: String
//    var address: String
//}

// MARK: - Doctor List View
struct DoctorListView: View {
    let hospitalId: String
    @State private var doctors: [DoctorModel] = []
    @State private var searchText = ""
    @State private var isLoading = true

    var filteredDoctors: [DoctorModel] {
        if searchText.isEmpty {
            return doctors
        } else {
            return doctors.filter { doctor in
                doctor.firstName.localizedCaseInsensitiveContains(searchText) ||
                doctor.lastName.localizedCaseInsensitiveContains(searchText) ||
                doctor.specialization.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGray6)
                    .edgesIgnoringSafeArea(.all)

                VStack {
                    PatientSearchBar(searchText: $searchText)
                        .padding(.bottom, 10)

                    if isLoading {
                        ProgressView("Loading Doctors...")
                    } else if doctors.isEmpty {
                        VStack {
                            Text("No doctors available")
                                .foregroundColor(.gray)
                                .padding()
                            Spacer()
                        }
                        .frame(maxHeight: .infinity)
                    } else {
                        List(filteredDoctors) { doctor in
                            ZStack {
                                PatientDoctorCard(doctor: doctor)
                                    .listRowBackground(Color.clear)

                                NavigationLink(destination: DoctorDetail(doctor: doctor, hospitalId: hospitalId)) {
                                    EmptyView()
                                }
                                .opacity(0)
                            }
                            .listRowInsets(EdgeInsets())
                        }
                        .listStyle(PlainListStyle())
                        .background(Color.clear)
                    }
                }
            }
            .navigationTitle("Doctors")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: AddDoctor(hospitalId: hospitalId)) {
                        Image(systemName: "plus")
                            .foregroundColor(.blue)
                    }
                }
            }
            .onAppear {
                fetchDoctors()
            }
        }
    }

    private func fetchDoctors() {
        let db = Firestore.firestore()
        db.collection("doctors")
            .whereField("hospitalId", isEqualTo: hospitalId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching doctors: \(error.localizedDescription)")
                    isLoading = false
                    return
                }

                self.doctors = snapshot?.documents.compactMap { document in
                    let data = document.data()
                    return DoctorModel(
                        id: document.documentID,
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
                } ?? []
                isLoading = false
            }
    }
}

// MARK: - Search Bar Component
struct PatientSearchBar: View {
    @Binding var searchText: String

    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)

                TextField("Search by Name or Specialization", text: $searchText)
                    .padding(.vertical, 8)
                    .autocapitalization(.none)

                Button(action: {
                    searchText = "" // Clear search
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .opacity(searchText.isEmpty ? 0 : 1)
                }
            }
            .padding(.horizontal, 10)
            .background(Color(red: 227/255, green: 227/255, blue: 233/255))
            .cornerRadius(10)
        }
        .padding(.horizontal)
    }
}

// MARK: - Doctor Card View
struct PatientDoctorCard: View {
    let doctor: DoctorModel

    var body: some View {
        HStack {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 50, height: 50)

            VStack(alignment: .leading) {
                Text("\(doctor.firstName) \(doctor.lastName)")
                    .font(.headline)

                Text(doctor.specialization)
                    .font(.subheadline)
                    .foregroundColor(.gray)

                if !doctor.degrees.isEmpty {
                    Text(doctor.degrees.joined(separator: ", "))
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .frame(height: 80)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.gray.opacity(0.3), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Preview
struct DoctorListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            DoctorListView(hospitalId: "exampleHospitalId")
        }
    }
}
