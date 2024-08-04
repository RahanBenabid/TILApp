import Fluent

struct CreateAcronymCategoryPivot: Migration {

	func prepare(on database: any Database) -> EventLoopFuture<Void> {
		database.schema("acronym-category-pivot")
			.id()
		// Create the two columns for the two properties. These use the key provided to the property wrapper, set the type to UUID, and mark the column as required. They also set a reference to the respective model to create a foreign key constraint
			.field("acronymID", .uuid, .required, .references("acronyms", "id", onDelete: .cascade))
			.field("categoryID", .uuid, .required, .references("categories", "id", onDelete: .cascade))
			.create()
	}
	
	func revert(on database: any Database) -> EventLoopFuture<Void> {
		database.schema("acronym-category-pivot").delete()
	}
}
