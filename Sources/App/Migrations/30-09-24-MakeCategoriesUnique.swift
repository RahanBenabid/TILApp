import Fluent

struct MakeCategoriesUnique: Migration {
	func prepare(on database: any Database) -> EventLoopFuture<Void> {
		database.schema(Category.v29092024.schemaName)
			.unique(on: Category.v29092024.name)
			.update()
	}
	
	func revert(on database: any Database) -> EventLoopFuture<Void> {
		database.schema(Category.v29092024.schemaName)
			.deleteUnique(on: Category.v29092024.name)
			.update()
	}
}
