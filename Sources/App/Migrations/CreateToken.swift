import Fluent

struct CreateToken: Migration {
	func prepare(on database: any Database) -> EventLoopFuture<Void> {
		database.schema("tokens")
			.id()
			.field(Token.v29092024.value, .string, .required)
			.field(Token.v29092024.userID, .uuid, .required, .references(User.v20240929.schemaName, User.v20240929.id, onDelete: .cascade))
			.create()
	}
	
	func revert(on database: any Database) -> EventLoopFuture<Void> {
		database.schema(Token.v29092024.schameName).delete()
	}
}

extension Token {
	enum v29092024 {
		static let schameName = "tokens"
		static let id = FieldKey(stringLiteral: "id")
		static let value = FieldKey(stringLiteral: "value")
		static let userID = FieldKey(stringLiteral: "userID")
	}
}
