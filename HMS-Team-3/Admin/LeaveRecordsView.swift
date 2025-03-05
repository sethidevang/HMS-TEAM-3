import SwiftUI
import FirebaseFirestore
import FirebaseCore

struct LeaveRecordsView: View {
    @State private var searchText: String = ""
    @State private var leaveRecords: [LeaveRecord] = []
    @State private var selectedFilter: String = "All"

    var filteredRecords: [LeaveRecord] {
        let records = searchText.isEmpty ? leaveRecords : leaveRecords.filter {
            $0.doctorName.localizedCaseInsensitiveContains(searchText)
        }
        
        switch selectedFilter {
        case "Approved":
            return records.filter { $0.status == "Approved" }
        case "Rejected":
            return records.filter { $0.status == "Rejected" }
        default:
            return records
        }
    }

    var leaveCount: Int {
        filteredRecords.count
    }

    var body: some View {
        NavigationStack {
            VStack {
                // Search Bar
                PatientSearchBar(searchText: $searchText)

                // Segmented Control for Filtering
                Picker("Filter", selection: $selectedFilter) {
                    Text("All (\(leaveRecords.count))").tag("All")
                    Text("Approved (\(leaveRecords.filter { $0.status == "Approved" }.count))").tag("Approved")
                    Text("Rejected (\(leaveRecords.filter { $0.status == "Rejected" }.count))").tag("Rejected")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                // Leave Records List
                List(filteredRecords) { record in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(record.doctorName)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.black)

                        HStack {
                            Text("Status:")
                                .fontWeight(.semibold)
                            Text(record.status)
                                .foregroundColor(statusColor(status: record.status))
                        }

                        HStack {
                            Text("Start Date:")
                                .fontWeight(.semibold)
                            Text(record.startDate)
                        }

                        HStack {
                            Text("End Date:")
                                .fontWeight(.semibold)
                            Text(record.endDate)
                        }

                        HStack {
                            Text("Leave Type:")
                                .fontWeight(.semibold)
                            Text(record.leaveType)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, minHeight: 120)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.gray.opacity(0.2), radius: 4, x: 0, y: 2)
                }
                .listStyle(PlainListStyle())
            }
            .background(Color(.systemGray6))
            .navigationBarTitle("Leave Records", displayMode: .inline)
            .onAppear {
                fetchLeaveRecords()
            }
        }
    }

    func fetchLeaveRecords() {
        let db = Firestore.firestore()
        print("Fetching leave records...")

        db.collection("leaveRequests")
            .whereField("status", in: ["Approved", "Rejected"])
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching records: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents else {
                    print("No documents found.")
                    return
                }

                self.leaveRecords = documents.compactMap { doc -> LeaveRecord? in
                    let data = doc.data()
                    print("Fetched Data: \(data)") // Debugging log

                    guard let doctorName = data["doctorName"] as? String,
                          let status = data["status"] as? String,
                          let startTimestamp = data["startDate"] as? Timestamp,
                          let endTimestamp = data["endDate"] as? Timestamp,
                          let leaveType = data["leaveType"] as? String else {
                        print("Skipping document due to missing fields.")
                        return nil
                    }

                    // Convert Timestamps to a readable date string
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateStyle = .medium
                    dateFormatter.timeStyle = .none

                    let startDateString = dateFormatter.string(from: startTimestamp.dateValue())
                    let endDateString = dateFormatter.string(from: endTimestamp.dateValue())

                    return LeaveRecord(
                        id: doc.documentID,
                        doctorName: doctorName,
                        status: status,
                        startDate: startDateString,
                        endDate: endDateString,
                        leaveType: leaveType
                    )
                }
            }
    }

    func statusColor(status: String) -> Color {
        switch status {
        case "Approved": return .green
        case "Rejected": return .red
        default: return .gray
        }
    }
}

struct LeaveRecord: Identifiable {
    let id: String
    let doctorName: String
    let status: String
    let startDate: String
    let endDate: String
    let leaveType: String
}

#Preview {
    LeaveRecordsView()
}
