import Fluent

struct CreateToken: Migration {
	func prepare(on database: any Database) -> EventLoopFuture<Void> {
		database.schema("tokens")
			.id()
			.field("value", .string, .required)
			.field("userID", .uuid, .required, .references("users", "id"))
			.create()
	}
	
	func revert(on database: any Database) -> EventLoopFuture<Void> {
		database.schema("tokens").delete()
	}
}
