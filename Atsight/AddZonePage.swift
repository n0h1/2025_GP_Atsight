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

//MARK: Setup:
// Setting up the user's coordinates to be in Riyadh by default
extension CLLocationCoordinate2D {
    static var userLocation: CLLocationCoordinate2D {
        return .init(latitude: 24.7136, longitude: 46.6753)
    }
}

// Setting up the zoom around the user's location
extension MKCoordinateRegion {
    static var userRegion: MKCoordinateRegion {
        return .init(center: .userLocation, latitudinalMeters: 5000, longitudinalMeters: 5000)
    }
}

//MARK: Zone struct:
// Zone struct: Defines the data structure for a geographical zone.
struct Zone: Identifiable {
    let id = UUID()
    var coordinate: CLLocationCoordinate2D
    var zoneName: String
    var isSafeZone: Bool
    var zoneSize: Double // This is the radius in meters
}

//MARK: Variables:
struct AddZonePage: View {
    @Environment(\.presentationMode) var presentationMode
    
    // Binding to the child's zones array
    @Binding var zones: [Zone]
    
    // Define the camera's position
    @State private var cameraPosition = MKCoordinateRegion.userRegion
    
    //temporary zone values that the user can adjust before saving the zone
    @State private var tempZoneCoordinates = CLLocationCoordinate2D.userLocation
    @State private var tempZoneSize: Double = 50 // Default radius in meters
    @State private var tempIsSafeZone = true
    @State private var tempZoneName = ""
    
    // Conversion factor - explicitly defining meters per unit
    let metersPerUnit: Double = 1.0 // 1 unit = 1 meter for radius
    
    // Navigation bar offset values - adjust these as needed
    let navigationBarYOffset: CGFloat = 140.0  // Vertical offset to compensate for navigation bar
    
    // Create a temporary zone for display
    var tempZone: Zone {
        return Zone(coordinate: tempZoneCoordinates, zoneName: "Your Location", isSafeZone: tempIsSafeZone, zoneSize: tempZoneSize)
    }
    
    // Calculate actual radius and diameter in meters
    var radiusInMeters: Double {
        return tempZoneSize * metersPerUnit
    }
    
    var diameterInMeters: Double {
        return radiusInMeters * 2
    }
    
