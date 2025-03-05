import SwiftUI
import FirebaseFirestore
import Firebase

struct SetTimingsView: View {
    @State private var selectedDate = Date()
    @State private var startTime = Date()
    @State private var endTime = Date()
//    @State private var maxPatients = 1
    @State private var weeklySchedule: [Date: [TimeSlot]] = [:]

    let doctorId: String

    var body: some View {
        Form {
            Section(header: Text("Add a New Time Slot").font(.headline)) {
                DatePicker("Select Date", selection: $selectedDate, in: Date()...Calendar.current.date(byAdding: .day, value: 7, to: Date())!, displayedComponents: .date)
                
                DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
                
//                Stepper(value: $maxPatients, in: 1...10) {
//                    Text("Max Patients: \(maxPatients)")
//                }
                
                Button(action: addSlot) {
                    Text("Add Slot")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
            
            ForEach(weeklySchedule.keys.sorted(), id: \.self) { date in
                if let slots = weeklySchedule[date], !slots.isEmpty {
                    Section(header: Text(formatDate(date)).font(.headline)) {
                        ForEach(slots) { slot in
                            SlotRow(slot: slot, date: date, weeklySchedule: $weeklySchedule, doctorId: doctorId)
                        }
                    }
                }
            }
        }
//        .navigationTitle("Set Timings")
//        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            fetchSlots()
        }
    }
    
    private func addSlot() {
        let newSlot = TimeSlot(
            doctorId: doctorId,
            startTime: startTime,
            endTime: endTime
//            maxPatients: maxPatients
        )

        if weeklySchedule[selectedDate] != nil {
            weeklySchedule[selectedDate]?.append(newSlot)
        } else {
            weeklySchedule[selectedDate] = [newSlot]
        }

        saveSlotToFirestore(newSlot, date: selectedDate)

        startTime = Date()
        endTime = Date()
//        maxPatients = 1
    }
    
    private func saveSlotToFirestore(_ slot: TimeSlot, date: Date) {
        let db = Firestore.firestore()
        let docRef = db.collection("doctor_schedules").document(UUID().uuidString)

        var slotsArray: [[String: Any]] = []
        var slotStartTime = slot.startTime
        let slotEndTime = slot.endTime
        var totalSlots = 0

        while slotStartTime < slotEndTime {
            let formattedTime = DateFormatter.localizedString(from: slotStartTime, dateStyle: .none, timeStyle: .short)
            
            slotsArray.append([
                "time": formattedTime,
                "isBooked": false
            ])
            
            // Safely add 30 minutes
            guard let newStartTime = Calendar.current.date(byAdding: .minute, value: 40, to: slotStartTime) else {
                print("Error: Could not add time")
                break
            }
            
            slotStartTime = newStartTime
            totalSlots += 1
        }

        print("Total Slots Created: \(totalSlots)")


        let scheduleData: [String: Any] = [
            "doctorId": doctorId,
            "date": Timestamp(date: date),
            "startTime": Timestamp(date: slot.startTime),
            "endTime": Timestamp(date: slot.endTime),
//            "maxPatients": totalSlots,
            "slots": slotsArray
        ]

        docRef.setData(scheduleData) { error in
            if let error = error {
                print("Error saving slots: \(error.localizedDescription)")
            } else {
                print("Slots saved successfully")
            }
        }
    }

    private func fetchSlots() {
        let db = Firestore.firestore()
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!

        db.collection("doctor_schedules")
            .whereField("doctorId", isEqualTo: doctorId)
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startDate))
            .whereField("date", isLessThanOrEqualTo: Timestamp(date: endDate))
            .getDocuments { (snapshot, error) in
                if let error = error {
                    print("Error fetching slots: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents else { return }

                var newSchedule: [Date: [TimeSlot]] = [:]

                for document in documents {
                    let data = document.data()
                    if let date = (data["date"] as? Timestamp)?.dateValue(),
                       let startTime = (data["startTime"] as? Timestamp)?.dateValue(),
                       let endTime = (data["endTime"] as? Timestamp)?.dateValue(),
                       let maxPatients = data["maxPatients"] as? Int {

                        let slot = TimeSlot(doctorId: doctorId, startTime: startTime, endTime: endTime)
                        
                        if newSchedule[date] != nil {
                            newSchedule[date]?.append(slot)
                        } else {
                            newSchedule[date] = [slot]
                        }
                    }
                }

                DispatchQueue.main.async {
                    self.weeklySchedule = newSchedule
                }
            }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }
}

// MARK: - SlotRow
struct SlotRow: View {
    @State var slot: TimeSlot
    var date: Date
    @Binding var weeklySchedule: [Date: [TimeSlot]]
    let doctorId: String
    @State private var isEditing = false

    var body: some View {
        VStack {
            HStack {
                Text("\(formatTime(slot.startTime)) - \(formatTime(slot.endTime))")
                    .font(.body)
                Spacer()
//                Text("Patients: \(slot.maxPatients)")
//                    .font(.subheadline)
            }
            .padding(.vertical, 5)

            HStack {
                Button("Edit") {
                    isEditing = true
                }

                Spacer()

                Button("Delete") {
                    removeSlot()
                }
                .foregroundColor(.red)
            }
        }
        .sheet(isPresented: $isEditing) {
            EditSlotView(slot: $slot, weeklySchedule: $weeklySchedule, date: date, doctorId: doctorId, isEditing: $isEditing)
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func removeSlot() {
        let db = Firestore.firestore()
        db.collection("doctor_schedules")
            .whereField("doctorId", isEqualTo: doctorId)
            .whereField("date", isEqualTo: Timestamp(date: date))
            .getDocuments { (snapshot, error) in
                if let error = error {
                    print("Error deleting slot: \(error.localizedDescription)")
                    return
                }

                snapshot?.documents.forEach { doc in
                    doc.reference.delete()
                }

                weeklySchedule[date]?.removeAll { $0.id == slot.id }
            }
    }
}

// MARK: - EditSlotView
struct EditSlotView: View {
    @Binding var slot: TimeSlot
    @Binding var weeklySchedule: [Date: [TimeSlot]]
    var date: Date
    let doctorId: String
    @Binding var isEditing: Bool

    var body: some View {
        Form {
            DatePicker("Start Time", selection: $slot.startTime, displayedComponents: .hourAndMinute)
            DatePicker("End Time", selection: $slot.endTime, displayedComponents: .hourAndMinute)
        }
        .navigationTitle("Edit Slot")
        .navigationBarItems(trailing: Button("Save") {
            isEditing = false
        })
    }
}

#Preview {
    SetTimingsView(doctorId: "90")
}
