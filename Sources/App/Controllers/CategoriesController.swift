import Vapor

struct CategoriesController: RouteCollection {
	func boot(routes: any RoutesBuilder) throws {
		
		let categoriesRoute = routes.grouped("api", "categories")
		
		categoriesRoute.post(use: createHandler)
		categoriesRoute.get(use: getAllHandler)
		categoriesRoute.get(":categoryID", use: getHandler)
		categoriesRoute.get(":categoryID", "acronyms", use: getAcronymsHandler)
	}
	
	@Sendable func createHandler(_ req: Request) throws -> EventLoopFuture<Category> {
		let category = try req.content.decode(Category.self)
		return category.save(on: req.db).map { category }
	}
	
	@Sendable func getAllHandler(_ req: Request) -> EventLoopFuture<[Category]> {
		Category.query(on: req.db).all()
	}
	
	@Sendable func getHandler(_ req: Request) -> EventLoopFuture<Category> {
		Category.find(req.parameters.get("categoryID"), on: req.db)
			.unwrap(or: Abort(.notFound))
	}
	
	@Sendable func getAcronymsHandler(_ req: Request) -> EventLoopFuture<[Acronym]> {
		Category.find(req.parameters.get("categoryID"), on: req.db)
			.unwrap(or: Abort(.notFound))
			.flatMap { category in
				category.$acronyms.get(on: req.db)
			}
	}
}
