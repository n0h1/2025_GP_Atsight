//
//  HomeView.swift
//  AtSightWatchh
//
//  Created by lona on 15/04/2025.
//


import SwiftUI

struct HomeView: View {
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 16) {
                // Header at top
                HStack {
                    Text("AtSight")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color("Blue"))

                    Spacer()

                    Image("Image") // Your logo image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                // Contact Buttons
                VStack(alignment: .leading, spacing: 12) {
                    ContactRow(name: "Mom")
                    ContactRow(name: "Dad")
                }

                // Spacer between chat and SOS button
                Spacer(minLength: 1)

                // SOS Button
                Button(action: {
                    // SOS action
                }) {
                    Text("SOS button")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.red)
                        .cornerRadius(25)
                }
                .buttonStyle(.plain)

                Spacer()
            }
        }
    }
}

// MARK: - Reusable Row View
struct ContactRow: View {
    var name: String

    var body: some View {
        HStack(spacing: 10) {
            Button(action: {
                // Action for chat
            }) {
                Image("chat") // Chat icon
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)

            Text(name)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color("Blue"))

            Spacer()
        }
        .padding(.horizontal, 30)
    }
}

#Preview {
    HomeView()
}
