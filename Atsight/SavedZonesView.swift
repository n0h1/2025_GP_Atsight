//
//  SavedZonesView.swift
//  Atsight
//
//  Created by Najd Alsabi on 21/04/2025.
//

import SwiftUI
import MapKit
import Firebase
import FirebaseFirestore
import FirebaseAuth

// MARK: Variables:
struct SavedZonesView: View {
    @Environment(\.presentationMode) var presentationMode
    
    // Using a binding to the parent's zones array
    @Binding var zones: [Zone]
    
    @State private var editingZoneId: UUID? = nil
    @State private var editingZoneName: String = ""
    @State private var isProcessing = false // To show loading indicator
    
    //MARK: Main View:
    var body: some View {
        //iterate through zones list and display the added zones:
        List {
            ForEach(zones) { zone in
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Image(systemName: "mappin").resizable().scaledToFill().frame(width: 10, height: 10).padding(.trailing, 10)
                        
                        VStack(alignment: .leading) {
                            if editingZoneId == zone.id {
                                TextField("Zone name", text: $editingZoneName, onCommit: {
                                    saveZoneName()
                                })
                                .font(.title2)
                            } else {
                                Text("\(zone.zoneName)").font(.title2).fontWeight(.semibold)
                            }
                            Text(" \(zone.coordinate.latitude), \(zone.coordinate.longitude)").foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Text("\(zone.isSafeZone ? "Safe" : "Unsafe")")
                            .fontWeight(.bold)
                            .foregroundColor(.white).padding(5)
                            .background(Color(zone.isSafeZone ? .green : .red))
                            .cornerRadius(10)
                    }
                    
                    HStack(alignment: .center, spacing: 10) {
                        //edit zone name button
                        Button {
                            startEditing(zone: zone)
                        } label: {
                            HStack {
                                Image(systemName: "pencil").resizable().scaledToFill().frame(width: 20, height: 20).padding(.trailing, 10)
                                Text("Edit").fontWeight(.semibold)
                            }.padding()
                        }
                        .frame(maxWidth: .infinity, maxHeight: 40)
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .contentShape(Rectangle())
                        .disabled(isProcessing)
                        .onTapGesture {
                            startEditing(zone: zone)
                        }
                        
                        //delete zone button
                        Button {
                            deleteZone(zoneToDelete: zone)
                        } label: {
                            HStack {
                                if isProcessing && editingZoneId == zone.id {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .frame(width: 20, height: 20)
                                        .padding(.trailing, 10)
                                } else {
                                    Image(systemName: "trash").resizable().scaledToFill().frame(width: 20, height: 20).padding(.trailing, 10)
                                }
                                Text("Delete").fontWeight(.semibold)
                            }.padding()
                        }
                        .frame(maxWidth: .infinity, maxHeight: 40)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .contentShape(Rectangle())
                        .disabled(isProcessing)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 5)
                }
                .padding(.vertical)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading:
            Button(action: {
                self.presentationMode.wrappedValue.dismiss()
            }) {
                HStack {
                    Image(systemName: "chevron.left")
                        .foregroundColor(Color("BlackFont"))
                        .font(.system(size: 20, weight: .bold))
                }
            }
        )
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Saved Zones")
                    .font(.system(size: 24, weight: .bold))
            }
        }
        .overlay(
            Group {
                if isProcessing {
                    Color.black.opacity(0.2)
                        .edgesIgnoringSafeArea(.all)
                        .overlay(
                            ProgressView("Processing...")
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                        )
                }
            }
        )
        .onAppear {
            fetchZones()
        }
    }
    
    //MARK: Firebase Fetch Zones
    func fetchZones() {
        guard let guardianID = Auth.auth().currentUser?.uid else {
            print("❌ No authenticated user.")
            return
        }

        let db = Firestore.firestore()
        let childrenRef = db.collection("guardians").document(guardianID).collection("children")

        childrenRef.limit(to: 1).getDocuments { snapshot, error in
            if let error = error {
                print("❌ Error fetching children: \(error)")
                return
            }

            guard let childDoc = snapshot?.documents.first else {
                print("❌ No child found.")
                return
            }

            let childID = childDoc.documentID
            let childRef = db.collection("guardians").document(guardianID).collection("children").document(childID)

            let group = DispatchGroup()
            var fetchedZones: [Zone] = []

            for collection in ["safeZone", "unSafeZone"] {
                group.enter()
                childRef.collection(collection).getDocuments { snapshot, error in
                    if let error = error {
                        print("❌ Error fetching \(collection): \(error)")
                    } else if let documents = snapshot?.documents {
                        for doc in documents {
                            let data = doc.data()
                            if let geo = data["coordinate"] as? GeoPoint,
                               let name = data["zoneName"] as? String,
                               let isSafe = data["isSafeZone"] as? Bool,
                               let size = data["zoneSize"] as? Double {
                                let zone = Zone(
                                    coordinate: CLLocationCoordinate2D(latitude: geo.latitude, longitude: geo.longitude),
                                    zoneName: name,
                                    isSafeZone: isSafe,
                                    zoneSize: size
                                )
                                fetchedZones.append(zone)
                            }
                        }
                    }
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                self.zones = fetchedZones
            }
        }
    }

    func deleteZone(zoneToDelete: Zone) {
        guard !isProcessing else { return }
        isProcessing = true
        editingZoneId = zoneToDelete.id
        
        guard let guardianID = Auth.auth().currentUser?.uid else {
            isProcessing = false
            return
        }
        
        let db = Firestore.firestore()
        let childrenRef = db.collection("guardians").document(guardianID).collection("children")
        
        childrenRef.limit(to: 1).getDocuments { snapshot, error in
            if let error = error {
                print("❌ Error fetching children: \(error)")
                isProcessing = false
                return
            }
            
            guard let childDoc = snapshot?.documents.first else {
                print("❌ No child found.")
                isProcessing = false
                return
            }
            
            let childID = childDoc.documentID
            let collection = zoneToDelete.isSafeZone ? "safeZone" : "unSafeZone"
            let zonesRef = db.collection("guardians").document(guardianID)
                .collection("children").document(childID)
                .collection(collection)
            
            zonesRef.whereField("zoneName", isEqualTo: zoneToDelete.zoneName)
                .whereField("coordinate", isEqualTo: GeoPoint(latitude: zoneToDelete.coordinate.latitude, longitude: zoneToDelete.coordinate.longitude))
                .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error finding zone to delete: \(error.localizedDescription)")
                    isProcessing = false
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    print("❌ No matching zone document found")
                    DispatchQueue.main.async {
                        zones.removeAll { $0.id == zoneToDelete.id }
                        isProcessing = false
                    }
                    return
                }
                
                let dispatchGroup = DispatchGroup()
                for document in documents {
                    dispatchGroup.enter()
                    document.reference.delete { err in
                        if let err = err {
                            print("❌ Error removing zone document: \(err)")
                        } else {
                            print("✅ Zone document successfully removed!")
                        }
                        dispatchGroup.leave()
                    }
                }
                dispatchGroup.notify(queue: .main) {
                    zones.removeAll { $0.id == zoneToDelete.id }
                    isProcessing = false
                }
            }
        }
    }

    func startEditing(zone: Zone) {
        editingZoneId = zone.id
        editingZoneName = zone.zoneName
    }

    func saveZoneName() {
        guard !isProcessing, let id = editingZoneId else { return }
        isProcessing = true
        
        guard let index = zones.firstIndex(where: { $0.id == id }) else {
            isProcessing = false
            editingZoneId = nil
            return
        }

        let zone = zones[index]
        let oldZoneName = zone.zoneName
        let newZoneName = editingZoneName
        
        guard let guardianID = Auth.auth().currentUser?.uid else {
            isProcessing = false
            return
        }
        
        let db = Firestore.firestore()
        let childrenRef = db.collection("guardians").document(guardianID).collection("children")
        
        childrenRef.limit(to: 1).getDocuments { snapshot, error in
            if let error = error {
                print("❌ Error fetching child: \(error)")
                isProcessing = false
                return
            }
            
            guard let childDoc = snapshot?.documents.first else {
                print("❌ No child found.")
                isProcessing = false
                return
            }
            
            let childID = childDoc.documentID
            let collection = zone.isSafeZone ? "safeZone" : "unSafeZone"
            let zonesRef = db.collection("guardians").document(guardianID)
                .collection("children").document(childID)
                .collection(collection)
            
            zonesRef.whereField("zoneName", isEqualTo: oldZoneName)
                .whereField("coordinate", isEqualTo: GeoPoint(latitude: zone.coordinate.latitude, longitude: zone.coordinate.longitude))
                .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error finding zone: \(error.localizedDescription)")
                    isProcessing = false
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    print("❌ No matching zone document found")
                    DispatchQueue.main.async {
                        zones[index].zoneName = newZoneName
                        isProcessing = false
                        editingZoneId = nil
                    }
                    return
                }
                
                let dispatchGroup = DispatchGroup()
                for document in documents {
                    dispatchGroup.enter()
                    document.reference.updateData(["zoneName": newZoneName]) { err in
                        if let err = err {
                            print("❌ Error updating zone name: \(err)")
                        } else {
                            print("✅ Zone name successfully updated!")
                        }
                        dispatchGroup.leave()
                    }
                }
                dispatchGroup.notify(queue: .main) {
                    zones[index].zoneName = newZoneName
                    isProcessing = false
                    editingZoneId = nil
                }
            }
        }
    }
}

// Preview provider
struct SavedZonesView_Previews: PreviewProvider {
    @State static var previewZones: [Zone] = [
        Zone(coordinate: CLLocationCoordinate2D(latitude: 24.7136, longitude: 46.6753),
             zoneName: "Sample Zone", isSafeZone: true, zoneSize: 100)
    ]
    
    static var previews: some View {
        SavedZonesView(zones: .constant(previewZones))
    }
}
