import SwiftUI
import Firebase

struct PatientDoctorDetailView: View {
    let doctor: DoctorModel
    @EnvironmentObject var appointmentManager: AppointmentManager
    @State private var navigateToBooking = false
    @State private var showAllReviews = false
    
    @State private var fees: String = "Loading..." // ✅ Store fees
    @State private var reviews: [Review] = []
    var patientEmail:String
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                VStack {
                    HStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                            .foregroundColor(.gray)

                        VStack(alignment: .leading) {
                            Text(doctor.firstName + " " + doctor.lastName)
                                .font(.title2)
                                .fontWeight(.semibold)
                            Text(doctor.specialization)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: Color.gray.opacity(0.2), radius: 2, x: 0, y: 2)

                InfoRow(title: "Experience", value: doctor.experience)
                InfoRow(title: "Phone", value: doctor.phone)
                InfoRow(title: "Email", value: doctor.email)
                InfoRow(title: "Fees", value: fees)
               
                Button(action: {
                    navigateToBooking = true
                }) {
                    Text("Book Appointment")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .background(
                    NavigationLink("", destination: BookAppointmentView(doctor: doctor,patientManager: PatientManager(), patientEmail: patientEmail)
                        .environmentObject(AppointmentManager()),
                        isActive: $navigateToBooking
                    )
                    .opacity(0)
                )
            }
            .padding()
            if !reviews.isEmpty {
                Text("Patient Reviews")
                    .font(.headline)
                    .padding(.top)

                ForEach(reviews) { review in
                    ReviewCard(review: review)
                }
            } else {
                Text("No reviews yet.")
                    .foregroundColor(.gray)
            }

        }
        .navigationTitle("Doctor Detail")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            fetchDoctorFees()
            fetchDoctorReviews()
        }
    }
    
    // 🔥 Fetch outpatient fees from Firestore
    private func fetchDoctorFees() {
        let db = Firestore.firestore()
        let doctorRef = db.collection("doctors").document(doctor.id)
        
        doctorRef.getDocument { document, error in
            if let document = document, document.exists {
                if let feesData = document.data()?["outpatientFees"] as? String {
                    DispatchQueue.main.async {
                        self.fees = feesData // ✅ Update UI
                    }
                } else {
                    DispatchQueue.main.async {
                        self.fees = "Not available"
                    }
                }
            } else {
                print("Error fetching fees: \(error?.localizedDescription ?? "Unknown error")")
                DispatchQueue.main.async {
                    self.fees = "Error"
                }
            }
        }
    }
    
    private func fetchDoctorReviews() {
        let db = Firestore.firestore()

        db.collection("doctors")
            .whereField("firstName", isEqualTo: doctor.firstName)
            .whereField("specialization", isEqualTo: doctor.specialization) // ✅ Fixed field name
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching doctor: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents, let doctorDoc = documents.first else {
                    print("No doctor found with the given name and specialization.")
                    return
                }

                // ✅ Extract reviews directly without making another Firestore call
                if let reviewData = doctorDoc.data()["reviews"] as? [[String: Any]] {
                    let parsedReviews = reviewData.compactMap { dict -> Review? in
                        guard let patientName = dict["patientName"] as? String,
                              let rating = dict["rating"] as? Int,
                              let comment = dict["comment"] as? String,
                              let timestamp = dict["timestamp"] as? Timestamp,
                              let docName = dict["doctorName"] as? String,
                              let docSpel = dict["docSpecialization"] as? String else { return nil }

                        return Review(patientId: "", patientName: patientName, rating: rating, comment: comment, timestamp: timestamp.dateValue(), doctorName: docName, docSpecialization: docSpel)
                    }
                    
                    DispatchQueue.main.async {
                        self.reviews = parsedReviews
                    }
                } else {
                    print("No reviews found for this doctor.")
                }
            }
    }

}


struct InfoRow: View {
    var title: String
    var value: String

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            Text(value)
                .font(.body)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.gray.opacity(0.2), radius: 2, x: 0, y: 2)
    }
}
struct ReviewCard: View {
    let review: Review

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(review.patientName)
                    .font(.headline)
                Spacer()
                Text(review.timestamp, style: .date)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { index in
                    Image(systemName: index <= review.rating ? "star.fill" : "star")
                        .foregroundColor(index <= review.rating ? .yellow : .gray)
                }
            }

            Text(review.comment)
                .font(.body)
                .foregroundColor(.primary)

        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.gray.opacity(0.2), radius: 3, x: 0, y: 2)
        .padding(.horizontal)
    }
}


// ✅ Preview
//struct PatientDoctorDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        NavigationView {
//            PatientDoctorDetailView(doctor: Doctor(
//                name: "Dr. John Smith",
//                specialty: "Cardiologist",
//                fees: "Rs. 500",
//                rating: "4.5",
//                reviews: [
//                    (rating: 5, text: "Very professional and knowledgeable doctor."),
//                    (rating: 4, text: "Great experience, but wait time was long."),
//                    (rating: 5, text: "The best cardiologist in town!"),
//                    (rating: 5, text: "Highly recommended!")
//                ],
//                imageName: "doctor1",
//                weeklySchedule: [
//                    "Monday": [
//                        TimeSlot(startTime: Date(), endTime: Date().addingTimeInterval(3600), maxPatients: 5)
//                    ],
//                    "Wednesday": [
//                        TimeSlot(startTime: Date().addingTimeInterval(7200), endTime: Date().addingTimeInterval(10800), maxPatients: 3)
//                    ]
//                ]
//            ))
//        }
//    }
//}
