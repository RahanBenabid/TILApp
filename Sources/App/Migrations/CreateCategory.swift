import Fluent

struct CreateCategory: Migration {
	
	func prepare(on database: any Database) -> EventLoopFuture<Void> {
		database.schema(Category.v29092024.schemaName)
			.id()
			.field("name", .string, .required)
			.create()
	}
	
	func revert(on database: any Database) -> EventLoopFuture<Void> {
		database.schema("categories").delete()
	}
}

extension Category {
	enum v29092024 {
		static let schemaName = "categories"
		static let id = FieldKey(stringLiteral: "id")
		static let name = FieldKey(stringLiteral: "name")
	}
}
