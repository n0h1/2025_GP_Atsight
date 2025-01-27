import SwiftUI
import MapKit
import FirebaseAuth
import FirebaseFirestore

struct HomeView: View {
    @Binding var selectedChild: Child?
    @Binding var expandedChild: Child?
    @State private var firstName: String = "Guest"
    @State private var children: [Child] = []

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                HStack {
                    Spacer()
                    Image("Image 1")
                        .resizable()
                        .frame(width: 140, height: 130)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding(.top)

                VStack(alignment: .leading, spacing: 20) {
                    Text("Hello \(firstName)")
                        .font(.largeTitle).bold()
                        .foregroundColor(Color("Blue"))
                        .padding(.top, 20)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("View your kids' locations.")
                            .font(.title3)
                            .foregroundColor(Color("BlackFont"))
                            .fontWeight(.medium)

                        Text("Stay connected and informed about their well-being.")
                            .font(.body)
                            .foregroundColor(Color("ColorGray"))
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    HStack {
                        NavigationLink(destination: AddChildView(fetchChildrenCallback: fetchChildrenFromFirestore)) {
                            Text("Add child")
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .foregroundColor(Color("Blue"))
                                .background(Color("BgColor"))
                                .cornerRadius(25)
                                .shadow(radius: 5)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(Color("ColorGray"), lineWidth: 1)
                                )
                        }
                        .padding(.leading, 250)
                    }

                    ScrollView {
                        VStack(spacing: 15) {
                            ForEach(children) { child in
                                NavigationLink(destination: ChildDetailView(child: child)) {
                                    ChildCardView(child: child, expandedChild: $expandedChild)
                                        .padding(.top)
                                }
                                .onDisappear {
                                    fetchChildrenFromFirestore()
                                }
                            }
                        }
                    }
                    .padding(.top, 3)
                }
                .onAppear {
                    fetchUserName()
                    fetchChildrenFromFirestore()
                }
            }
            .padding(.horizontal, 10)
            .background(Color("BgColor").ignoresSafeArea()) // ✅ خلفية الصفحة كاملة
        }
    }

    func fetchChildrenFromFirestore() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("guardians").document(userId).collection("children").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching children: \(error.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    self.children = snapshot?.documents.compactMap { doc in
                        let data = doc.data()
                        return Child(
                            id: doc.documentID,
                            name: data["name"] as? String ?? "Unknown",
                            color: data["color"] as? String ?? "gray",
                            imageName: data["imageName"] as? String
                        )
                    } ?? []
                }
            }
        }
    }

    func fetchUserName() {
        if let userId = Auth.auth().currentUser?.uid {
            let db = Firestore.firestore()
            db.collection("guardians").document(userId).getDocument { document, error in
                if let document = document, document.exists {
                    if let fetchedFirstName = document.data()?["FirstName"] as? String {
                        firstName = fetchedFirstName
                    }
                }
            }
        }
    }
}

struct ChildDetailView: View {
    @State var child: Child
    @Environment(\.presentationMode) var presentationMode
    @State private var guardianID: String = Auth.auth().currentUser?.uid ?? ""

    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        // Removed NavigationView here
        VStack {
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.black)
                        .font(.system(size: 20, weight: .bold))
                }

                Spacer()

                Text(child.name)
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(Color("BlackFont"))

                Spacer()
                Spacer().frame(width: 24)
            }
            .padding()
            .padding(.top, -10)

            VStack(spacing: 20) {
                NavigationLink(destination: ChildLocationView(child: child)) {
                    VStack {
                        Image(systemName: "location.fill")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundColor(Color("Blue"))
                        Text("View Last Location")
                            .font(.headline)
                            .foregroundColor(Color("Blue"))
                    }
                    .frame(width: 300, height: 140)
                    .background(Color("BgColor"))
                    .cornerRadius(20)
                    .shadow(radius: 10)
                }

                NavigationLink(destination: EditChildProfile(guardianID: guardianID, child: $child)) {
                    VStack {
                        Image(systemName: "figure.child.circle")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundColor(Color("ColorGreen"))
                        Text("Child Profile")
                            .font(.headline)
                            .foregroundColor(Color("ColorGreen"))
                    }
                    .frame(width: 300, height: 140)
                    .background(Color("BgColor"))
                    .cornerRadius(20)
                    .shadow(radius: 10)
                }

                NavigationLink(destination: LocationHistoryView()) {
                    VStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundColor(Color("ColorGray"))
                        Text("Location History")
                            .font(.headline)
                            .foregroundColor(Color("ColorGray"))
                    }
                    .frame(width: 300, height: 140)
                    .background(Color("BgColor"))
                    .cornerRadius(20)
                    .shadow(radius: 10)
                }

                NavigationLink(destination: AddZonePage(zones: $child.zones)) {
                    VStack {
                        Image(systemName: "mappin.and.ellipse")
                            .resizable()
                            .frame(width: 40, height: 60)
                            .foregroundColor(Color("ColorRed"))
                        Text("Zones Setup")
                            .font(.headline)
                            .foregroundColor(Color("ColorRed"))
                    }
                    .frame(width: 300, height: 140)
                    .background(Color("BgColor"))
                    .cornerRadius(20)
                    .shadow(radius: 10)
                }
            }
            .padding()
            .background(Color("BgColor"))
            .cornerRadius(15)
        }
        .background(Color("BgColor").ignoresSafeArea())
        // Keep navigationBarBackButtonHidden and navigationBarHidden on this view
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
    }
}

#Preview("Home") {
    HomeView(selectedChild: .constant(nil), expandedChild: .constant(nil)).environmentObject(AppState())
}
