//  EditChildProfile.swift
//  Atsight

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseStorage

struct EditChildProfile: View {
    @Environment(\.dismiss) var dismiss
    var guardianID: String
    @Binding var child: Child

    @Environment(\.presentationMode) var presentationMode
    @State private var showingColorPicker = false
    @State private var isSaving = false
    @State private var showSuccessMessage = false
    @State private var showErrorAlert = false
    @State private var errorMessage: String?
    @State private var goToLocationHistory = false
    @State private var isAvatarSelectionVisible = false

    let colors: [Color] = [.red, .green, .blue, .yellow, .orange, .purple, .pink, .brown, .gray]
    let animalIcons = ["penguin", "giraffe", "butterfly", "fox", "deer", "tiger", "whale", "turtle", "owl", "elephant", "frog", "hamster"]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                profileImageSection
                nameField
                colorPickerSection
                navigationLinksSection
                saveButton
            }
            .padding()
            .foregroundColor(Color("BlackFont"))
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: backButton)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Child Profile")
                    .font(.headline)
            }
        }
        .overlay(
            Group {
                if showSuccessMessage {
                    Text("Changes Saved!")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green.opacity(0.8))
                        .cornerRadius(10)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.3), value: showSuccessMessage)
                }
            }
        )
        .alert(isPresented: $showErrorAlert) {
            Alert(
                title: Text("Error Saving Profile"),
                message: Text(errorMessage ?? "An unknown error occurred."),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    var displayedImage: Image {
        if let name = child.imageName, !name.isEmpty, animalIcons.contains(name) {
            return Image(name)
        } else {
            return Image(systemName: "figure.child")
        }
    }

    var profileImageSection: some View {
        VStack(alignment: .center, spacing: 8) {
            displayedImage
                .resizable()
                .frame(width: 120, height: 120)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                .padding(10)
                .onTapGesture {
                    isAvatarSelectionVisible.toggle()
                }

            Text("Tap to change avatar")
                .font(.caption)
                .foregroundColor(.gray)

            if isAvatarSelectionVisible {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(animalIcons, id: \.self) { iconName in
                            Image(iconName)
                                .resizable()
                                .frame(width: 50, height: 50)
                                .background(Circle().fill(child.imageName == iconName ? Color.blue.opacity(0.2) : Color.clear)).padding(5)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(child.imageName == iconName ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2))
                                .onTapGesture {
                                    child.imageName = iconName
                                    isAvatarSelectionVisible = false
                                }
                        }
                    }
                    .padding(.top, 4)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    var nameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Name")
                .font(.caption)
                .foregroundColor(.gray)
            TextField("Enter name", text: $child.name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .disabled(isSaving)
        }
    }

    var colorPickerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Color")
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                Rectangle()
                    .fill(colorFromString(child.color).opacity(0.8))
                    .frame(width: 30, height: 30)
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.5)))
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if !isSaving {
                    withAnimation {
                        showingColorPicker.toggle()
                    }
                }
            }

            if showingColorPicker {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(colors, id: \.self) { color in
                            Circle()
                                .fill(color.opacity(0.8))
                                .frame(width: 36, height: 36)
                                .overlay(Circle().stroke(Color.white, lineWidth: 1))
                                .shadow(radius: 1)
                                .onTapGesture {
                                    child.color = colorToString(color)
                                    withAnimation {
                                        showingColorPicker = false
                                    }
                                }
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
        .opacity(isSaving ? 0.6 : 1.0)
        .disabled(isSaving)
    }

    var navigationLinksSection: some View {
        VStack(spacing: 10) {
            navigationBox(title: "Authorized People", systemImage: "person.2.fill", destination: AuthorizedPeople())
            navigationBox(title: "Customize", systemImage: "bell.badge", destination: CustomizeNotifications(child: $child))
        }
        .padding(.top)
        .opacity(isSaving ? 0.6 : 1.0)
    }

    var saveButton: some View {
        Button(action: {
            if !isSaving {
                updateChildProfile()
            }
        }) {
            Text(isSaving ? "Saving..." : "Save Changes")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color("Buttons").opacity(isSaving ? 0.4 : 0.8))
                .foregroundColor(Color("BlackFont"))
                .cornerRadius(12)
                .overlay(
                    Group {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        }
                    }
                )
        }
        .disabled(isSaving)
        .padding(.top, 120)
    }

    var backButton: some View {
        Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "chevron.left")
                .foregroundColor(Color("BlackFont"))
                .font(.system(size: 20, weight: .bold))
        }
        .disabled(isSaving)
    }

    func updateChildProfile() {
        isSaving = true
        let childID = child.id

        if let avatarName = child.imageName, !avatarName.isEmpty {
            saveToFirestore(childID: childID, avatarName: avatarName)
        } else {
            saveToFirestore(childID: childID, avatarName: nil)
        }
    }

    func saveToFirestore(childID: String, avatarName: String?) {
        let db = Firestore.firestore()
        let childRef = db.collection("guardians").document(guardianID).collection("children").document(childID)

        var data: [String: Any] = [
            "name": child.name,
            "color": colorToString(colorFromString(child.color))
        ]

        if let avatarName = avatarName {
            data["imageName"] = avatarName
        }

        childRef.updateData(data) { error in
            DispatchQueue.main.async {
                isSaving = false
                if let error = error {
                    print("❌ Error updating profile: \(error.localizedDescription)")
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                } else {
                    print("✅ Profile updated successfully.")
                    showSuccessMessage = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        showSuccessMessage = false
                    }
                }
            }
        }
    }

    func colorToString(_ color: Color) -> String {
        switch color {
        case .red: return "red"
        case .green: return "green"
        case .blue: return "Blue"
        case .yellow: return "yellow"
        case .orange: return "orange"
        case .purple: return "purple"
        case .pink: return "Pink"
        case .brown: return "brown"
        case .gray: return "gray"
        case Color("Blue"): return "bluecolor"
        case Color("Pink"): return "pinkcolor"
        default: return "unknown"
        }
    }

    func colorFromString(_ colorName: String) -> Color {
        switch colorName {
        case "red": return .red
        case "green": return .green
        case "Blue": return .blue
        case "yellow": return .yellow
        case "orange": return .orange
        case "purple": return .purple
        case "Pink": return .pink
        case "brown": return .brown
        case "gray": return .gray
        case "bluecolor": return Color("Blue")
        case "pinkcolor": return Color("Pink")
        default: return .gray
        }
    }

    struct ImagePicker: UIViewControllerRepresentable {
        @Binding var selectedImage: UIImage?

        class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
            let parent: ImagePicker

            init(_ parent: ImagePicker) {
                self.parent = parent
            }

            func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
                if let uiImage = info[.originalImage] as? UIImage {
                    parent.selectedImage = uiImage
                }
                picker.dismiss(animated: true)
            }
        }

        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }

        func makeUIViewController(context: Context) -> UIImagePickerController {
            let picker = UIImagePickerController()
            picker.delegate = context.coordinator
            return picker
        }

        func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    }
}

@ViewBuilder
func navigationCard<Destination: View>(title: String, systemImage: String, destination: Destination) -> some View {
    NavigationLink(destination: destination) {
        HStack {
            Image(systemName: systemImage)
                .font(.system(size: 20))
                .foregroundColor(Color("Blue"))
                .frame(width: 30)

            Text(title)
                .foregroundColor(.primary)
                .font(.subheadline)

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
        )
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
}
@ViewBuilder
func navigationBox<Destination: View>(title: String, systemImage: String, destination: Destination) -> some View {
    NavigationLink(destination: destination) {
        HStack {
            Image(systemName: systemImage)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundColor(Color("Blue"))
                .padding(.leading, 10)

            Spacer()

            Text(title)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .foregroundColor(.primary)

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .padding(.trailing, 10)
        }
        .frame(height: 60)
        .background(Color("navBG"))
        .cornerRadius(20)
        .shadow(color: Color("ColorGray").opacity(0.3), radius: 5, x: 0, y: 4)
    }
}
