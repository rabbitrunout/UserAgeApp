

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
                searchSection
                userListSection
                entrySection
            }
            .navigationTitle("User Info")
            .onAppear { viewModel.fetchAll() }
        }
    }
}

extension ContentView {
    private var searchSection: some View {
        Section {
            TextField("Search by name...", text: $viewModel.searchText)
                .textFieldStyle(.roundedBorder)
        }
    }

    private var userListSection: some View {
        Section(header: Text("All Users")) {
            List {
                ForEach(Array(viewModel.filteredUsers.enumerated()), id: \.element.id) { (filteredIndex, user) in
                    userRow(for: user, filteredIndex: filteredIndex)
                }
                .onDelete { indexSet in
                    let actualIndexes = IndexSet(indexSet.compactMap {
                        viewModel.indexInUsers(forFilteredIndex: $0)
                    })
                    viewModel.deleteUser(at: actualIndexes)
                }
            }
            .listStyle(PlainListStyle())
            .frame(minHeight: 150)
        }
    }

    private func userRow(for user: UserInfo, filteredIndex: Int) -> some View {
        HStack(spacing: 12) {
            if let uiImage = viewModel.uiImage(for: user) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.25), lineWidth: 1))
                    .shadow(radius: 1)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(Image(systemName: "person.crop.rectangle").foregroundColor(.gray).font(.system(size: 22)))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.25), lineWidth: 1))
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
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.selectedUser = user
            editName = user.name
            editAge = "\(user.age)"
            viewModel.isEditing = true
        }
    }

    private var entrySection: some View {
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
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        await MainActor.run {
                            viewModel.selectedImageData = data
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

            if viewModel.isSaving {
                VStack {
                    ProgressView(value: viewModel.progress)
                        .progressViewStyle(.linear)
                        .tint(.green)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.progress)
                        .padding(.vertical, 8)
                    Text("Saving user…")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }

            Button("Save") {
                viewModel.save()
            }
            .disabled(viewModel.isSaving)
        }
    }
}
#Preview {
    ContentView()
}
