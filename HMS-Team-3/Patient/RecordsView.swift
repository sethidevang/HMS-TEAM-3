import SwiftUI



struct RecordsView: View {
    @State private var selectedTab = "Medical"
    @Binding var medicalRecords: [Record]
    @Binding var billRecords: [Record]

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                Picker("Records", selection: $selectedTab) {
                    Text("Medical").tag("Medical")
                    Text("Bills").tag("Bills")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                List(selectedTab == "Medical" ? medicalRecords : billRecords) { record in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(record.hospitalName)
                            .font(.headline)
                        Text("Dr. \(record.doctorName)")
                            .font(.subheadline)
                        if let specialization = record.specialization {
                            Text(specialization)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        // Use a HStack with alignment to correctly display "Date:" and the actual date
                        HStack {
                            Text("Date:")
                                .font(.footnote)
                            
                            Text(record.date)
                                .font(.footnote)
                        }

                        // Show the bill amount only in the "Bills" tab
                        if selectedTab == "Bills", let billAmount = record.billAmount {
                            HStack {
                                Spacer()
                                Text("Rs. \(billAmount)")
                                    .foregroundColor(.green)
                                    .fontWeight(.bold)
                            }
                        }
                    }
//                    .padding(.vertical, 5)
                }
            }
            .background(Color(UIColor.systemGray6))
            .navigationTitle("Records") // Set the navigation title
            .navigationBarTitleDisplayMode(.large) // Set the title display mode to large
        }
    }
}

// Preview with mock data
struct RecordsView_Previews: PreviewProvider {
    static var previews: some View {
        StatefulPreviewWrapper(
            [
                Record(hospitalName: "City Hospital", doctorName: "Dr. Smith", specialization: "Cardiology", date: "2025-02-15", prescriptionURL: nil, billAmount: nil),
                Record(hospitalName: "Global Health Clinic", doctorName: "Dr. Green", specialization: "Dermatology", date: "2025-02-14", prescriptionURL: nil, billAmount: "5000"),
                Record(hospitalName: "Sunrise Medical Center", doctorName: "Dr. Brown", specialization: "Pediatrics", date: "2025-02-13", prescriptionURL: "https://example.com/prescription.pdf", billAmount: "2000")
            ],
            [
                Record(hospitalName: "Sunshine Hospital", doctorName: "Dr. Taylor", specialization: nil, date: "2025-01-25", prescriptionURL: nil, billAmount: "1500"),
                Record(hospitalName: "Rainbow Clinic", doctorName: "Dr. White", specialization: "Orthopedics", date: "2025-02-05", prescriptionURL: nil, billAmount: "3500")
            ]
        ) { medicalRecords, billRecords in
            RecordsView(medicalRecords: medicalRecords, billRecords: billRecords)
        }
    }
}

struct StatefulPreviewWrapper<Content: View>: View {
    @State private var medicalRecords: [Record]
    @State private var billRecords: [Record]
    let content: (Binding<[Record]>, Binding<[Record]>) -> Content

    init(
        _ initialMedicalRecords: [Record],
        _ initialBillRecords: [Record],
        content: @escaping (Binding<[Record]>, Binding<[Record]>) -> Content
    ) {
        self._medicalRecords = State(initialValue: initialMedicalRecords)
        self._billRecords = State(initialValue: initialBillRecords)
        self.content = content
    }

    var body: some View {
        content($medicalRecords, $billRecords)
    }
}
