import SwiftUI

struct PatientRecordsView: View {
    
    @State private var searchText = ""
    @State private var patients: [Patient] = completedPatientsData  // Only show completed appointments
    
    private var filteredPatients: [Patient] {
        patients.filter { patient in
            searchText.isEmpty || patient.name.lowercased().contains(searchText.lowercased())
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search by name", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding()
                .background(Color(UIColor.systemGray5))
                .cornerRadius(10)
                .padding(.horizontal)

                // Patient List
                if filteredPatients.isEmpty {
                    Spacer()
                } else {
                    List(filteredPatients) { patient in
                        NavigationLink(destination: PatientDetailView(patient: patient, onAppointmentEnd: {}, doctorId: "h")) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(patient.name)
                                        .font(.headline)
                                    Text("Age: \(patient.age) | \(patient.gender)")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                Text(patient.appointmentDate)
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                            .padding(.vertical, 5)
                        }
                    }
                    .listStyle(PlainListStyle())
                    .background(Color.white) // List background only
                }
            }
            .background(Color(UIColor.systemGray6)) // Background for empty space
            .navigationTitle("Patient Records")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.white, for: .navigationBar) // White navigation bar
        }
    }
}

#Preview {
    NavigationStack {
        PatientRecordsView()
    }
}
