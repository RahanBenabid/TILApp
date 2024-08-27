import Fluent


// create the new type in the migration (create the user table in the database)
struct CreateUser: Migration {
	
	// reminder that the function is reaquired by the database
	func prepare(on database: Database) -> EventLoopFuture<Void> {
		database.schema("users")
			.id()
			.field("name", .string, .required)
			.field("username", .string, .required)
			.field("password", .string, .required)
		// make the username unique
			.unique(on: "username")
			.create()
	}
	
	func revert(on database: Database) -> EventLoopFuture<Void> {
		database.schema("users").delete()
	}
}
