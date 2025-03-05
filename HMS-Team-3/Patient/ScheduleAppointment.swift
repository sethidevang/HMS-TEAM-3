import SwiftUI



struct ScheduleAppointment: View {
    var appointment: DoctorAppointment
    @State private var showAlert = false
    @EnvironmentObject var appointmentManager: AppointmentManager
    var body: some View {
        VStack(spacing: 16) {
            // Doctor Information Card
            HStack {
                Image(systemName: "person.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .foregroundColor(.gray)
                    .padding(.trailing, 16)

                VStack(alignment: .leading, spacing: 6) {
                    Text(appointment.doctorName)
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text(appointment.specialty)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .padding(.horizontal)

            // Appointment Details
            DetailRow(title: "Appointment Date", value: appointment.appointmentDate)
            DetailRow(title: "Appointment Slot", value: appointment.appointmentSlot)
            DetailRow(title: "Payment Status", value: "\(appointment.paymentStatus) (\(appointment.paymentState))")

            // Cancel Button with Alert Confirmation
            Button(action: {
//                AppointmentManager.shared.selectedAppointment = currentAppointment
//                    // Call the cancellation function without passing parameters
//                    AppointmentManager.shared.cancelAppointment()
                showAlert = true
            }) {
                Text("Cancel Appointment")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.red)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .alert(isPresented: $showAlert) {
                Alert(
                                    title: Text("Cancel Appointment"),
                                    message: Text("Are you sure you want to cancel this appointment?"),
                                    primaryButton: .destructive(Text("OK"), action: {
                                        // Set the currently selected appointment and cancel it without passing any parameter
                                        AppointmentManager.shared.selectedAppointment = appointment
                                        AppointmentManager.shared.cancelAppointment()
                                    }),
                                    secondaryButton: .cancel()
                                )
            }

            // Follow-Up Button (unchanged)
            Button(action: {
                // Handle Follow-Up Action
            }) {
                Text("Follow Up")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding(.top)
        .background(Color(UIColor.systemGray6))
        .navigationTitle("Appointment Detail")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
    }
}
    

// Reusable Detail Row Component
struct DetailRow: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            Text(value)
                .font(.headline)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// Preview with Sample Data
struct ScheduleAppointment_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ScheduleAppointment(appointment: DoctorAppointment(
                doctorName: "Dr. John Smith",
                specialty: "Cardiologist",
                appointmentDate: "11 Feb 2025",
                appointmentSlot: "10:15 AM",
                paymentStatus: "500",
                paymentState: "Unpaid",
                appointmentId: "08281929"
            ))
        }
    }
}

