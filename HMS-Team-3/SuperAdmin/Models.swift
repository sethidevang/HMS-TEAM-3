//
//  Models.swift
//  HMS-Team3
//
//  Created by DIWAKAR KUMAR on 12/02/25.
//
import FirebaseFirestore
//import FirebaseFirestoreSwift

import Foundation

//struct Hospital: Identifiable {
//    let id = UUID()
//    let name: String
//    let location: String
//}

struct Hospital: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var location: String
    var admin: Admin
    var revenue : String?
    var unpaidDues: String?
    var expenses: String?
}

struct Admin: Codable, Identifiable {
    var id: String? // Optional ID
    var name: String
    var email: String
    var address: String
    var experience: String
    var phoneNumber: String

    // 🔹 Add this explicit initializer
    init(id: String? = nil, name: String, email: String, address: String, experience: String, phoneNumber: String) {
        self.id = id
        self.name = name
        self.email = email
        self.address = address
        self.experience = experience
        self.phoneNumber = phoneNumber
    }

//     🔹 Convert to Dictionary for Firestore
    func toDictionary() -> [String: Any] {
        return [
            "id": id ?? UUID().uuidString,
            "name": name,
            "email": email,
            "address": address,
            "experience": experience,
            "phoneNumber": phoneNumber
        ]
    }

    // 🔹 Initialize from Firestore Dictionary
    init?(dictionary: [String: Any]) {
        guard let name = dictionary["name"] as? String,
              let email = dictionary["email"] as? String,
              let address = dictionary["address"] as? String,
              let experience = dictionary["experience"] as? String,
              let phoneNumber = dictionary["phoneNumber"] as? String else {
            return nil
        }
        self.id = dictionary["id"] as? String
        self.name = name
        self.email = email
        self.address = address
        self.experience = experience
        self.phoneNumber = phoneNumber
    }
}
struct DoctorModel: Identifiable, Equatable {
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
    
    // Computed properties for convenience
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    var initials: String {
        let firstInitial = firstName.first?.uppercased() ?? ""
        let lastInitial = lastName.first?.uppercased() ?? ""
        return "\(firstInitial)\(lastInitial)"
    }
    
    static func == (lhs: DoctorModel, rhs: DoctorModel) -> Bool {
        lhs.id == rhs.id
    }
}
struct Appointment: Identifiable {
    let id = UUID()
    let doctorName: String
    let specialty: String
    let appointmentDate: String
    let appointmentSlot: String
}
struct TimeSlot: Identifiable {
    let id = UUID()
    var doctorId : String?
    var startTime: Date
    var endTime: Date
}
struct Record: Identifiable {
    let id = UUID()
    let hospitalName: String
    let doctorName: String
    let specialization: String?
    let date: String
    let prescriptionURL: String?
    let billAmount: String?
}
struct DoctorAppointment {
    let doctorName: String
    let specialty: String
    let appointmentDate: String
    let appointmentSlot: String
    let paymentStatus: String
    let paymentState: String
    let appointmentId: String
}
struct Patient: Identifiable {
    let id = UUID()
    var name: String
    var age: String?
    var gender: String?
    var phoneNumber: String?
    var email: String?
    var appointmentDate: String = "N/A" // Default value
    var appointmentSlot: String = "N/A" // Default value
    var isCompleted: Bool = false
    
    // Computed property to get initials from the patient's name
    var initials: String {
        let nameParts = name.split(separator: " ")
        let initials = nameParts.compactMap { part in
            part.first?.uppercased()
        }.prefix(2).joined() // Get first two initials, in case of middle name
        return initials
    }
}


//struct Patient: UserProtocol {
//    var name: String
//    var age: Int
//    var gender: String
//    var phoneNumber: String
//    var email: String
//
//    var initials: String {
//        name.split(separator: " ").map { String($0.prefix(1)) }.joined()
//    }
//}

struct User: Identifiable {
    let id = UUID()        // ✅ Keep 'id' at the top
    var name: String       // ✅ 'name' should come first
    var age: String?       // ✅ 'age' follows 'name'
    var gender: String?    // ✅ 'gender' comes next
    var phoneNumber: String
    var email: String
    var relation: String

    var initials: String {
        name.components(separatedBy: " ").map { String($0.prefix(1)) }.joined()
    }
}

struct SpecializationModel: Identifiable {
    let id: String
    let name: String
    let description: String
    let imageName: String

    init(id: String = UUID().uuidString, name: String, description: String, imageName: String = "") {
        self.id = id
        self.name = name
        self.description = description
        self.imageName = imageName
    }
}



//func fetchHospitals() {
//    let db = Firestore.firestore()
//    db.collection("hospitals").getDocuments { snapshot, error in
//        if let error = error {
//            print("Error fetching hospitals: \(error)")
//            return
//        }
//        
//        if let snapshot = snapshot {
//            let hospitals = snapshot.documents.compactMap { doc -> Hospital? in
//                try? doc.data(as: Hospital.self)
//            }
//            print(hospitals)  // Debugging output
//        }
//    }
//}
//
//
//
