import SwiftUI

struct GetStartedView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Spacer()
                
                // **App Title**
                Text("HMS Pro")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                // **Subtitle**
                Text("Efficient, Smart & Reliable Hospital Management")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Spacer()
                
                // **Get Started Button**
                NavigationLink(destination: PatientRegistrationView()) { // Change destination accordingly
                    Text("Get Started")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
            }
            .padding()
            .background(Color(UIColor.systemGroupedBackground)) // Light gray Apple-style background
        }
    }
}

#Preview {
    GetStartedView()
}
