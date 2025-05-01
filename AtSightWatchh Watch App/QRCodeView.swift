import SwiftUI

struct QRCodeView: View {
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                // QR Image
                Image("QR")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160, height: 160)

                // Instruction Text
                Text("Scan the QR code using the app\nto connect to the watch.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color("Blue"))
                    .font(.system(size: 14, weight: .semibold))

                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    QRCodeView()
}
