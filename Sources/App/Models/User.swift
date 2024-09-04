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
  
  @Field(key: "password")
  var password: String
	
	@Children(for: \.$user)
	var acronyms: [Acronym]
	
	init() {}
	
  init(id: UUID? = nil, name: String, username: String, password: String) {
		self.name = name
		self.username = username
    self.password = password
	}
	
	final class Public: Content {
		var id: UUID?
		var name: String
		var username: String
		
		init(id: UUID?, name: String, username: String) {
			self.id = id
			self.name = name
			self.username = username
		}
	}
}

extension User: Content {}

// represents the object that will be sent in the GET API
extension User {
	func convertToPublic() -> User.Public {
		return User.Public(id: id, name: name, username: username)
	}
}

// this will help to reduce nesting, it will call convertToPublic() on EventLoopFuture<User>, [User] and EventLoopFuture<[User]>, they allow you to change your route to handle returning a public user

extension EventLoopFuture where Value: User {
	func convertToPublic() -> EventLoopFuture<User.Public> {
		return self.map { user in
			return user.convertToPublic()
		}
	}
}

extension Collection where Element: User {
	func convertToPublic() -> [User.Public] {
		return self.map { $0.convertToPublic() }
	}
}

extension EventLoopFuture where Value == Array<User> {
	func convertToPublic() -> EventLoopFuture<[User.Public]> {
		return self.map { $0.convertToPublic() }
	}
}

// The ModelAuthenticable will allow Fluent models to use the HTTP Auth
extension User: ModelAuthenticatable {
	
	// tells fluents the username and password path
	static let usernameKey = \User.$username
	static let passwordHashKey = \User.$password
	
	// very the hash here (you hash the input password and compare the result with the db hash)
	func verify(password: String) throws -> Bool {
		try Bcrypt.verify(password, created: self.password)
	}
}

// conform user to ModelSessionAuthenticatable to be able to save and retreive user as part of the session
extension User: ModelSessionAuthenticatable {}
// allows vapor to authenticate users with a username and password when they login, already implemented so nothing to ædd here
extension User: ModelCredentialsAuthenticatable {}
