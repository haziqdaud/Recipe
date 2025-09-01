import Foundation
import RealmSwift

class RecipeType: Object, Codable, Identifiable {
    @objc dynamic var id: Int = 0
    @objc dynamic var name: String = ""
    
    // Primary key for Realm
    override static func primaryKey() -> String? {
        return "id"
    }
    
    // Codable support
    enum CodingKeys: String, CodingKey {
        case id, name
    }
    
    required convenience init(from decoder: Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
    }
    
    // Equatable conformance (compare by primary key)
    static func == (lhs: RecipeType, rhs: RecipeType) -> Bool {
        return lhs.id == rhs.id
    }
}
