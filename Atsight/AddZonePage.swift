//
//  AddZonePage.swift
//  Atsight
//
//  Created by Najd Alsabi on 21/04/2025.
//

import SwiftUI
import MapKit
import FirebaseFirestore
import FirebaseAuth

extension CLLocationCoordinate2D {
    static var userLocation: CLLocationCoordinate2D {
        return .init(latitude: 24.7136, longitude: 46.6753)
    }
}

extension MKCoordinateRegion {
    static var userRegion: MKCoordinateRegion {
        return .init(center: .userLocation, latitudinalMeters: 5000, longitudinalMeters: 5000)
    }
}

struct Zone: Identifiable {
    let id = UUID()
    var coordinate: CLLocationCoordinate2D
    var zoneName: String
    var isSafeZone: Bool
    var zoneSize: Double
}

struct AddZonePage: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var zones: [Zone]

    @State private var cameraPosition = MKCoordinateRegion.userRegion
    @State private var tempZoneCoordinates = CLLocationCoordinate2D.userLocation
    @State private var tempZoneSize: Double = 50
    @State private var tempIsSafeZone = true
    @State private var tempZoneName = ""

    let metersPerUnit: Double = 1.0

    var tempZone: Zone {
        Zone(coordinate: tempZoneCoordinates, zoneName: "Your Location", isSafeZone: tempIsSafeZone, zoneSize: tempZoneSize)
    }

    var body: some View {
        ZStack {
            Map(coordinateRegion: $cameraPosition,
                interactionModes: [.all],
                annotationItems: zones + [tempZone]) { zone in
                MapAnnotation(coordinate: zone.coordinate) {
                    ZStack {
                        Circle()
                            .fill(zone.isSafeZone ? Color.green.opacity(0.3) : Color.red.opacity(0.3))
                            .frame(width: calculateZoneSize(zone.zoneSize), height: calculateZoneSize(zone.zoneSize))
                        Image(systemName: "mappin")
                            .foregroundColor(zone.id == tempZone.id ? .red : .black)
                            .font(.title)
                    }
                }
            }
            .overlay(
                GeometryReader { geo in
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onEnded { value in
                                    let coordinate = convertToCoordinate(location: value.location)
                                    tempZoneCoordinates = coordinate
                                }
                        )
                }
            )
            .ignoresSafeArea()

            // UI content...
            VStack {
                Spacer()

                // Zoom controls
                HStack {
                    Spacer()
                    VStack(spacing: 10) {
                        Button(action: zoomIn) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(Color("BlackFont"))
                                .background(Color.white.opacity(0.8))
                                .clipShape(Circle())
                                .shadow(radius: 3)
                        }
                        Button(action: zoomOut) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(Color("BlackFont"))
                                .background(Color.white.opacity(0.8))
                                .clipShape(Circle())
                                .shadow(radius: 3)
                        }
                    }
                    .padding(.trailing, 20)
                }
                .padding(.bottom, 20)

                VStack {
                    Spacer()
                    Color.clear
                        .frame(height: UIScreen.main.bounds.height / 3)
                        .overlay(
                            VStack {
                                TextField("Enter your zone's name", text: $tempZoneName)
                                    .padding(10)
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    .padding()

                                HStack {
                                    Button {
                                        tempIsSafeZone = true
                                    } label: {
                                        Text("Safe").fontWeight(.bold)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(tempIsSafeZone ? Color.green : Color.gray.opacity(0.3))
                                            .foregroundColor(tempIsSafeZone ? .white : .black)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }

                                    Button {
                                        tempIsSafeZone = false
                                    } label: {
                                        Text("Unsafe").fontWeight(.bold)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(tempIsSafeZone ? Color.gray.opacity(0.3) : Color.red)
                                            .foregroundColor(tempIsSafeZone ? .black : .white)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
                                }
                                .padding([.horizontal, .bottom])

                                Text("Zone size: \(Int(tempZoneSize))")
                                    .fontWeight(.semibold)
                                Slider(value: $tempZoneSize, in: 1...150)
                                    .accentColor(.black)
                                    .padding(.horizontal)

                                VStack(alignment: .leading, spacing: 5) {
                                    Text("Hint:").italic()
                                    Text("This zone equals \(Int(Double.pi * tempZoneSize * tempZoneSize)) sq. meters.").italic()
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.white.opacity(0.7))
                                .cornerRadius(8)
                            }
                            .background(Color.mint.opacity(0.25))
                            .border(Color.green)
                            .cornerRadius(10)
                            .padding()
                        )

                    Button {
                        addZone(coordinates: tempZoneCoordinates, size: tempZoneSize, isSafe: tempIsSafeZone, name: tempZoneName, zonesList: &zones)
                    } label: {
                        Text("Add").fontWeight(.bold)
                    }
                    .frame(width: 100, height: 50)
                    .background(Color.mint)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding()
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading:
            Button(action: {
                self.presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(Color("BlackFont"))
                    .font(.system(size: 20, weight: .bold))
            }
        )
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Setup Zone").font(.system(size: 24, weight: .bold))
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: SavedZonesView(zones: $zones)) {
                    Text("zone list")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(7)
                        .background(Color.mint)
                        .cornerRadius(10)
                }
            }
        }
    }

    // MARK: - Functions

    func calculateZoneSize(_ zoneSize: Double) -> CGFloat {
        let metersPerPoint = cameraPosition.span.latitudeDelta * 111000
        return CGFloat(zoneSize * 2) / CGFloat(metersPerPoint) * 5000
    }

    func addZone(coordinates: CLLocationCoordinate2D, size: Double, isSafe: Bool, name: String, zonesList: inout [Zone]) {
        let newZone = Zone(coordinate: coordinates, zoneName: name, isSafeZone: isSafe, zoneSize: size)
        zonesList.append(newZone)
        saveZoneToFirebase(zone: newZone)
    }

    func saveZoneToFirebase(zone: Zone) {
        let db = Firestore.firestore()
        guard let guardianID = Auth.auth().currentUser?.uid else { return }

        let childrenRef = db.collection("guardians").document(guardianID).collection("children")
        childrenRef.limit(to: 1).getDocuments { snapshot, error in
            guard let document = snapshot?.documents.first else { return }
            let childID = document.documentID
            let collection = zone.isSafeZone ? "safeZone" : "unSafeZone"

            db.collection("guardians").document(guardianID)
                .collection("children").document(childID)
                .collection(collection).addDocument(data: [
                    "coordinate": GeoPoint(latitude: zone.coordinate.latitude, longitude: zone.coordinate.longitude),
                    "zoneName": zone.zoneName,
                    "isSafeZone": zone.isSafeZone,
                    "zoneSize": zone.zoneSize
                ])
        }
    }

    func convertToCoordinate(location: CGPoint) -> CLLocationCoordinate2D {
        let screenSize = UIScreen.main.bounds.size

        let latDelta = cameraPosition.span.latitudeDelta
        let lonDelta = cameraPosition.span.longitudeDelta

        let latPerPoint = latDelta / screenSize.height
        let lonPerPoint = lonDelta / screenSize.width

        let dx = location.x - screenSize.width / 2
        let dy = location.y - screenSize.height / 2

        let newLat = cameraPosition.center.latitude - (dy * latPerPoint)
        let newLon = cameraPosition.center.longitude + (dx * lonPerPoint)

        return CLLocationCoordinate2D(latitude: newLat, longitude: newLon)
    }

    func zoomIn() {
        cameraPosition.span.latitudeDelta /= 2.0
        cameraPosition.span.longitudeDelta /= 2.0
    }

    func zoomOut() {
        cameraPosition.span.latitudeDelta *= 2.0
        cameraPosition.span.longitudeDelta *= 2.0
    }
}

struct AddZonePage_Previews: PreviewProvider {
    static var previews: some View {
        AddZonePage(zones: .constant([]))
    }
}
