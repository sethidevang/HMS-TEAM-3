import SwiftUI
import FirebaseFirestore

struct AdminLeaveDashboard: View {
    let hospitalId: String
    @State private var leaveRequests: [LeaveRequest] = []
    @State private var isSelectionMode = false
    @State private var selectedRequests: Set<String> = []
    @State private var snackbarMessage: String = ""
    @State private var showSnackbar: Bool = false
    @State private var selectedStatus = "Pending" // Default selection

    private var filteredRequests: [LeaveRequest] {
        leaveRequests.filter { $0.status == selectedStatus }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // Segmented Control
                Picker("Status", selection: $selectedStatus) {
                    Text("Pending (\(count(for: "Pending")))")
                        .tag("Pending")
                    Text("Approved (\(count(for: "Approved")))")
                        .tag("Approved")
                    Text("Rejected (\(count(for: "Rejected")))")
                        .tag("Rejected")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // List of Requests
                List {
                    ForEach(filteredRequests) { request in
                        LeaveRequestRow(request: request, isSelectionMode: isSelectionMode, isSelected: selectedRequests.contains(request.id)) {
                            toggleSelection(for: request.id)
                        }
                        .swipeActions {
                            if !isSelectionMode && request.status == "Pending" {
                                Button(role: .destructive) {
                                    rejectRequest(request)
                                } label: {
                                    Label("Reject", systemImage: "xmark.circle.fill")
                                }
                                .tint(.red)

                                Button {
                                    approveRequest(request)
                                } label: {
                                    Label("Approve", systemImage: "checkmark.circle.fill")
                                }
                                .tint(.green)
                            }
                        }
                    }
                }
                
                // Bulk Actions
                if isSelectionMode {
                    HStack {
                        Button("Approve") {
                            approveSelectedRequests()
                        }
                        .foregroundColor(selectedRequests.isEmpty ? .gray : .blue)
                        .disabled(selectedRequests.isEmpty)
                        .frame(maxWidth: .infinity)
                        
                        Button("Reject") {
                            rejectSelectedRequests()
                        }
                        .foregroundColor(selectedRequests.isEmpty ? .gray : .red)
                        .disabled(selectedRequests.isEmpty)
                        .frame(maxWidth: .infinity)
                    }
                    .padding()
                }
            }
            .navigationTitle("Leave Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isSelectionMode {
                        Button("Select All") {
                            selectAllRequests()
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isSelectionMode ? "Cancel" : "Select") {
                        toggleSelectionMode()
                    }
                }
            }
            .onAppear {
                fetchLeaveRequests()
            }
        }
    }

    private func fetchLeaveRequests() {
        let db = Firestore.firestore()
        db.collection("leaveRequests")
            .whereField("hospitalId", isEqualTo: hospitalId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching leave requests: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                let requests: [LeaveRequest] = documents.map { doc in
                    let data = doc.data()
                    
                    return LeaveRequest(
                        id: doc.documentID,
                        type: data["leaveType"] as? String ?? "Unknown",
                        startDate: (data["startDate"] as? Timestamp)?.dateValue() ?? Date(),
                        endDate: (data["endDate"] as? Timestamp)?.dateValue() ?? Date(),
                        status: data["status"] as? String ?? "Pending",
                        color: getColor(from: data["color"] as? String ?? "Gray"),
                        doctorId: data["doctorId"] as? String ?? "Unknown",
                        hospitalId: hospitalId,
                        doctorName: data["doctorName"] as? String ?? "Unknown Doctor",
                        specialization: data["specialization"] as? String ?? "General",
                        reason: data["reason"] as? String ?? "No reason provided"
                    )
                }
                
                DispatchQueue.main.async {
                    self.leaveRequests = requests
                }
            }
    }

    private func count(for status: String) -> Int {
        leaveRequests.filter { $0.status == status }.count
    }

    private func getColor(from colorName: String) -> Color {
        switch colorName.lowercased() {
        case "red": return .red
        case "green": return .green
        case "blue": return .blue
        case "yellow": return .yellow
        case "gray": return .gray
        default: return .black
        }
    }

    private func toggleSelectionMode() {
        isSelectionMode.toggle()
        if !isSelectionMode {
            selectedRequests.removeAll()
        }
    }
    
    private func toggleSelection(for id: String) {
        if let request = leaveRequests.first(where: { $0.id == id }), request.status == "Pending" {
            if selectedRequests.contains(id) {
                selectedRequests.remove(id)
            } else {
                selectedRequests.insert(id)
            }
        }
    }

    private func selectAllRequests() {
        selectedRequests = Set(filteredRequests.map { $0.id })
    }

    private func approveRequest(_ request: LeaveRequest) {
        updateRequestStatus(for: [request.id], status: "Approved")
    }
    
    private func rejectRequest(_ request: LeaveRequest) {
        updateRequestStatus(for: [request.id], status: "Rejected")
    }

    private func approveSelectedRequests() {
        updateRequestStatus(for: Array(selectedRequests), status: "Approved")
    }
    
    private func rejectSelectedRequests() {
        updateRequestStatus(for: Array(selectedRequests), status: "Rejected")
    }

    private func updateRequestStatus(for requestIds: [String], status: String) {
        let db = Firestore.firestore()
        let batch = db.batch()
        
        requestIds.forEach { id in
            let requestRef = db.collection("leaveRequests").document(id)
            batch.updateData(["status": status], forDocument: requestRef)
        }
        
        batch.commit { error in
            if error == nil {
                DispatchQueue.main.async {
                    self.leaveRequests = self.leaveRequests.map { request in
                        if requestIds.contains(request.id) {
                            var updatedRequest = request
                            updatedRequest.status = status
                            return updatedRequest
                        }
                        return request
                    }
                    self.selectedRequests.removeAll()
                    self.isSelectionMode = false
                    self.showMessage(status == "Approved" ? "✅ Approved selected requests" : "❌ Rejected selected requests")
                }
            }
        }
    }
    
    private func showMessage(_ message: String) {
        snackbarMessage = message
        showSnackbar = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            showSnackbar = false
        }
    }
}


    
//    private func approveSelectedRequests() {
//        leaveRequests.removeAll { selectedRequests.contains($0.id) }
//        selectedRequests.removeAll()
//        isSelectionMode = false
//        print("✅ Approved selected requests")
//    }
//
//    private func rejectSelectedRequests() {
//        leaveRequests.removeAll { selectedRequests.contains($0.id) }
//        selectedRequests.removeAll()
//        isSelectionMode = false
//        print("❌ Rejected selected requests")
//    }
//}


