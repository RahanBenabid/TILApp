import Vapor
import Fluent

final class Category: Model {
	static let schema = "categories"
	
	@ID
	var id: UUID?
	
	@Field(key: "name")
	var name: String
	
	@Siblings(
		through: AcronymCategoryPivot.self,
		from: \.$category,
		to: \.$acronym)
	var acronyms: [Acronym]
	
	init() {}
	
	init(id: UUID? = nil, name: String) {
		self.id = id
		self.name = name
	}
}

extension Category: Content {}

extension Category {
	static func addCategory(
		_ name: String,
		to acronym: Acronym,
		on req: Request) -> EventLoopFuture<Void> {
			// search for category with the provided name
			return Category.query(on: req.db)
				.filter(\.$name == name)
				.first()
				.flatMap { foundCategory in
					if let existingCategory = foundCategory {
						// if it exisits, set up the relationship between the cat and the acronym
						return acronym.$categories
							.attach(existingCategory, on: req.db)
					} else {
						// if not create a new cat with the provided name, save it and set the relationship
						let category = Category(name: name)
						return category.save(on: req.db).flatMap {
							acronym.$categories
								.attach(category, on: req.db)
						}
					}
				}
		}
}
