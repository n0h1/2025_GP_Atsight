//
//  CustomizeNotifications.swift
//  Atsight
//
//  Created by Najd Alsabi on 21/04/2025.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import AVFoundation

// MARK: - Sound Player
class SoundPlayer {
    static let shared = SoundPlayer()
    private var audioPlayer: AVAudioPlayer?

    func playSound(named soundName: String) {
        guard let url = Bundle.main.url(forResource: soundName, withExtension: "wav") else {
            print("Sound file not found")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("Failed to play sound: \(error)")
        }
    }
}

// MARK: - Notification Sound Options
enum NotificationSound: String, CaseIterable, Identifiable {
    case defaultSound = "Default"
    case alert = "Alert"
    case bell = "Bell"
    case chime = "Chime"
    case chirp = "Chirp"

    var id: String { self.rawValue }

    var filename: String {
        switch self {
        case .defaultSound: return "default_sound"
        case .alert: return "alert_sound"
        case .bell: return "bell_sound"
        case .chime: return "chime_sound"
        case .chirp: return "chirp_sound"
        }
    }

    static func fromString(_ string: String) -> NotificationSound {
        return NotificationSound.allCases.first { $0.filename == string } ?? .defaultSound
    }
}

// MARK: NotificationSettings Struct:
struct NotificationSettings: Codable, Equatable {
    var safeZoneAlert: Bool = true
    var unsafeZoneAlert: Bool = true
    var lowBatteryAlert: Bool = true
    var watchRemovedAlert: Bool = true
    var newAuthorAccount: Bool = true
    var sound: String = "default_sound"
}

