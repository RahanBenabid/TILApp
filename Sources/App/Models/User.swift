import Fluent
import Vapor

final class User: Model {
	static let schema = "users"
	
	@ID
	var id: UUID?
	
	@Field(key: User.v20240929.name)
	var name: String
	
	@Field(key: User.v20240929.username)
	var username: String
	
	@Field(key: User.v20240929.password)
	var password: String
	
	@Children(for: \.$user)
	var acronyms: [Acronym]
	
	@Field(key: User.v20240929.email)
	var email: String
	
	@OptionalField(key: User.v20240929.profilePicture)
	var profilePicture: String?
	
	@OptionalField(key: User.v20240930.twitterURL)
	var twitterURL: String?
	
	init() {}
	
	init(
		id: UUID? = nil,
		name: String,
		username: String,
		password: String,
		email: String,
		profilePicture: String? = nil,
		twitterURL: String? = nil) {
			self.name = name
			self.username = username
			self.password = password
			self.email = email
			self.profilePicture = profilePicture // the nil initialisation will help the app continue to compile without change
			self.twitterURL = twitterURL
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
	
	final class PublicV2: Content {
		var id: UUID?
		var name: String
		var username: String
		var twitterURL: String?
		
		init(id: UUID?, name: String, username: String, twitterURL: String?) {
			self.id = id
			self.name = name
			self.username = username
			self.twitterURL = twitterURL
		}
	}
}

extension User: Content {}

// represents the object that will be sent in the GET API
extension User {
	func convertToPublic() -> User.Public {
		return User.Public(id: id, name: name, username: username)
	}
	
	func convertToPublicV2() -> User.PublicV2 {
		return User.PublicV2(id: id, name: name, username: username, twitterURL: twitterURL)
	}
}

// this will help to reduce nesting, it will call convertToPublic() on EventLoopFuture<User>, [User] and EventLoopFuture<[User]>, they allow you to change your route to handle returning a public user
// there is a lotta versions below to convert to all the kinds of instances you want

extension EventLoopFuture where Value: User {
	func convertToPublic() -> EventLoopFuture<User.Public> {
		return self.map { user in
			return user.convertToPublic()
		}
	}
	
	func convertToPublicV2() -> EventLoopFuture<User.PublicV2> {
		return self.map { user in
			return user.convertToPublicV2()
		}
	}
}

extension Collection where Element: User {
	func convertToPublic() -> [User.Public] {
		return self.map { $0.convertToPublic() }
	}
	
	func convertToPublicV2() -> [User.PublicV2] {
		return self.map { $0.convertToPublicV2() }
	}
}

extension EventLoopFuture where Value == Array<User> {
	func convertToPublic() -> EventLoopFuture<[User.Public]> {
		return self.map { $0.convertToPublic() }
	}
	
	func convertToPublicV2() -> EventLoopFuture<[User.PublicV2]> {
		return self.map { $0.convertToPublicV2() }
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
