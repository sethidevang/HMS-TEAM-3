import SwiftUI

struct Appointments: View {
    @State private var selectedTab = "Pending"
    @StateObject var appointmentManager = AppointmentManager.shared // ✅ Changed to @StateObject
    var patientEmail: String
    
    var body: some View {
        NavigationStack {
            VStack {
                // Picker for Pending, Completed, and Canceled
                Picker("Appointments", selection: $selectedTab) {
                    Text("Pending").tag("Pending")
                    Text("Completed").tag("Completed")
                    Text("Canceled").tag("Canceled")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                // Appointment List
                appointmentListView
            }
//            .navigationBarItems(trailing:
//                NavigationLink(destination: BookAppointmentSelectionView(patientManager: PatientManager(), patientEmail: patientEmail)
//                    .environmentObject(appointmentManager)
//                ) {
//                    Image(systemName: "plus")
//                        .font(.title2)
//                }
//            )
            .background(Color(UIColor.systemGray6))
            .navigationTitle("Appointments")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                appointmentManager.setPatientEmail(patientEmail) // ✅ Fetch appointments on load
            }
        }
    }
    
    // Extracted computed property for cleaner code
    private var appointmentListView: some View {
        List {
            let appointments = selectedTab == "Pending" ? appointmentManager.scheduledAppointments :
                               selectedTab == "Completed" ? appointmentManager.completedAppointments :
                               appointmentManager.canceledAppointments  // ✅ Fixed property name

            ForEach(appointments, id: \.id) { appointment in
                let doctorFees = appointmentManager.doctorFeesDict[appointment.doctorName] ?? "N/A"
                let statusColor: Color = selectedTab == "Pending" ? .yellow :
                                                     selectedTab == "Completed" ? .green :
                                                     .red // Canceled

                NavigationLink(destination: getAppointmentDetailView(appointment: appointment, doctorFees: doctorFees)) {
                    AppointmentRow(appointment: appointment, doctorFees: doctorFees,statusColor: statusColor)
                }
            }
        }
        .listStyle(PlainListStyle())
        .background(Color(.systemGray6))
    }

    
    // Function to determine the destination view for NavigationLink
    private func getAppointmentDetailView(appointment: Appointment, doctorFees: String) -> some View {
        if selectedTab == "Pending" {
            return AnyView(ScheduleAppointment(appointment: DoctorAppointment(
                doctorName: appointment.doctorName,
                specialty: appointment.specialty,
                appointmentDate: appointment.appointmentDate,
                appointmentSlot: appointment.appointmentSlot,
                paymentStatus: doctorFees,
                paymentState: "Unpaid",
                appointmentId: appointment.id.uuidString
            )))
        } else if selectedTab == "Completed" {
            return AnyView(CompletedAppointment(appointment: DoctorAppointment(
                doctorName: appointment.doctorName,
                specialty: appointment.specialty,
                appointmentDate: appointment.appointmentDate,
                appointmentSlot: appointment.appointmentSlot,
                paymentStatus: "500",
                paymentState: "Paid",
                appointmentId: appointment.id.uuidString
            ), patientEmail: patientEmail))
        } else {
            return AnyView(AppointmentRow(appointment: appointment, doctorFees: doctorFees, statusColor: .red))
        }
    }
}

// MARK: - Appointment Row View
struct AppointmentRow: View {
    let appointment: Appointment
    let doctorFees: String
    let statusColor: Color

    var body: some View {
        HStack {
            Image(systemName: "person.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .foregroundColor(.gray)

            VStack(alignment: .leading) {
                Text(appointment.doctorName)
                    .font(.headline)
                Text(appointment.specialty)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text("Fees: \(doctorFees)")
                    .font(.footnote)
                    .foregroundStyle(.blue)
                    .bold()

                Text("Appointment Date: \(appointment.appointmentDate)")
                    .font(.footnote)

                Text("Appointment Slot: \(appointment.appointmentSlot)")
                    .font(.footnote)
                    .bold()
            }
            .padding(.leading, 13)
            Spacer()
        }
        .background(Color(UIColor.systemBackground))
        .padding(.vertical, 10)
    }
}

// MARK: - Appointments Preview
struct Appointments_Previews: PreviewProvider {
    static var previews: some View {
        Appointments(patientEmail: "09")
            .environmentObject(AppointmentManager()) // ✅ Pass AppointmentManager
    }
}