struct LeaveRequestRow: View {
    let request: LeaveRequest
    let isSelectionMode: Bool
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        HStack {
            if isSelectionMode {
                Button(action: {
                    if request.status == "Pending" { // ✅ Ensure only Pending requests are selectable
                        onSelect()
                    }
                }) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(request.status == "Pending" ? (isSelected ? .blue : .gray) : .clear) // Hide for non-pending requests
                }
                .disabled(request.status != "Pending") // 🚫 Disable button for non-pending requests
                .padding(.trailing, 8)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(request.doctorName) (\(request.specialization))")
                    .font(.headline)
                
                HStack {
                    Text("From: \(formatDate(request.startDate))")
                    Spacer()
                    Text("To: \(formatDate(request.endDate))")
                }
                .font(.subheadline)
                
                Text("Leave Type: \(request.type)")
                    .font(.subheadline)
                    .bold()
                
                Text(request.reason)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                // Display Status
                Text("Status: \(request.status)")
                    .font(.caption)
                    .foregroundColor(request.status == "Approved" ? .green : request.status == "Rejected" ? .red : .gray)
                    .bold()
            }
        }
        .padding()
        .background(request.status == "Approved" ? Color.green.opacity(0.2) :
                    request.status == "Rejected" ? Color.red.opacity(0.2) : Color.white)
        .cornerRadius(10)
    }


    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}


struct AdminLeaveDashboard_Previews: PreviewProvider {
    static var previews: some View {
        AdminLeaveDashboard(hospitalId: "H456")
    }
}
