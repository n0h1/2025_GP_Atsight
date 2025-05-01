import SwiftUI

struct VoiceChatView: View {
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                // Navigation Header
                HStack {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black)
                        .padding(.leading)

                    Spacer()

                    Text("Mom")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)

                    Spacer()

                    Spacer().frame(width: 40) // balance space from left icon
                }
                .padding(.vertical, 10)

                // Chat Bubbles
                ScrollView {
                    VStack(spacing: 12) {
                        VoiceMessageBubble(isSender: true)
                        VoiceMessageBubble(isSender: false)
                        VoiceMessageBubble(isSender: true)
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 10)
                }

                // Input Bar
                HStack {
                    Text("iMessage")
                        .foregroundColor(.gray)
                        .padding(.leading, 16)

                    Spacer()

                    Image(systemName: "waveform")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                        .padding(.trailing, 16)
                }
                .frame(height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.gray.opacity(0.4))
                        .background(Color.white.cornerRadius(20))
                )
                .padding(.all, 10)
            }
        }
    }
}

// MARK: - Voice Message Bubble
struct VoiceMessageBubble: View {
    var isSender: Bool

    var body: some View {
        HStack {
            if isSender {
                Spacer()
            }

            HStack(spacing: 8) {
                Image(systemName: "play.circle.fill")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundColor(.white.opacity(0.9))

                Image(systemName: "waveform") // Placeholder for waveform
                    .resizable()
                    .scaledToFit()
                    .frame(height: 20)

                Text("01:06")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSender ? Color.blue : Color.gray.opacity(0.4))
            )
            .frame(maxWidth: 200, alignment: .leading)

            if !isSender {
                Spacer()
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    VoiceChatView()
}
