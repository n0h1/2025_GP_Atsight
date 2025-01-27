import FirebaseFirestore

func saveChildToFirestore(guardianID: String, child: Child, completion: @escaping (Result<Void, Error>) -> Void) {
    let db = Firestore.firestore()

    let childRef = db.collection("guardians")
        .document(guardianID)
        .collection("children")
        .document(child.id)

    var childData: [String: Any] = [
        "name": child.name,
        "color": child.color
    ]

    if let imageName = child.imageName {
        childData["imageName"] = imageName
    }

    print("🚀 Starting to create child...")

    childRef.setData(childData) { error in
        if let error = error {
            print("❌ Error adding child: \(error.localizedDescription)")
            completion(.failure(error))
        } else {
            print("✅ Step 1: Child added successfully.")

            let timestamp = Timestamp(date: Date())

            let updatedEntry: [String: Any] = [
                "coordinate": [0.0, 0.0],
                "timestamp": timestamp,
                "zoneName": "Initial",
                "isSafeZone": true
            ]

            let collections = ["liveLocation", "locationHistory", "safeZone", "unSafeZone"]
            let group = DispatchGroup()
            var encounteredError: Error? = nil

            for collection in collections {
                group.enter()
                let collectionRef = childRef.collection(collection).document("init")
                collectionRef.setData(updatedEntry) { error in
                    if let error = error {
                        print("❌ Error creating \(collection): \(error.localizedDescription)")
                        encounteredError = error
                    } else {
                        print("✅ \(collection) created with updated entry.")
                    }
                    group.leave()
                }
            }

            // ✅ إشعار يحتوي على isSafeZone
            group.enter()
            let notificationRef = db.collection("guardians")
                .document(guardianID)
                .collection("notifications")
                .document()

            let notificationData: [String: Any] = [
                "title": "New Child Added",
                "body": "Child \(child.name) was added successfully.",
                "timestamp": timestamp,
                "isSafeZone": true // ✅ هذا هو السطر الجديد
            ]

            notificationRef.setData(notificationData) { error in
                if let error = error {
                    print("❌ Error creating notification: \(error.localizedDescription)")
                    encounteredError = error
                } else {
                    print("✅ Notification created.")
                }
                group.leave()
            }

            group.notify(queue: .main) {
                if let error = encounteredError {
                    completion(.failure(error))
                } else {
                    print("✅ All collections created successfully.")
                    completion(.success(()))
                }
            }
        }
    }
}
