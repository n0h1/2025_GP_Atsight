import SwiftUI
import Firebase
import FirebaseAuth

struct LoginPage: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showResetPasswordAlert = false
    @State private var resetPasswordMessage = ""
    @State private var isLoggedIn = false // ✅ Track login success

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

                    Text("Welcome back")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color("FontColor"))

                    Text("Sign in to access your account")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                VStack(spacing: 15) {
                    TextField("Enter your email", text: $email)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(50)
                        .keyboardType(.emailAddress)

                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(50)

                    Button(action: {
                        resetPassword()
                    }) {
                        Text("Forget Password?")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 20)

                Button(action: {
                    login()
                }) {
                    Text("Log in")
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
                    Text("New Member?")
                    NavigationLink(destination: SignUpPage()) {
                        Text("Register Now")
                            .foregroundColor(.blue)
                            .underline()
                    }
                }
                Spacer()
            }
            .background(Color("CustomBackground").edgesIgnoringSafeArea(.all))
            .alert(isPresented: $showResetPasswordAlert) {
                Alert(title: Text("Password Reset"), message: Text(resetPasswordMessage), dismissButton: .default(Text("OK")))
            }
            .fullScreenCover(isPresented: $isLoggedIn) { // ✅ Navigate to HomeView after login
                MainView()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .navigationBarBackButtonHidden(true)
    }

    func login() {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                print(error.localizedDescription)
            } else {
                // ✅ Login successful, navigate to HomeView
                isLoggedIn = true
            }
        }
    }

    func resetPassword() {
        guard !email.isEmpty else {
            resetPasswordMessage = "Please enter your email address first."
            showResetPasswordAlert = true
            return
        }

        print("Reset password called for: \(email)") // Debugging log

        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                resetPasswordMessage = error.localizedDescription
            } else {
                resetPasswordMessage = "A password reset link has been sent to your email."
            }
            showResetPasswordAlert = true
        }
    }
}

#Preview {
    LoginPage()
}
