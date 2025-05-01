import SwiftUI

struct WelcomeView: View {
    var body: some View {
        VStack(spacing: 40) {
            // App Name
            HStack {
                Text("AtSight")
                    .font(.headline)
                    .foregroundColor(Color.blue)
                    .padding(.leading, 20)
                Spacer()
            }

            // Logo Image (Location Mark with Child)
            Image("locationMarkLogo") // <-- Use this as the logo asset
                .resizable()
                .scaledToFit()
                .frame(width: 140, height: 140)

            // Welcome Text
            Text("Welcome")
                .font(.largeTitle)
                .fontWeight(.semibold)
                .foregroundColor(.blue)

            // Get Started Button
            Button(action: {
                // Navigation logic here
            }) {
                Text("Get Started")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(red: 200/255, green: 230/255, blue: 180/255)) // soft green
                    .foregroundColor(.white)
                    .cornerRadius(40)
            }
            .padding(.horizontal, 30)

            Spacer()
        }
        .padding(.top, 60)
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
    }
}
