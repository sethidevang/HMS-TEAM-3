import SwiftUI
import Firebase
import FirebaseFirestore

struct LeaveRequest: Identifiable {
    var id: String
    var type: String
    var startDate: Date
    var endDate: Date
    var status: String
    var color: Color
    var doctorId: String
    var hospitalId: String
    var doctorName: String
    var specialization: String
    var reason: String
}

struct LeaveRequestView: View {
    @State private var leaveRequests: [LeaveRequest] = []
    @State private var pendingRequests: [LeaveRequest] = []
    @State private var showLeaveForm = false
    @State private var selectedSegment = "Pending"
    
    var doctorId: String
    var hospitalId: String
    
    let segments = ["Pending", "All Requests"]
    
    var body: some View {
        VStack {
            // Segmented Control always at the top
            Picker("Select", selection: $selectedSegment) {
                ForEach(segments, id: \.self) { segment in
                    Text(segment)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            // If no requests, push text to center
            if (selectedSegment == "Pending" && pendingRequests.isEmpty) ||
               (selectedSegment == "All Requests" && leaveRequests.isEmpty) {
                Spacer()
                Text("No Leave Requests Found")
                    .foregroundColor(.gray)
                    .padding()
                Spacer()
            } else {
                RequestListView(requests: selectedSegment == "Pending" ? pendingRequests : leaveRequests)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showLeaveForm = true }) {
                    Image(systemName: "plus").font(.title)
                }
            }
        }
        .sheet(isPresented: $showLeaveForm) {
            LeaveRequestForm(doctorId: doctorId, hospitalId: hospitalId, onSubmit: { newRequest in
                leaveRequests.append(newRequest)
                if newRequest.status == "Pending" {
                    pendingRequests.append(newRequest)
                }
            })
        }
        .onAppear { fetchLeaveRequests() }
    }


    
    private func fetchLeaveRequests() {
        let db = Firestore.firestore()
        db.collection("leaveRequests")
            .whereField("doctorId", isEqualTo: doctorId)
            .order(by: "startDate", descending: false)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching leave requests: \(error.localizedDescription)")
                    return
                }
                guard let documents = snapshot?.documents else { return }
                
                leaveRequests = documents.compactMap { doc in
                    let data = doc.data()
                    let request = LeaveRequest(
                        id: UUID().uuidString,
                        type: data["leaveType"] as? String ?? "Unknown",
                        startDate: (data["startDate"] as? Timestamp)?.dateValue() ?? Date(),
                        endDate: (data["endDate"] as? Timestamp)?.dateValue() ?? Date(),
                        status: data["status"] as? String ?? "Pending",
                        color: getColor(for: data["status"] as? String ?? "Pending"),
                        doctorId: data["doctorId"] as? String ?? "",
                        hospitalId: data["hospitalId"] as? String ?? "",
                        doctorName: data["doctorName"] as? String ?? "Unknown",
                        specialization: data["specialization"] as? String ?? "Not Specified",
                        reason: data["reason"] as? String ?? "No Reason Provided"
                    )
                    return request
                }
                pendingRequests = leaveRequests.filter { $0.status == "Pending" }
            }
    }
    
    private func getColor(for status: String) -> Color {
        switch status {
        case "Approved": return .green
        case "Rejected": return .red
        default: return .orange
        }
    }
}

struct RequestListView: View {
    var requests: [LeaveRequest]
    
    var body: some View {
        if requests.isEmpty {
            Text("No Leave Requests Found")
                .foregroundColor(.gray)
                .padding()
        } else {
            List(requests) { request in
                LeaveCard(
                    leaveType: request.type,
                    startDate: request.startDate,
                    endDate: request.endDate,
                    status: request.status,
                    statusColor: request.color,
                    reason: request.reason,
                    specialization: request.specialization
                )
            }
        }
    }
}


struct LeaveRequestForm: View {
    @State private var leaveType: String = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()
    @State private var reason: String = ""
    @Environment(\.dismiss) private var dismiss
    
    var doctorId: String
    var hospitalId: String
    var onSubmit: (LeaveRequest) -> Void
    
    let leaveTypes = ["Sick Leave", "Casual Leave", "Annual Leave", "Maternity Leave", "Paternity Leave", "Emergency Leave", "Study Leave", "Medical Leave", "Personal Leave", "Compassionate Leave"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Leave Details")) {
                    Picker("Leave Type", selection: $leaveType) {
                        ForEach(leaveTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                    TextEditor(text: $reason)
                        .frame(height: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                        .padding(.vertical, 5)
                }
                
                Button(action: applyLeave) {
                    Text("Submit")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(leaveType.isEmpty || reason.isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(leaveType.isEmpty || reason.isEmpty)
            }
            .navigationTitle("Apply for Leave")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func applyLeave() {
        let db = Firestore.firestore()
        
        db.collection("doctors").document(doctorId).getDocument { document, error in
            if let error = error {
                print("Error fetching doctor details: \(error.localizedDescription)")
                return
            }
            
            let firstName = document?.data()?["firstName"] as? String ?? "Unknown"
            let lastName = document?.data()?["lastName"] as? String ?? "Unknown"
            let specialization = document?.data()?["specialization"] as? String ?? "Not Specified"
            
            let doctorName = "\(firstName) \(lastName)"
            
            let newRequest = LeaveRequest(
                id: UUID().uuidString,
                type: leaveType,
                startDate: startDate,
                endDate: endDate,
                status: "Pending",
                color: .orange,
                doctorId: doctorId,
                hospitalId: hospitalId,
                doctorName: doctorName,
                specialization: specialization,
                reason: reason
            )
            
            let leaveData: [String: Any] = [
                "leaveType": leaveType,
                "startDate": Timestamp(date: startDate),
                "endDate": Timestamp(date: endDate),
                "reason": reason,
                "status": "Pending",
                "doctorId": doctorId,
                "hospitalId": hospitalId,
                "doctorName": doctorName,
                "specialization": specialization
            ]
            
            db.collection("leaveRequests").addDocument(data: leaveData) { error in
                if let error = error {
                    print("Error saving leave request: \(error.localizedDescription)")
                } else {
                    print("Leave request submitted successfully")
                    onSubmit(newRequest)
                    dismiss()
                }
            }
        }
    }
}


struct LeaveCard: View {
    var leaveType: String
    var startDate: Date
    var endDate: Date
    var status: String
    var statusColor: Color
    var reason: String
    var specialization: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(leaveType)
                    .font(.headline)
                    .foregroundColor(.blue)
                Spacer()
                Text(status)
                    .font(.subheadline)
                    .foregroundColor(statusColor)
                    .padding(6)
                    .background(statusColor.opacity(0.2))
                    .cornerRadius(6)
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Start Date:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(formatDate(startDate))
                        .font(.body)
                }
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("End Date:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(formatDate(endDate))
                        .font(.body)
                }
            }
            
            Text("Reason: \(reason)")
                .font(.body)
                .foregroundColor(.primary)
            
            Text("Specialization: \(specialization)")
                .font(.subheadline)
                .foregroundColor(.secondary)

        }
        .padding()
//        .background(Color.white)
        .cornerRadius(12)
//        .shadow(radius: 3)
        .padding(.horizontal)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}


// Preview
#Preview {
    LeaveRequestView(doctorId: "89", hospitalId: "76")
}
