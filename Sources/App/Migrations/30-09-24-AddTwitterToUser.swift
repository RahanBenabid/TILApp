import Fluent

struct AddTwitterToUser: Migration {
	// define the two required funcitons
	func prepare(on database: any Database) -> EventLoopFuture<Void> {
		// notice the schema is from the old version and the twitterURL is from the newer version
		database.schema(User.v20240929.schemaName)
			.field(User.v20240930.twitterURL, .string)
			.update()
	}
	
	func revert(on database: any Database) -> EventLoopFuture<Void> {
		database.schema(User.v20240929.schemaName)
		// this time in revert instead of deleting the table, we will just delete the field
			.deleteField(User.v20240930.twitterURL)
			.update()
	}
}
