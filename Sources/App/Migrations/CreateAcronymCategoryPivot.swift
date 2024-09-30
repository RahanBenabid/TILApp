import Fluent

struct CreateAcronymCategoryPivot: Migration {

	func prepare(on database: any Database) -> EventLoopFuture<Void> {
		database.schema(AcronymCategoryPivot.v29092024.schemaName)
			.id()
		// Create the two columns for the two properties. These use the key provided to the property wrapper, set the type to UUID, and mark the column as required. They also set a reference to the respective model to create a foreign key constraint
			.field(AcronymCategoryPivot.v29092024.acronymID, .uuid, .required, .references(Acronym.v30092024.schemaName, Acronym.v30092024.id, onDelete: .cascade))
			.field(AcronymCategoryPivot.v29092024.categoryID, .uuid, .required, .references(Category.v29092024.schemaName, Category.v29092024.id, onDelete: .cascade))
			.create()
	}
	
	func revert(on database: any Database) -> EventLoopFuture<Void> {
		database.schema(AcronymCategoryPivot.v29092024.schemaName).delete()
	}
}

extension AcronymCategoryPivot {
	enum v29092024 {
		static let schemaName = "acronym-category-pivot"
		static let id = FieldKey(stringLiteral: "id")
		static let acronymID = FieldKey(stringLiteral: "acronymID")
		static let categoryID = FieldKey(stringLiteral: "categoryID")
	}
}
