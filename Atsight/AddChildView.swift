//
//  AddChildView.swift
//  Atsight
//
//  Created by Najd Alsabi on 22/03/2025.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct AddChildView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedGender: String? = nil
    @State private var showNamePage = false
    var fetchChildrenCallback: (() -> Void)?  // Add callback for refreshing children list

    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            // Back Button
            HStack {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(Color("BlackFont"))
                        .font(.system(size: 20, weight: .bold))
                }
                Spacer()
            }
            .padding()

            // Title
            Text("What is your child's gender?")
                .font(.title)
                .bold()
                .padding(.horizontal, 5)

            // Gender Selection (Circles with Labels)
            VStack(spacing: 70) {
                GenderOptionView(
                    gender: "Boy",
                    color: .blue,
                    isSelected: selectedGender == "Boy"
                ) {
                    selectedGender = "Boy"
                }

                GenderOptionView(
                    gender: "Girl",
                    color: .pink,
                    isSelected: selectedGender == "Girl"
                ) {
                    selectedGender = "Girl"
                }
            }
            .frame(maxWidth: .infinity) // Centering the options
            .padding(.horizontal)
            .padding(.top, 60)

            Spacer()

            // Next Button
            HStack {
                Spacer()
                Button(action: { showNamePage = true }) {
                    Text("Next")
                        .frame(width: 190)
                        .padding()
                        .background(selectedGender != nil ? Color("Blue") : .gray)
                        .foregroundColor(.white)
                        .cornerRadius(30)
                        .shadow(radius: 5)
                }
                .disabled(selectedGender == nil)
                Spacer()
            }
            .padding(.bottom, 30)
            .fullScreenCover(isPresented: $showNamePage) {
                AddChildNameView(selectedGender: selectedGender ?? "", fetchChildrenCallback: fetchChildrenCallback)  // Pass callback to the next view
                    .onDisappear {
                        // Ensure we dismiss properly after adding the child
                        presentationMode.wrappedValue.dismiss()
                    }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

// Gender Option View
struct GenderOptionView: View {
    let gender: String
    let color: Color
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .fill(color.opacity(0.07))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color.green : Color.clear, lineWidth: 3)
                    )

                Image(gender)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 70, height: 70)

                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .font(.system(size: 15, weight: .bold))
                        .padding(4)
                        .background(Circle().fill(Color.green))
                        .offset(x: 29, y: -39)
                }
            }
            .onTapGesture(perform: onTap)

            Text(gender)
                .font(.title3)
                .foregroundColor(Color("BlackFont"))
        }
        .frame(maxWidth: .infinity)
    }
}



struct AddChildNameView: View {
    let selectedGender: String
    @State private var childName = ""
    @Environment(\.presentationMode) var presentationMode
    @State private var isLoading = false
    var fetchChildrenCallback: (() -> Void)?  // Callback to refresh the children list

    var body: some View {
        ZStack {
            // Bubble Background
            BubbleBackground(color: selectedGender == "Boy" ? .blue : .pink)

            VStack(alignment: .leading, spacing: 30) {
                // Back Button
                HStack {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.primary)
                            .font(.system(size: 22, weight: .medium))
                            .padding(8)
                    }
                    Spacer()
                }
                .padding(.top, 70)
                .padding(.horizontal, 10)

                // Title
                Text("What is your child's name?")
                    .font(.title)
                    .bold()
                    .foregroundColor(.primary)
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 20)

                // Text Field
                TextField("Enter name", text: $childName)
                    .padding()
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(selectedGender == "Boy" ? Color.blue.opacity(0.5) : Color.pink.opacity(0.5), lineWidth: 2)
                    )
                    .shadow(color: .gray.opacity(0.15), radius: 3, x: 0, y: 2)
                    .padding(.horizontal, 40)

                Spacer()

                // Submit Button
                HStack {
                    Spacer()
                    Button(action: handleSubmit) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(width: 190, height: 44)
                        } else {
                            Text("Submit")
                                .frame(width: 190)
                                .padding()
                                .background(childName.isEmpty ? .gray : Color("Blue"))
                                .foregroundColor(.white)
                                .font(.system(size: 18, weight: .semibold))
                                .cornerRadius(30)
                                .shadow(color: .gray.opacity(0.4), radius: 5, x: 0, y: 3)
                                .opacity(childName.isEmpty ? 0.5 : 1.0)
                        }
                    }
                    .disabled(childName.isEmpty || isLoading)
                    Spacer()
                }
                .padding(.bottom, 63)
            }
        }
        .edgesIgnoringSafeArea(.all)
    }

    func handleSubmit() {
        isLoading = true
        
        let child = Child(
            id: UUID().uuidString,
            name: childName,
            color: selectedGender == "Boy" ? "Blue" : "Pink"
        )
        
        if let guardianID = Auth.auth().currentUser?.uid {
            saveChildToFirestore(guardianID: guardianID, child: child) { result in
                switch result {
                case .success:
                    fetchChildrenCallback?()  // Refresh list
                    presentationMode.wrappedValue.dismiss()
                case .failure(let error):
                    print("Error saving child: \(error)")
                }
                isLoading = false
            }
        } else {
            print("No guardian logged in")
            isLoading = false
        }
    }
    
}



// Bubble Background Component
struct BubbleBackground: View {
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<12, id: \.self) { _ in
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: CGFloat.random(in: 40...100))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                }
            }
        }
    }
}




#Preview {
    AddChildView()
    
}