    //MARK: Main View:
    var body: some View {
        return ZStack {
            // Show both the saved zones and the temporary zone
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
            // Convert the tap location to map coordinates wherever the user presses:
            .onTapGesture { location in
                let coordinate = convertToCoordinate(location: location)
                tempZoneCoordinates = coordinate
            }
            .ignoresSafeArea()
            
            // Zoom buttons positioned above the overlay
            VStack {
                Spacer()
                
                // Zoom control buttons
                HStack {
                    Spacer()
                    
                    VStack(spacing: 10) {
                        // Zoom in button
                        Button(action: {
                            zoomIn()
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.black)
                                .background(Color.white.opacity(0.8))
                                .clipShape(Circle())
                                .shadow(radius: 3)
                        }
                        
                        // Zoom out button
                        Button(action: {
                            zoomOut()
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.black)
                                .background(Color.white.opacity(0.8))
                                .clipShape(Circle())
                                .shadow(radius: 3)
                        }
                    }
                    .padding(.trailing, 20)
                }
                .padding(.bottom, 20)
                
                // Zone name textfield, safe and unsafe buttons, and the zone size's slider area.
                VStack {
                    Spacer()
                    Color.clear
                        .frame(height: UIScreen.main.bounds.height / 3) // Made taller to accommodate new info
                        .cornerRadius(20)
                        .shadow(radius: 10)
                        .overlay(
                            VStack {
                                //zone name text field
                                TextField("Enter your zone's name", text: $tempZoneName)
                                    .textFieldStyle(.plain).padding().border(Color("Buttons"), width: 1).background(Color.white)
                                    .cornerRadius(50)
                                    .padding(.top)
                                    .padding(.horizontal)
                                    .padding(.bottom)
                                
                                // Safe and Unsafe buttons:
                                HStack {
                                    Button {
                                        tempIsSafeZone = true
                                    } label: {
                                        Text("Safe").fontWeight(.bold)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(tempIsSafeZone ? Color.green : Color.gray.opacity(0.3))
                                            .foregroundColor(tempIsSafeZone ? .white : .black)
                                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    }
                                    .padding([.leading, .bottom])
                                    
                                    Button {
                                        tempIsSafeZone = false
                                    } label: {
                                        Text("Unsafe").fontWeight(.bold)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(tempIsSafeZone ? Color.gray.opacity(0.3) : Color.red)
                                            .foregroundColor(tempIsSafeZone ? .black : .white)
                                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    }
                                    .padding([.trailing, .bottom])
                                } // end buttons' hstack
                                
                                // Slider to adjust zone size as needed:
                                Text("Zone size: \(Int(tempZoneSize))")
                                    .fontWeight(.semibold)
                                Slider(value: $tempZoneSize, in: 1...150)
                                    .accentColor(.black)
                                    .padding([.horizontal, .bottom], 30)
                                
                                // Display the geographical size for the user as a hint on how big the zone is
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("Hint: This zone equals \(Int(Double.pi * radiusInMeters * radiusInMeters)) sq. meters.").italic().font(.system(size: 14)).foregroundColor(.black)
                                    
                                }
                                .padding(.horizontal)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.white.opacity(0.7))
                                .cornerRadius(8)
                                .padding(.horizontal)
                                .padding(.bottom)
                                
                            } //end inner vstack
                            .background(Color.mint.opacity(0.25))
                            .border(Color.green)
                            .cornerRadius(10)
                            .padding()
                        ) //end overlay
                    
                    // add zone button:
                    Button {
                        addZone(coordinates: tempZoneCoordinates, size: tempZoneSize, isSafe: tempIsSafeZone, name: tempZoneName, zonesList: &zones)
                    } label: {
                        Text("Add").font(.title2).fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding()
                           
                    }
                    .background(Color("Blue"))
                    .cornerRadius(30)
                    .padding()
                  
                   
                    
                }//end vstack
            }//end VStack
        }//end zstack
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading:
                                Button(action: { //navigate back
            self.presentationMode.wrappedValue.dismiss()
        }) {
            //navigate back button styling:
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.black)
                        .font(.system(size: 20, weight: .bold))
                }
            }
        }
        )
        
        // add page title + "Show Zones" button:
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Add Zone")
                    .font(.system(size: 24, weight: .bold))
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: SavedZonesView(zones: $zones)) {
                    Text("Show Zones").fontWeight(.semibold).foregroundColor(.black).padding(7).background(Color("Buttons")).cornerRadius(10)
                }
            }
        } //end toolbar
    } //end body
    
    
    //MARK: Functions & Struct:
    //function to adjust the zone's circle size when zooming:
    func calculateZoneSize(_ zoneSize: Double) -> CGFloat {
        let metersPerPoint = cameraPosition.span.latitudeDelta * 111000
        let zoomFactor = CGFloat(metersPerPoint)
        let baseSize: CGFloat = CGFloat(zoneSize * 2)
        return baseSize / zoomFactor * 5000
    }
    
    //function to add the specified zone to the "zones" list:
    func addZone(coordinates: CLLocationCoordinate2D, size: Double, isSafe: Bool, name: String, zonesList: inout [Zone]) {
        let newZone = Zone(coordinate: coordinates, zoneName: name, isSafeZone: isSafe, zoneSize: size)
        zonesList.append(newZone)
        
        // Save to Firebase
        saveZoneToFirebase(zone: newZone)
    }

    //save zone to Firebase
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


    // Convert a tap location on screen to map coordinates with navigation bar offset
    func convertToCoordinate(location: CGPoint) -> CLLocationCoordinate2D {
        let mapSize = UIScreen.main.bounds.size
        
        // Apply the navigation bar offset to get the adjusted center point
        let adjustedYPosition = mapSize.height / 2 + navigationBarYOffset
        let centerPoint = CGPoint(x: mapSize.width / 2, y: adjustedYPosition)
        
        // Calculate the difference between tap location and adjusted center
        let xDelta = (location.x - centerPoint.x) / mapSize.width
        let yDelta = (location.y - centerPoint.y) / mapSize.height
        
        // Convert the screen deltas to coordinate deltas
        let latitudeDelta = cameraPosition.span.latitudeDelta * Double(-yDelta)
        let longitudeDelta = cameraPosition.span.longitudeDelta * Double(xDelta)
        
        // Apply the deltas to the center coordinate
        let newLatitude = cameraPosition.center.latitude + latitudeDelta
        let newLongitude = cameraPosition.center.longitude + longitudeDelta
        
        return CLLocationCoordinate2D(latitude: newLatitude, longitude: newLongitude)
    }
    
    // Function to zoom in the map
    func zoomIn() {
        var region = cameraPosition
        region.span.latitudeDelta /= 2.0
        region.span.longitudeDelta /= 2.0
        cameraPosition = region
    }
    
    // Function to zoom out the map
    func zoomOut() {
        var region = cameraPosition
        region.span.latitudeDelta *= 2.0
        region.span.longitudeDelta *= 2.0
        cameraPosition = region
    }
} // end AddZonePage struct

struct AddZonePage_Previews: PreviewProvider {
    static var previews: some View {
        // Create a sample empty zones array for the preview
        AddZonePage(zones: .constant([]))
    }
}
