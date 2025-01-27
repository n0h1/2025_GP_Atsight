import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

struct NotificationItem: Identifiable {
    var id: String
    var title: String
    var body: String
    var timestamp: Timestamp
    var isSafeZone: Bool
}

struct NotificationSettingsView: View {
    @State private var notifications: [NotificationItem] = []
    @State private var isLoading = true

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    if isLoading {
                        ProgressView("Loading...")
                            .padding(.top, 50)
                            .foregroundColor(Color("BlackFont"))
                    } else if notifications.isEmpty {
                        Text("No notifications available.")
                            .foregroundColor(Color("ColorGray"))
                            .padding(.top, 50)
                    } else {
                        ForEach(notifications) { notification in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "bell.fill")
                                    .foregroundColor(Color("BlackFont"))
                                    .padding(.top, 6)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(notification.title)
                                        .font(.headline)
                                        .foregroundColor(Color("BlackFont"))

                                    Text(notification.body)
                                        .font(.subheadline)
                                        .foregroundColor(Color("ColorGray"))
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                Spacer()

                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(notification.isSafeZone ? Color("ColorGreen") : Color("ColorRed"), lineWidth: 2)
                                        .frame(width: 34, height: 34)

                                    Image(systemName: notification.isSafeZone ? "checkmark.shield" : "exclamationmark.triangle")
                                        .foregroundColor(notification.isSafeZone ? Color("ColorGreen") : Color("ColorRed"))
                                        .font(.system(size: 18))
                                }
                            }
                            .padding()
                            .background(
                                notification.isSafeZone ? Color("BgColor") : Color("ColorRed").opacity(0.1) // ✅ خلفية حمراء خفيفة لو Unsafe
                            )
                            .cornerRadius(20)
                            .overlay(
                                notification.isSafeZone ? nil :
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color("ColorRed"), lineWidth: 1.5) // ✅ حدود حمراء خفيفة للكرت إذا Unsafe
                            )
                            .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 4) // ✅ شادو خفيف
                            .padding(.horizontal, 16)
                        }
                    }
                }
                .padding(.top)
                .frame(maxWidth: .infinity)
            }
            .background(Color("BgColor").ignoresSafeArea())
            .navigationTitle("Customize Notifications")
            .navigationBarTitleDisplayMode(.large) // ✅ رجعناها Large مثل الكود القديم
            .foregroundColor(Color("BlackFont"))
        }
        .onAppear(perform: fetchNotifications)
    }

    func fetchNotifications() {
        guard let guardianID = Auth.auth().currentUser?.uid else {
            print("User not logged in")
            return
        }

        let db = Firestore.firestore()
        db.collection("guardians")
            .document(guardianID)
            .collection("notifications")
            .order(by: "timestamp", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching notifications: \(error.localizedDescription)")
                    self.isLoading = false
                } else {
                    self.notifications = snapshot?.documents.compactMap { doc in
                        let data = doc.data()
                        return NotificationItem(
                            id: doc.documentID,
                            title: data["title"] as? String ?? "Untitled",
                            body: data["body"] as? String ?? "",
                            timestamp: data["timestamp"] as? Timestamp ?? Timestamp(date: Date()),
                            isSafeZone: data["isSafeZone"] as? Bool ?? false
                        )
                    } ?? []
                    self.isLoading = false
                }
            }
    }
}

#Preview {
    NotificationSettingsView()
}
