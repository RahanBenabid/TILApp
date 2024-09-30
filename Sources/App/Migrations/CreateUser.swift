import Fluent


// create the new type in the migration (create the user table in the database)
struct CreateUser: Migration {
	
	// reminder that the function is reaquired by the database
	func prepare(on database: Database) -> EventLoopFuture<Void> {
		database.schema(User.v20240929.schemaName)
			.id()
			.field(User.v20240929.name, .string, .required)
			.field(User.v20240929.username, .string, .required)
			.field(User.v20240929.password, .string, .required)
			.field(User.v20240929.email, .string, .required)
			.field(User.v20240929.profilePicture, .string)
			.unique(on: User.v20240929.username)
			.unique(on: User.v20240929.email)
			.create()
	}
	
	func revert(on database: Database) -> EventLoopFuture<Void> {
		database.schema(User.v20240929.schemaName).delete()
	}
}

extension User {
	enum v20240929 {
		static let schemaName = "users"
		static let id = FieldKey(stringLiteral: "id")
		static let name = FieldKey(stringLiteral: "name")
		static let username = FieldKey(stringLiteral: "username")
		static let email = FieldKey(stringLiteral: "email")
		static let profilePicture = FieldKey(stringLiteral: "profilePicture")
		static let password = FieldKey(stringLiteral: "password")
	}
	
	enum v20240930 {
		static let twitterURL = FieldKey(stringLiteral: "twitterURL")
	}
	
}
