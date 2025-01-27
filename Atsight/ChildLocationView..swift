//
//  ChildLocationView.swift
//  AtSightSprint0Test
//
//  Updated to show last 3 location history entries and navigate to details
//
import SwiftUI
import MapKit
import FirebaseFirestore
import FirebaseAuth

struct LocationPin: Identifiable {
    var id = UUID()
    var coordinate: CLLocationCoordinate2D
}

struct ChildLocationView: View {
    var child: Child
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 23.8859, longitude: 45.0792),
        span: MKCoordinateSpan(latitudeDelta: 5.0, longitudeDelta: 5.0)
    )
    @State private var isMapExpanded = false
    @State private var iconSize: CGFloat = 60
    @Environment(\.presentationMode) var presentationMode
    @State private var latestCoordinate: CLLocationCoordinate2D? = nil
    @State private var recentLocations: [[String: Any]] = []
    @State private var selectedLocation: CLLocationCoordinate2D? = nil
    @State private var selectedLocationName: String? = nil
    @State private var showLocationDetail = false

    private func zoomIn() {
        region.span.latitudeDelta /= 2
        region.span.longitudeDelta /= 2
    }

    private func zoomOut() {
        region.span.latitudeDelta *= 2
        region.span.longitudeDelta *= 2
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(Color("BlackFont"))
                        .font(.system(size: 20, weight: .bold))
                        .padding(8)
                        .background(Color.white)
                        .clipShape(Circle())
                }

                Spacer()

                VStack(spacing: 5) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(Color("Blue"))
                        .background(Circle().fill(Color.white))
                        .overlay(Circle().stroke(Color("CustomBlue"), lineWidth: 2))
                        .shadow(radius: 4)

                    Text("\(child.name)")
                        .font(.headline).bold()
                        .foregroundColor(Color("Blue"))
                }.padding(.leading, 30)

                Spacer()

                Button(action: {}) {
                    Text("HALT")
                        .font(.system(size: 19 , weight: .bold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(18)
                        .shadow(radius: 4)
                }
            }
            .padding()
            .cornerRadius(25)
            .padding(.horizontal)

            Divider().padding(.horizontal)

            ZStack {
                Map(coordinateRegion: $region,
                    annotationItems: latestCoordinate.map { [LocationPin(coordinate: $0)] } ?? []) { pin in
                    MapPin(coordinate: pin.coordinate, tint: .blue)
                }
                .frame(height: isMapExpanded ? 600 : 350)
                .cornerRadius(30)
                .padding(.horizontal)
                .animation(.spring(), value: isMapExpanded)
                .onTapGesture { isMapExpanded.toggle() }
            }
            .padding(.bottom, isMapExpanded ? 0 : -40)
            .onAppear {
                fetchLatestLocation()
                fetchRecentLocationHistory()
            }

            HStack(spacing: 20) {
                Button(action: zoomOut) {
                    Image(systemName: "minus.magnifyingglass")
                        .font(.title2)
                        .padding(10)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }

                Button(action: zoomIn) {
                    Image(systemName: "plus.magnifyingglass")
                        .font(.title2)
                        .padding(10)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }
            }
            .padding(.top, -20)

            if !recentLocations.isEmpty {
                VStack(alignment: .leading, spacing: 15) {
                    Text("Recent Locations")
                        .font(.title3).bold()
                        .padding(.leading)

                    ForEach(Array(recentLocations.prefix(3).enumerated()), id: \.offset) { index, location in
                        let coords = location["coordinate"] as? [Double] ?? []
                        TimelineItem(
                            icon: location["isSafeZone"] as? Bool == true ? "checkmark.shield" : "exclamationmark.triangle",
                            color: location["isSafeZone"] as? Bool == true ? .green : .red,
                            title: location["zoneName"] as? String ?? "Unknown",
                            time: formattedDate(location["timestamp"]),
                            isSafeZone: location["isSafeZone"] as? Bool
                        )

                        .onTapGesture {
                            if coords.count == 2 {
                                selectedLocation = CLLocationCoordinate2D(latitude: coords[0], longitude: coords[1])
                                selectedLocationName = location["zoneName"] as? String ?? "Unknown"
                                showLocationDetail = true
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top, 10)
            }

            Spacer()
        }
        .background(Color("BgColor").edgesIgnoringSafeArea(.all))
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showLocationDetail) {
            if let coord = selectedLocation, let name = selectedLocationName {
                LocationDetailView(coordinate: coord, locationName: name)
            }
        }
    }

    func fetchLatestLocation() {
        guard let guardianID = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        db.collection("guardians")
            .document(guardianID)
            .collection("children")
            .document(child.id)
            .collection("liveLocation")
            .order(by: "timestamp", descending: true)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("\u{274C} Error fetching location: \(error.localizedDescription)")
                    return
                }

                guard let doc = snapshot?.documents.first,
                      let coords = doc["coordinate"] as? [Double], coords.count == 2 else { return }

                let location = CLLocationCoordinate2D(latitude: coords[0], longitude: coords[1])
                self.latestCoordinate = location
                self.region.center = location
            }
    }

    func fetchRecentLocationHistory() {
        guard let guardianID = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        db.collection("guardians")
            .document(guardianID)
            .collection("children")
            .document(child.id)
            .collection("locationHistory")
            .order(by: "timestamp", descending: true)
            .limit(to: 3)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("\u{274C} Error fetching history: \(error.localizedDescription)")
                    return
                }

                self.recentLocations = snapshot?.documents.map { $0.data() } ?? []
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

struct TimelineItem: View {
    var icon: String
    var color: Color
    var title: String
    var time: String
    var number: String? = nil
    var isSafeZone: Bool? = nil

    var body: some View {
        HStack {
            VStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                Rectangle()
                    .frame(width: 2, height: 40)
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(isSafeZone == true ? .green : .red) 

                Text(time)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            Spacer()

            if let number = number {
                Text(number)
                    .font(.headline)
                    .foregroundColor(.orange)
                    .padding(8)
                    .background(Color.white)
                    .cornerRadius(15)
                    .shadow(radius: 2)
            }

            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
    }
}


#Preview {
    ContentView()
    
}
