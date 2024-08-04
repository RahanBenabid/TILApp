import Vapor
import Fluent

final class Category: Model {
	static let schema = "categories"
	
	@ID
	var id: UUID?
	
	@Field(key: "name")
	var name: String
	
	init() {}
	
	init(id: UUID? = nil, name: String) {
		self.id = id
		self.name = name
	}
}

extension Category: Content {}
