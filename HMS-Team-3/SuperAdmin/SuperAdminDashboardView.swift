import SwiftUI
import Firebase
import FirebaseFirestore

struct SuperAdminDashboardView: View {
    @State private var searchText = ""
    @State private var isAddingHospital = false
    @State private var selectedTab = 0
    @State private var hospitals: [Hospital] = []
    private let db = Firestore.firestore()
    
    var filteredHospitals: [Hospital] {
        if searchText.isEmpty {
            return hospitals
        }
        return hospitals.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.location.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                VStack(alignment: .leading) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.black)

                        TextField("Search", text: $searchText)
                            .foregroundColor(.black)
                            .padding(8)

                        Spacer()

                        Button(action: { }) { // Voice search action placeholder
                            Image(systemName: "mic.fill")
                                .foregroundColor(.black)
                        }
                    }
                    .padding(10)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    .padding(.horizontal)

                    // Hospital List
                    ScrollView {
                        if !searchText.isEmpty && filteredHospitals.isEmpty {
                            VStack {
                                Text("No search results found")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                    .padding()
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            VStack(spacing: 10) {
                                ForEach(filteredHospitals) { hospital in
                                    NavigationLink(destination: HospitalDetailView(hospital: hospital)) {
                                        HospitalCard(
                                            name: hospital.name,
                                            location: hospital.location,
                                            adminName: hospital.admin.name                                        )
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                    Spacer()
                }
                .background(Color(UIColor.systemGray6).edgesIgnoringSafeArea(.all))
                .sheet(isPresented: $isAddingHospital) {
                    AddHospitalView()
                }
                .onAppear {
                    setupRealTimeListener()
                }
                .navigationTitle("Dashboard")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { isAddingHospital = true }) {
                            Image(systemName: "plus")
                                .font(.title3)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .tabItem {
                Image(systemName: "plus.circle")
                Text("Dashboard")
            }
            .tag(0)

            NavigationStack {
                SuperAdminProfile()
            }
            .tabItem {
                Image(systemName: "person.crop.circle")
                Text("Profile")
            }
            .tag(1)
        }
        .toolbarBackground(.gray, for: .tabBar)
    }

    // Set up Firestore real-time listener
    func setupRealTimeListener() {
        db.collection("hospitals").addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error fetching hospitals: \(error.localizedDescription)")
                return
            }

            guard let snapshot = snapshot else { return }

            DispatchQueue.global(qos: .background).async {
                let fetchedHospitals: [Hospital] = snapshot.documents.compactMap { document in
                    let data = document.data()
                    guard let name = data["name"] as? String,
                          let location = data["location"] as? String,
                          let adminData = data["admin"] as? [String: Any],
                          let adminName = adminData["name"] as? String,
                          let adminEmail = adminData["email"] as? String,
                          let adminAddress = adminData["address"] as? String,
                          let adminExperience = adminData["experience"] as? String,
                          let adminPhoneNumber = adminData["phoneNumber"] as? String else { return nil }

                    let admin = Admin(name: adminName, email: adminEmail, address: adminAddress, experience: adminExperience, phoneNumber: adminPhoneNumber)

                    return Hospital(
                        id: document.documentID,
                        name: name,
                        location: location,
                        admin: admin,
                        revenue: data["revenue"] as? String,
                        unpaidDues: data["unpaidDues"] as? String,
                        expenses: data["expenses"] as? String
                    )
                }

                DispatchQueue.main.async {
                    hospitals = fetchedHospitals
                }
            }
        }
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        SuperAdminDashboardView()
    }
}
