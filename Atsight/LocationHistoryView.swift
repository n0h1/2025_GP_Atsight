import SwiftUI
import MapKit
import Firebase
import FirebaseFirestore

struct LocationHistoryView: View {
    @State private var locations: [Location] = []
    @State private var selectedLocation: Location?
    @Environment(\.presentationMode) var presentationMode
    @State private var isLoading = true
    // @State private var path = NavigationPath() // Remove or comment this out if not needed for programmatic navigation within this view

    var body: some View {
        // Removed NavigationStack here
        VStack {
            // Header
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(Color("BlackFont"))
                        .font(.system(size: 20, weight: .bold))
                }

                Spacer()

                Text("Location History")
                    .font(.title2)
                    .bold()

                Spacer()
            }
            .padding()

            Text("Recent Places")
                .foregroundColor(Color(red: 90/255, green: 90/255, blue: 90/255))
                .bold()
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 20)
                .padding(.top, 40)
                .padding(.bottom, 10)

            if isLoading {
                ProgressView("Loading...")
                    .padding()
            } else {
                ScrollView {
                    VStack(spacing: 14) {
                        ForEach(locations) { location in
                            // NavigationLink will use the outer NavigationStack from HomeView
                            NavigationLink(destination: MapView(latitude: location.latitude, longitude: location.longitude, locationName: location.name)) {
                                LocationRow(location: location)
                            }
                        }
                        .padding(.top, 5)

                        if locations.isEmpty {
                            Text("No location history found.")
                                .foregroundColor(.gray)
                                .padding()
                        }
                    }
                    .padding(.horizontal, 15)
                }
            }
        }
        // Applied navigation bar modifiers directly to the main VStack
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        // Removed the .navigationDestination modifier here as it was tied to the removed NavigationStack
        .onAppear {
            fetchLocations()
        }
    }

    func fetchLocations() {
        let guardianID = UserDefaults.standard.string(forKey: "guardianID") ?? ""
        let childID = UserDefaults.standard.string(forKey: "childID") ?? ""

        print("🟡 Fetching locations for:")
        print("GuardianID: \(guardianID)")
        print("ChildID: \(childID)")

        guard !guardianID.isEmpty, !childID.isEmpty else {
            print("❌ Missing guardianID or childID")
            isLoading = false
            return
        }

        isLoading = true
        let db = Firestore.firestore()
        db.collection("guardians")
            .document(guardianID)
            .collection("children")
            .document(childID)
            .collection("locationHistory")
            .getDocuments { snapshot, error in
                isLoading = false
                if let error = error {
                    print("❌ Firestore error: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents else {
                    print("⚠️ No documents found.")
                    return
                }

                print("📦 Retrieved \(documents.count) locations")

                self.locations = documents.compactMap { doc in
                    let data = doc.data()
                    guard let coord = data["coordinate"] as? [Double], coord.count == 2 else {
                        print("⚠️ Skipped: Missing coordinates")
                        return nil
                    }

                    let name = data["zoneName"] as? String ?? "Unknown"
                    let address = data["address"] as? String ?? "—"
                    let distance = data["distance"] as? String ?? "—"
                    let isSafe = data["isSafeZone"] as? Bool ?? true

                    let timestamp = data["timestamp"] as? Timestamp
                    let date = timestamp?.dateValue() ?? Date()
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy/MM/dd"
                    let dateStr = formatter.string(from: date)
                    formatter.dateFormat = "h:mm a"
                    let timeStr = formatter.string(from: date)

                    return Location(
                        name: name,
                        address: address,
                        date: dateStr,
                        time: timeStr,
                        distance: distance,
                        latitude: coord[0],
                        longitude: coord[1],
                        isSafeZone: isSafe
                    )
                }
            }
    }

    func formattedDate(_ timestamp: Any?) -> String {
        if let ts = timestamp as? Timestamp {
            let date = ts.dateValue()
            let formatter = DateFormatter()
            formatter.dateFormat = "dd MMM yyyy, HH:mm"
            return formatter.string(from: date)
        }
        return "Unknown Time"
    }
}

// MARK: - Location Model
struct Location: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let address: String
    let date: String
    let time: String
    let distance: String
    let latitude: Double
    let longitude: Double
    let isSafeZone: Bool
}

// MARK: - Map View
struct MapView: View {
    var latitude: Double
    var longitude: Double
    var locationName: String
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            Map(coordinateRegion: .constant(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )), annotationItems: [LocationMarker(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))]) { item in
                MapAnnotation(coordinate: item.coordinate) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                        .shadow(radius: 4)
                }
            }
            .edgesIgnoringSafeArea(.all)

            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Back to Location History")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color("Buttons").opacity(0.7))
                    .foregroundColor(Color("BlackFont"))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding()
            }
        }
        .navigationBarBackButtonHidden(true) // Keep this here to hide the back button on MapView
        // If MapView needs to hide the whole bar, add .navigationBarHidden(true) here too
    }
}

// 👇 تم تغيير الاسم هنا
struct LocationMarker: Identifiable {
    let id = UUID()
    var coordinate: CLLocationCoordinate2D
}

// MARK: - Location Row UI
struct LocationRow: View {
    let location: Location

    var body: some View {
        HStack(alignment: .center) {
            Image(systemName: location.isSafeZone ? "checkmark.shield" : "exclamationmark.triangle")
                .foregroundColor(location.isSafeZone ? .green : .red)
                .font(.title2)

            VStack(alignment: .leading, spacing: 4) {
                Text(location.name)
                    .font(.headline)
                    .foregroundColor(location.isSafeZone ? .green : .red)

                Text("\(location.date) \(location.time)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Color("navBG"))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
    }
}

struct previews: PreviewProvider {
    static var previews: some View {
        LocationHistoryView()
            .environmentObject(AppState()) // Added for preview context
    }
}