// MARK: Variables:
struct CustomizeNotifications: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var child: Child

    @State private var safeZoneAlert: Bool
    @State private var unsafeZoneAlert: Bool
    @State private var lowBatteryAlert: Bool
    @State private var watchRemovedAlert: Bool
    @State private var newAuthorAccount: Bool

    @State private var showSoundPicker = false
    @State private var selectedSound: NotificationSound

    @State private var isLoading = false

    init(child: Binding<Child>) {
        self._child = child
        let settings = child.wrappedValue.notificationSettings

        _safeZoneAlert = State(initialValue: settings.safeZoneAlert)
        _unsafeZoneAlert = State(initialValue: settings.unsafeZoneAlert)
        _lowBatteryAlert = State(initialValue: settings.lowBatteryAlert)
        _watchRemovedAlert = State(initialValue: settings.watchRemovedAlert)
        _newAuthorAccount = State(initialValue: settings.newAuthorAccount)
        _selectedSound = State(initialValue: NotificationSound.fromString(settings.sound))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Customize Notifications")
                    .font(.system(size: 28, weight: .bold))
                    .padding(.bottom, 8)

                notificationCard(
                    title: "Safe Zone Alert",
                    subtitle: "Alert in case child out of safe zone",
                    isOn: $safeZoneAlert
                ) {
                    child.notificationSettings.safeZoneAlert = $0
                }

                notificationCard(
                    title: "Unsafe Zone Alert",
                    subtitle: "Alert in case child near unsafe zone",
                    isOn: $unsafeZoneAlert
                ) {
                    child.notificationSettings.unsafeZoneAlert = $0
                }

                notificationCard(
                    title: "Battery Low",
                    subtitle: "Alert if watch is low battery",
                    isOn: $lowBatteryAlert
                ) {
                    child.notificationSettings.lowBatteryAlert = $0
                }

                notificationCard(
                    title: "Movement",
                    subtitle: "Alert for each movement",
                    isOn: .constant(false)
                ) { _ in }

                notificationCard(
                    title: "Watch Removed or Alert",
                    subtitle: "Alert if child removed the watch",
                    isOn: $watchRemovedAlert
                ) {
                    child.notificationSettings.watchRemovedAlert = $0
                }

                notificationCard(
                    title: "New Author Account",
                    subtitle: "Alert if child profile has been accessed",
                    isOn: $newAuthorAccount
                ) {
                    child.notificationSettings.newAuthorAccount = $0
                }

                notificationCard(
                    title: "Notification Sound",
                    subtitle: "Choose sound for all notifications",
                    rightView: AnyView(
                        Button(action: {
                            showSoundPicker = true
                        }) {
                            HStack {
                                Text(selectedSound.rawValue)
                                    .foregroundColor(.primary)
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                    )
                )

                if isLoading {
                    ProgressView("Updating settings...")
                        .padding()
                }

                Spacer(minLength: 40)
            }
            .padding()
        }
        .background(Color("BgColor").ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(
            leading: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(Color("BlackFont"))
                    .font(.system(size: 20, weight: .bold))
            },
            trailing: Button(action: {
                saveAllNotificationSettings()
            }) {
                Text("Done")
                    .foregroundColor(.blue)
                    .fontWeight(.bold)
            }
        )
        .sheet(isPresented: $showSoundPicker) {
            NotificationSoundPicker(selectedSound: $selectedSound, onSoundSelected: { sound in
                child.notificationSettings.sound = sound.filename
            })
        }
    }

    private func saveAllNotificationSettings() {
        isLoading = true
        let db = Firestore.firestore()
        let guardianID = "test-guardian-123"
        let childDocID = "4QU8xb7VN5CHAKLVnwDq"
        let notificationDocID = "BaOwvWw8CoR9WdErQRXG"

        let notificationDocRef = db.collection("guardians").document(guardianID)
            .collection("children").document(childDocID)
            .collection("notifications").document(notificationDocID)

        let notificationSettings: [String: Any] = [
            "safeZoneAlert": safeZoneAlert,
            "unsafeZoneAlert": unsafeZoneAlert,
            "lowBatteryAlert": lowBatteryAlert,
            "watchRemovedAlert": watchRemovedAlert,
            "newAuthorAccount": newAuthorAccount,
            "sound": selectedSound.filename
        ]

        child.notificationSettings = NotificationSettings(
            safeZoneAlert: safeZoneAlert,
            unsafeZoneAlert: unsafeZoneAlert,
            lowBatteryAlert: lowBatteryAlert,
            watchRemovedAlert: watchRemovedAlert,
            newAuthorAccount: newAuthorAccount,
            sound: selectedSound.filename
        )

        notificationDocRef.setData(notificationSettings, merge: true) { error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    print("❌ Error updating notification settings: \(error.localizedDescription)")
                } else {
                    print("✅ Successfully updated all notification settings")
                    self.presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }

    // MARK: - Notification Card View Builder
    @ViewBuilder
    private func notificationCard(
        title: String,
        subtitle: String,
        isOn: Binding<Bool>? = nil,
        rightView: AnyView? = nil,
        onToggle: ((Bool) -> Void)? = nil
    ) -> some View {
        HStack {
            Image(systemName: "bell")
                .foregroundColor(Color("BlackFont"))
                .font(.system(size: 18))
                .padding(.leading, 10)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color("BlackFont"))
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            Spacer()

            if let toggleBinding = isOn {
                Toggle("", isOn: toggleBinding)
                    .labelsHidden()
                    .onChange(of: toggleBinding.wrappedValue) { newVal in
                        onToggle?(newVal)
                    }
            } else if let right = rightView {
                right
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Sound Picker
struct NotificationSoundPicker: View {
    @Binding var selectedSound: NotificationSound
    var onSoundSelected: (NotificationSound) -> Void
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            List {
                ForEach(NotificationSound.allCases) { sound in
                    HStack {
                        Text(sound.rawValue)
                        Spacer()
                        if selectedSound == sound {
                            Image(systemName: "checkmark")
                                .foregroundColor(.mint)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedSound = sound
                        SoundPlayer.shared.playSound(named: sound.filename)
                        onSoundSelected(sound)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Select Sound")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
