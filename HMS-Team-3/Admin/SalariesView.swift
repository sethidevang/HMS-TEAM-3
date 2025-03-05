import SwiftUI
import FirebaseFirestore

struct SalariesView: View {
    let hospitalId: String
    @State private var doctors: [DoctorSalaryData] = []
    @Environment(\.dismiss) private var dismiss  // Add dismiss environment

    var isFormValid: Bool {
        doctors.allSatisfy { !$0.salary.isEmpty && !$0.outpatientFees.isEmpty }
    }

    var body: some View {
            NavigationStack {
                ZStack {
                    Color(.systemGray6) // ✅ Background applied
                        .edgesIgnoringSafeArea(.all)

                    ScrollView {
                        VStack(spacing: 15) {
                            ForEach($doctors) { $doctor in
                                DoctorCards(doctor: $doctor)
                                    .background(Color(.systemBackground)) // ✅ Ensures contrast for dark mode
                                    .cornerRadius(12)
                                    .shadow(color: Color.gray.opacity(0.2), radius: 4, x: 0, y: 2)
                            }
                        }
                        .padding()
                    }
                }
                .navigationTitle("Doctor Salaries")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Save") {
                            saveSalariesToDB()
                        }
                        .fontWeight(.bold)
                        .foregroundColor(isFormValid ? .blue : .gray)
                        .disabled(!isFormValid)
                    }
                }
                .onAppear {
                    fetchDoctors()
                }
            }
        }

    func fetchDoctors() {
        let db = Firestore.firestore()
        db.collection("doctors")
            .whereField("hospitalId", isEqualTo: hospitalId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching doctors: \(error)")
                    return
                }

                if let documents = snapshot?.documents {
                    doctors = documents.compactMap { doc in
                        let data = doc.data()
                        return DoctorSalaryData(
                            id: doc.documentID,
                            firstName: data["firstName"] as? String ?? "",
                            lastName: data["lastName"] as? String ?? "",
                            specialization: data["specialization"] as? String ?? "Unknown",
                            phone: data["phone"] as? String ?? "",
                            email: data["email"] as? String ?? "",
                            experience: data["experience"] as? String ?? "",
                            degrees: data["degrees"] as? [String] ?? [],
                            medicalLicenseId: data["medicalLicenseId"] as? String ?? "",
                            bankAccountNumber: data["bankAccountNumber"] as? String ?? "",
                            address: data["address"] as? String ?? "",
                            salary: data["salary"] as? String ?? "",
                            outpatientFees: data["outpatientFees"] as? String ?? ""
                        )
                    }
                }
            }
    }

    func saveSalariesToDB() {
        let db = Firestore.firestore()
        var completed = 0
        let totalDoctors = doctors.count
        
        for doctor in doctors {
            db.collection("doctors").document(doctor.id).updateData([
                "salary": doctor.salary,
                "outpatientFees": doctor.outpatientFees
            ]) { error in
                if let error = error {
                    print("Error saving salaries: \(error)")
                } else {
                    print("Salaries saved successfully for \(doctor.firstName) \(doctor.lastName)")
                }
                
                completed += 1
                if completed == totalDoctors {
                    DispatchQueue.main.async {
                        dismiss()  // Dismiss the view after all updates complete
                    }
                }
            }
        }
    }
}

// Doctor card UI
struct DoctorCards: View {
    @Binding var doctor: DoctorSalaryData

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading) {
                    Text("\(doctor.firstName) \(doctor.lastName)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(doctor.specialization)
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.blue)
            }

            InputField(icon: "creditcard.fill", title: "Salary", placeholder: "Enter Salary", value: $doctor.salary)
            InputField(icon: "stethoscope", title: "Outpatient Fees", placeholder: "Enter Fees", value: $doctor.outpatientFees)
        }
        .padding()
        .background(.ultraThinMaterial)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 5)
    }
}

// Custom input field
struct InputField: View {
    var icon: String
    var title: String
    var placeholder: String
    @Binding var value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.title2)
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.secondary)
                TextField(placeholder, text: $value)
                    .keyboardType(.numberPad)
                    .textFieldStyle(PlainTextFieldStyle())
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
        .shadow(radius: 3)
    }
}

// Temporary doctor struct with salary & fees
struct DoctorSalaryData: Identifiable {
    let id: String
    var firstName: String
    var lastName: String
    var specialization: String
    var phone: String
    var email: String
    var experience: String
    var degrees: [String]
    var medicalLicenseId: String
    var bankAccountNumber: String
    var address: String
    var salary: String
    var outpatientFees: String
}

#Preview {
    SalariesView(hospitalId: "78")
}
