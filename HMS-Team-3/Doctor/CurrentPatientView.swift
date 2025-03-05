import SwiftUI
import PencilKit


struct CurrentPatientView: View {
    var patient: Patient // Receive the patient object

    @State private var showMedicalRecords = false
    @State private var canvasView = PKCanvasView()
    @State private var showEndMeetingAlert = false
    @State private var savedDrawings: [String: PKDrawing] = [:] // Store whiteboard drawings

    var currentDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d, yyyy"
        return formatter.string(from: Date())
    }

    var body: some View {
        ZStack {
            // Full-Screen Whiteboard
            WhiteboardView(canvasView: $canvasView)
                .edgesIgnoringSafeArea(.all)

            VStack {
                // Header
                HStack {
                    Button(action: { showMedicalRecords.toggle() }) {
                        Image(systemName: "list.bullet")
                            .foregroundColor(.blue)
                            .font(.title)
                    }
                    .padding()

                    VStack(alignment: .leading) {
                        Text("Apollo Hospital")
                            .font(.title2)
                            .bold()
                            .foregroundColor(Color.primary)
                        Text("Dr. Kuldeep (Neurologist)")
                            .font(.subheadline)
                            .foregroundColor(Color.secondary)
                    }
                    
                    Spacer()
                    
                    // Date
                    Text(currentDate)
                        .font(.headline)
                        .foregroundColor(Color.primary)
                    
                    Spacer()

                    // Patient Details
                    VStack(alignment: .trailing) {
                        Text("Patient: \(patient.name)")
                            .font(.headline)
                            .foregroundColor(Color.primary)
                        Text("Age: \(patient.age), Gender: \(patient.gender)")
                            .font(.subheadline)
                            .foregroundColor(Color.secondary)
                    }
                    .padding()
                }

                Spacer()

                // Doctor's Digital Signature
                VStack {
                    Text("Dr. Kuldeep")
                        .font(.title3)
                        .bold()
                        .foregroundColor(Color.primary)
                    Text("(Digital Signature)")
                        .font(.caption)
                        .foregroundColor(Color.secondary)
                }

                // End Meeting Button
                Button(action: {
                    showEndMeetingAlert = true
                    savedDrawings[currentDate] = canvasView.drawing // Save drawing with date as key
                }) {
                    Text("End Meeting")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal, 20)
                }
                .padding(.top, 10)
                .padding(.bottom, 20)
                .alert(isPresented: $showEndMeetingAlert) {
                    Alert(
                        title: Text("End Meeting"),
                        message: Text("Are you sure you want to end the meeting?"),
                        primaryButton: .destructive(Text("End")) {
                            print("Meeting Ended")
                        },
                        secondaryButton: .cancel()
                    )
                }
            }

            // Medical Records Overlay
            if showMedicalRecords {
                MedicalRecordsView(isPresented: $showMedicalRecords, savedDrawings: savedDrawings)
                    .transition(.move(edge: .leading))
                    .zIndex(1)
            }
        }
        .navigationBarHidden(true)
    }
}





// Whiteboard View with Apple Pencil Support
struct WhiteboardView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = UIColor.systemBackground
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {}
}

// Full-Screen Medical Records View
struct MedicalRecordsView: View {
    @Binding var isPresented: Bool
    var savedDrawings: [String: PKDrawing]

    let records = [
        "Visit on Jan 10, 2025 - Migraine Treatment",
        "Visit on Dec 22, 2024 - General Checkup",
        "Visit on Nov 15, 2024 - Blood Pressure Issue"
    ]

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Text("Patient Medical Records")
                        .font(.title2)
                        .bold()
                        .foregroundColor(Color.primary)
                    Spacer()
                    Button("Close") { isPresented = false }
                        .foregroundColor(.red)
                }
                .padding()

                List(records, id: \.self) { record in
                    NavigationLink(destination: MedicalRecordDetailView(record: record, drawing: savedDrawings[record] ?? PKDrawing())) {
                        Text(record)
                            .font(.body)
                            .foregroundColor(Color.primary)
                            .padding(.vertical, 5)
                    }
                    .buttonStyle(PlainButtonStyle()) // Prevents double tap, ensures one tap navigation
                }
                .background(Color(.systemBackground))
                .scrollContentBackground(.hidden)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground).edgesIgnoringSafeArea(.all))
        }
        .navigationViewStyle(StackNavigationViewStyle())  // Ensure the navigation behaves as stack on iPad
    }
}


// Detailed Medical Record View (Now Shows Whiteboard)
struct MedicalRecordDetailView: View {
    var record: String
    var drawing: PKDrawing

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(record)
                .font(.title2)
                .bold()
                .foregroundColor(Color.primary)

            Text("Prescription Details")
                .font(.headline)
                .foregroundColor(Color.primary)

            // Display the previous whiteboard (prescription)
            WhiteboardPreview(drawing: drawing)
                .frame(maxWidth: .infinity, maxHeight: 400) // Expanded whiteboard view
                .cornerRadius(10)
                .shadow(radius: 5)

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground).edgesIgnoringSafeArea(.all))
    }
}

// Whiteboard Preview for Displaying Past Prescriptions
struct WhiteboardPreview: UIViewRepresentable {
    var drawing: PKDrawing

    func makeUIView(context: Context) -> PKCanvasView {
        let view = PKCanvasView()
        view.drawing = drawing
        view.isUserInteractionEnabled = false // Read-only mode
        return view
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {}
}

// Preview

