import SwiftUI
import PhotosUI

struct ContentView: View {
    @StateObject private var viewModel = UserViewModel()
    @State private var editName: String = ""
    @State private var editAge: String = ""
    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        NavigationView {
            Form {
                // Search Bar
                Section {
                    TextField("Search by name...", text: $viewModel.searchText)
                        .textFieldStyle(.roundedBorder)
                }

                // All Users List (appears above entry form)
                Section(header: Text("All Users")) {
                    // Use enumerated to produce stable index for mapping
                    List {
                        ForEach(Array(viewModel.filteredUsers.enumerated()), id: \.element.id) { (filteredIndex, user) in
                            HStack(spacing: 12) {
                                // Load image via viewModel helper
                                if let uiImage = viewModel.uiImage(for: user) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFit() // ✅ changed from scaledToFill
                                        .frame(width: 60, height: 60)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.gray.opacity(0.25), lineWidth: 1)
                                        )
                                        .shadow(radius: 1)
                                } else {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 60, height: 60)
                                        .overlay(
                                            Image(systemName: "person.crop.rectangle")
                                                .foregroundColor(.gray)
                                                .font(.system(size: 22))
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.gray.opacity(0.25), lineWidth: 1)
                                        )
                                }


                                VStack(alignment: .leading, spacing: 4) {
                                    Text(user.name)
                                        .font(.headline)
                                    Text("Age: \(user.age)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .contentShape(Rectangle()) // make whole row tappable
                            .onTapGesture {
                                viewModel.selectedUser = user
                                editName = user.name
                                editAge = "\(user.age)"
                                viewModel.isEditing = true
                            }
                        }
                        // onDelete applied to ForEach's collection
                        .onDelete { indexSet in
                            // Map indices in filteredUsers -> indices in users
                            let actualIndexes = IndexSet(indexSet.compactMap { filteredIndex in
                                viewModel.indexInUsers(forFilteredIndex: filteredIndex)
                            })
                            viewModel.deleteUser(at: actualIndexes)
                        }
                    }
                    .listStyle(PlainListStyle())
                    .frame(minHeight: 150)
                }

                // Enter User Info
                Section(header: Text("Enter Your Info")) {
                    TextField("Name", text: $viewModel.name)
                    TextField("Age", text: $viewModel.ageText)
                        .keyboardType(.numberPad)

                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        HStack {
                            Image(systemName: "photo.on.rectangle.angled")
                            Text("Select Image")
                        }
                    }
                    .onChange(of: selectedItem) { newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                viewModel.selectedImageData = data
                                if let uiImage = UIImage(data: data) {
                                    viewModel.selectedImage = uiImage
                                }
                            }
                        }
                    }

                    if let selectedImage = viewModel.selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 120)
                            .cornerRadius(10)
                            .padding(.top, 5)
                    }

                    Button("Save") {
                        viewModel.save()
                    }
                }
            }
            .navigationTitle("User Info")
            .onAppear { viewModel.fetchAll() }
            // Edit sheet remains unchanged; keep your existing sheet code if you have it
        }
    }
}


#Preview {
    ContentView()
}
