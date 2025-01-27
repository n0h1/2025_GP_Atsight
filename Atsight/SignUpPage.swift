import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SignUpPage: View {
    @State private var isTermsAccepted = false
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isRegistered = false

    var body: some View {
        NavigationView {
            VStack(spacing: 10) {
                HStack {
                    Image("logotext")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, -20)

                VStack(spacing: 5) {
                    Image("logoPin")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                    Text("Get Started")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color("FontColor"))
                    Text("By Creating an account")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                VStack(spacing: 15) {
                    TextField("First Name", text: $firstName)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(50)
                    TextField("Last Name", text: $lastName)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(50)
                    TextField("Valid email", text: $email)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(50)
                    SecureField("Strong Password", text: $password)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(50)
                }
                .padding(.horizontal, 20)

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(10)
                }

                Button(action: {
                    register()
                }) {
                    Text("sign up")
                        .font(.headline)
                        .foregroundColor(Color("BlackFont"))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("button"))
                        .cornerRadius(10)
                }
                .padding(.horizontal, 40)
                .padding(.top, 10)

                HStack {
                    Text("Do you have an account?")
                    NavigationLink(destination: LoginPage()) {
                        Text("Sign In")
                            .foregroundColor(.blue)
                            .underline()
                    }
                }
                Spacer()
            }
            .padding()
            .background(Color("CustomBackground").edgesIgnoringSafeArea(.all))
            .navigationBarBackButtonHidden(true)
            .fullScreenCover(isPresented: $isRegistered) {
                MainView()
            }
        }
    }

    func register() {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
            } else if let userId = result?.user.uid {
                let db = Firestore.firestore()
                db.collection("guardians").document(userId).setData([
                    "FirstName": firstName,
                    "LastName": lastName,
                    "email": email,
                    "password": password,
                    "phonenum": "",
                    "region": [0.0, 0.0]
                ]) { error in
                    if let error = error {
                        errorMessage = "Failed to save user data: \(error.localizedDescription)"
                    } else {
                        isRegistered = true
                    }
                }
            }
        }
    }
}

#Preview {
    SignUpPage()
}
