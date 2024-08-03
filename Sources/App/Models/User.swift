import Fluent
import Vapor

final class User: Model {
	static let schema = "users"
	
	@ID
	var id: UUID?
	
	@Field(key: "name")
	var name: String
	
	@Field(key: "username")
	var username: String
	
	@Children(for: \.$user)
	var acronyms: [Acronym]
	
	init() {}
	
	init(id: UUID? = nil, name: String, username: String) {
		self.name = name
		self.username = username
	}
}

extension User: Content {}
