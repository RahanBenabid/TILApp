import Fluent

struct CreateCategory: Migration {
	
	func prepare(on database: any Database) -> EventLoopFuture<Void> {
		database.schema("categories")
			.id()
			.field("name", .string, .required)
			.create()
	}
	
	func revert(on database: any Database) -> EventLoopFuture<Void> {
		database.schema("categories").delete()
	}
}
