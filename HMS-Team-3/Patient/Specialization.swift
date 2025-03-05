import SwiftUI

struct Specialization: View {
    @State private var searchText: String = ""
    let specializations: [SpecializationModel]
    let doctors:[DoctorModel]
    var patientEmail:String
    var filteredSpecializations: [SpecializationModel] {
        if searchText.isEmpty {
            return specializations
        } else {
            return specializations.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                Text("Specializations")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                SearchBar(searchText: $searchText)
                    .padding(.horizontal)
                
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(filteredSpecializations, id: \ .name) { specialization in
                            SpecializationCard(specialization: specialization,doctors: doctors, patientEmail: patientEmail)
                        }
                    }
                    .padding()
                }
            }
            .background(Color(uiColor: UIColor.systemGroupedBackground))
//            .navigationBarHidden(true)
        }
    }
}




import SwiftUI

struct SpecializationCard: View {
    let specialization: SpecializationModel
    let doctors: [DoctorModel] // Add doctors list here
    let patientEmail:String
    var body: some View {
        NavigationLink(destination: SpecialisationDoctorView(specialization: specialization, patientEmail: patientEmail)) { // Pass doctors
            VStack(alignment: .center, spacing: 8) {
                Image(systemName: specialization.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.blue)
                
                Text(specialization.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(specialization.description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(width: 160, height: 220)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SearchBar: View {
    @Binding var searchText: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search Specializations", text: $searchText)
                .padding(8)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(10)
        .background(Color(uiColor: UIColor.systemGray5))
        .cornerRadius(10)
    }
}

struct Specialization_Previews: PreviewProvider {
    static var previews: some View {
        Specialization(specializations: [
            SpecializationModel(name: "Cardiology", description: "Heart Specialist", imageName: "heart.fill"),
            SpecializationModel(name: "Neurology", description: "Brain Specialist", imageName: "brain.head.profile"),
            SpecializationModel(name: "Orthopedics", description: "Bone Specialist", imageName: "figure.walk"),
        ],doctors: [
            DoctorModel(id: "", firstName: "", lastName: "", specialization: "", phone: "", email: "", experience: "", degrees: [""], medicalLicenseId: "", bankAccountNumber: "", address: "")
        ], patientEmail: "shivamdubey177@gmail.com")
    }
}
