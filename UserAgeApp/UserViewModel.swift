import Foundation
import FirebaseDatabase
import SwiftUI
import Combine 

struct UserInfo: Identifiable, Codable {
    var id: String
    var name: String
    var age: Int
}

class UserViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var ageText: String = ""
    @Published var storedData: UserInfo?

    private let dbRef = Database.database().reference()
    private let usersPath = "users"

    // SAVE to Realtime Database
    func save() {
        guard let age = Int(ageText) else { return }

        let id = UUID().uuidString
        let userInfo = UserInfo(id: id, name: name, age: age)

        let data: [String: Any] = [
            "id": userInfo.id,
            "name": userInfo.name,
            "age": userInfo.age
        ]

        dbRef.child(usersPath).child(id).setValue(data) { error, _ in
            if let error = error {
                print("Error saving to Realtime DB: \(error)")
            } else {
                DispatchQueue.main.async {
                    self.storedData = userInfo
                }
            }
        }
    }

    // FETCH first user entry
    func fetch() {
        dbRef.child(usersPath).observeSingleEvent(of: .value) { snapshot in
            guard let dict = snapshot.value as? [String: Any],
                  let first = dict.values.first as? [String: Any],
                  let id = first["id"] as? String,
                  let name = first["name"] as? String,
                  let age = first["age"] as? Int else {
                return
            }

            let userInfo = UserInfo(id: id, name: name, age: age)

            DispatchQueue.main.async {
                self.storedData = userInfo
                self.name = userInfo.name
                self.ageText = "\(userInfo.age)"
            }
        }
    }
}
