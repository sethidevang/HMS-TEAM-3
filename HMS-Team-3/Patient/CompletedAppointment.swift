import SwiftUI
import Firebase
import Foundation

struct Review: Codable, Identifiable {
    var id: String = UUID().uuidString  // ✅ Unique identifier
    let patientId: String
    let patientName: String
    let rating: Int
    let comment: String
    let timestamp: Date
    let doctorName: String
    let docSpecialization: String
}


struct CompletedAppointment: View {
    var appointment: DoctorAppointment
    var patientEmail: String

    @State private var selectedRating: Int? = nil
    @State private var reviewText: String = ""
    @State private var existingReviewId: String? = nil
    @State private var showReviewSubmittedAlert = false
    @State private var showReviewDeletedAlert = false

    var body: some View {
        VStack(spacing: 16) {
            // Doctor Info
            HStack(spacing: 16) {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.gray)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Dr. " + appointment.doctorName)
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text(appointment.specialty)
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            .padding(.horizontal)

            // Rating Section
            VStack(spacing: 12) {
                Text(existingReviewId != nil ? "Edit Your Review" : "Rate Your Experience")
                    .font(.headline)

                // Star Rating System
                HStack(spacing: 8) {
                    ForEach(1...5, id: \.self) { index in
                        Image(systemName: index <= (selectedRating ?? 0) ? "star.fill" : "star")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(index <= (selectedRating ?? 0) ? .yellow : .gray)
                            .onTapGesture {
                                selectedRating = index
                            }
                    }
                }

                // Review TextField
                TextField("Write Your Review Here", text: $reviewText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                // Submit or Update Review
                Button(action: {
                    guard let selectedRating = selectedRating, !reviewText.isEmpty else { return }
                    getDoctorIdByNameAndSpecialization(doctorName: appointment.doctorName, specialization: appointment.specialty) { doctorId in
                        guard let doctorId = doctorId else {
                            print("Doctor not found.")
                            return
                        }

                        if let reviewId = existingReviewId {
                            updateReview(doctorId: doctorId, reviewId: reviewId)
                        } else {
                            submitNewReview(doctorId: doctorId)
                        }
                    }
                }) {
                    Text(existingReviewId != nil ? "Update Review" : "Submit Review")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background((selectedRating != nil && !reviewText.isEmpty) ? Color.blue : Color.gray)
                        .cornerRadius(10)
                }
                .disabled(selectedRating == nil || reviewText.isEmpty)
                .alert(isPresented: $showReviewSubmittedAlert) {
                    Alert(
                        title: Text("Success"),
                        message: Text("Review submitted successfully."),
                        dismissButton: .default(Text("OK")) {
                            selectedRating = nil
                            reviewText = ""
                        }
                    )
                }

                // Delete Review Button (Only if the review exists)
                if existingReviewId != nil {
                    Button(action: {
                        getDoctorIdByNameAndSpecialization(doctorName: appointment.doctorName, specialization: appointment.specialty) { doctorId in
                            guard let doctorId = doctorId else {
                                print("Doctor not found.")
                                return
                            }
                            deleteReview(doctorId: doctorId)
                        }
                    }) {
                        Text("Delete Review")
                            .foregroundColor(.red)
                            .padding()
                    }
                    .alert(isPresented: $showReviewDeletedAlert) {
                        Alert(
                            title: Text("Deleted"),
                            message: Text("Your review has been removed."),
                            dismissButton: .default(Text("OK")) {
                                selectedRating = nil
                                reviewText = ""
                                existingReviewId = nil
                            }
                        )
                    }
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            .padding(.horizontal)

            Spacer()
        }
        .background(Color("F2F2F7").ignoresSafeArea())
        .navigationTitle("Appointment Detail")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            fetchExistingReview()
        }
    }

    // Fetch existing review
    private func fetchExistingReview() {
        getDoctorIdByNameAndSpecialization(doctorName: appointment.doctorName, specialization: appointment.specialty) { doctorId in
            guard let doctorId = doctorId else { return }

            Firestore.firestore().collection("doctors").document(doctorId).getDocument { document, error in
                if let document = document, document.exists, let data = document.data(),
                   let reviews = data["reviews"] as? [[String: Any]] {
                    
                    if let review = reviews.first(where: { ($0["patientId"] as? String) == patientEmail }) {
                        self.existingReviewId = review["patientId"] as? String
                        self.selectedRating = review["rating"] as? Int
                        self.reviewText = review["comment"] as? String ?? ""
                    }
                }
            }
        }
    }

    // Submit new review
    private func submitNewReview(doctorId: String) {
        let newReview = [
            "patientId": patientEmail,
            "patientName": "Anonymous",
            "rating": selectedRating ?? 0,
            "comment": reviewText,
            "timestamp": Timestamp(date: Date()),
            "doctorName": appointment.doctorName,
            "docSpecialization": appointment.specialty
        ] as [String : Any]

        Firestore.firestore().collection("doctors").document(doctorId).updateData([
            "reviews": FieldValue.arrayUnion([newReview])
        ]) { error in
            if let error = error {
                print("Error adding review: \(error.localizedDescription)")
            } else {
                showReviewSubmittedAlert = true
                existingReviewId = patientEmail
            }
        }
    }

    // Update existing review
    private func updateReview(doctorId: String, reviewId: String) {
        Firestore.firestore().collection("doctors").document(doctorId).getDocument { document, error in
            guard let document = document, document.exists, var reviews = document.data()?["reviews"] as? [[String: Any]] else { return }

            if let index = reviews.firstIndex(where: { ($0["patientId"] as? String) == reviewId }) {
                reviews[index]["rating"] = selectedRating ?? 0
                reviews[index]["comment"] = reviewText
                reviews[index]["timestamp"] = Timestamp(date: Date())

                Firestore.firestore().collection("doctors").document(doctorId).updateData(["reviews": reviews]) { error in
                    if let error = error {
                        print("Error updating review: \(error.localizedDescription)")
                    } else {
                        showReviewSubmittedAlert = true
                    }
                }
            }
        }
    }

    // Delete review
    private func deleteReview(doctorId: String) {
        let doctorRef = Firestore.firestore().collection("doctors").document(doctorId)

        doctorRef.getDocument { document, error in
            if let error = error {
                print("Error fetching doctor reviews: \(error.localizedDescription)")
                return
            }

            guard let document = document, document.exists,
                  var reviews = document.data()?["reviews"] as? [[String: Any]] else {
                print("No reviews found")
                return
            }

            // Filter out the review that matches the patientId
            reviews.removeAll { $0["patientId"] as? String == patientEmail }

            // Update Firestore with the modified reviews array
            doctorRef.updateData(["reviews": reviews]) { error in
                if let error = error {
                    print("Error deleting review: \(error.localizedDescription)")
                } else {
                    showReviewDeletedAlert = true
                    print("Review deleted successfully")
                }
            }
        }
    }

}

    @ViewBuilder
    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
    
    
    func getDoctorIdByNameAndSpecialization(doctorName: String, specialization: String, completion: @escaping (String?) -> Void) {
        let db = Firestore.firestore()
        
        db.collection("doctors")
            .whereField("firstName", isEqualTo: doctorName) // Ensure the field name matches Firestore
            .whereField("specialization", isEqualTo: specialization)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching doctor: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    print("No doctor found with the given name and specialization.")
                    completion(nil)
                    return
                }
                
                let doctorId = documents.first?.documentID // Get the first matching document ID
                completion(doctorId)
            }
    }



