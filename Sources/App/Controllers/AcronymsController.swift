import Vapor
import Fluent

struct AcronymsController: RouteCollection {
	func boot(routes: RoutesBuilder) throws {
		
		// to generalise the path, since all of them use /api/acronyms
		let acronymsRoutes = routes.grouped("api", "acronyms")
		
		// registering the routes handlers
		acronymsRoutes.get(use: getAllHandler)
		acronymsRoutes.post(use: createHandler)
		acronymsRoutes.get(":acronymID", use: getHandler)
		acronymsRoutes.put(":acronymID", use: updateHandler)
		acronymsRoutes.delete(":acronymID", use: deleteHandler)
		acronymsRoutes.get("search", use: searchHandler)
		acronymsRoutes.get("first", use: getFirstHandler)
		acronymsRoutes.get("sorted", use: sortedHandler)
		acronymsRoutes.get(":acronymID", "user", use: getUserHandler)
		acronymsRoutes.post(":acronymID", "categories", ":categoryID", use: addCategoriesHandler)
		acronymsRoutes.get(":acronymID", "categories", use: getCategoriesHandler)
		acronymsRoutes.delete(":acronymID", "categories", ":categoryID", use: removeCategoriesHandler)
		
	}
	
	// define the functions
	@Sendable func getAllHandler(_ req: Request) -> EventLoopFuture<[Acronym]> {
		Acronym.query(on: req.db).all()
	}
	
	@Sendable func createHandler(_ req: Request) throws -> EventLoopFuture<Acronym> {
		let data = try req.content.decode(CreateAcronymData.self)
		
		let acronym = Acronym(
			short: data.short,
			long: data.long,
			userID: data.userID)
		return acronym.save(on: req.db).map { acronym }
	}
	
	@Sendable func getHandler(_ req: Request) -> EventLoopFuture<Acronym> {
		Acronym.find(req.parameters.get("acronymID"), on: req.db)
			.unwrap(or: Abort(.notFound))
	}
	
	@Sendable func updateHandler(_ req: Request) throws -> EventLoopFuture<Acronym> {
		let updateData = try req.content.decode(CreateAcronymData.self)
		return Acronym.find(req.parameters.get("acronymID"), on: req.db)
			.unwrap(or: Abort(.notFound))
			.flatMap { acronym in
				acronym.short = updateData.short
				acronym.long = updateData.long
				acronym.$user.id = updateData.userID
				return acronym.save(on: req.db).map {
					acronym
				}
			}
	}
	
	@Sendable func searchHandler(_ req: Request) throws -> EventLoopFuture<[Acronym]> {
		guard let searchTerm = req.query[String.self, at: "term"] else {
			throw Abort(.badRequest)
		}
		return Acronym.query(on: req.db).group(.or) { or in
			or.filter(\.$short == searchTerm)
			or.filter(\.$long == searchTerm)
		}.all()
	}
	
	@Sendable func getFirstHandler(_ req: Request) -> EventLoopFuture<Acronym> {
		return Acronym.query(on: req.db).first()
			.unwrap(or: Abort(.notFound))
	}
	
	@Sendable func sortedHandler(_ req: Request) -> EventLoopFuture<[Acronym]> {
		return Acronym.query(on: req.db).sort(\.$short, .ascending).all()
	}
	
	@Sendable func getUserHandler(_ req: Request) -> EventLoopFuture<User> {
		Acronym.find(req.parameters.get("acronymID"), on: req.db)
			.unwrap(or: Abort(.notFound))
			.flatMap { acronym in
				acronym.$user.get(on: req.db)
			}
	}
	
	@Sendable func addCategoriesHandler(_ req: Request) -> EventLoopFuture<HTTPStatus> {
		// define two props to query the db and get the acronym and category
		let acronymQuery = Acronym.find(req.parameters.get("acronymID"), on: req.db)
			.unwrap(or: Abort(.notFound))
		let categoryQuery = Category.find(req.parameters.get("categoryID"), on: req.db)
			.unwrap(or: Abort(.notFound))
		// and(_:) to wait for both futures
		return acronymQuery.and(categoryQuery)
			.flatMap { acronym, category in
				acronym
					.$categories
				// sets up the relationship between acronym and category, it creates the pivot model and saves it in the db
					.attach(category, on: req.db)
					.transform(to: .created)
			}
	}
	
	@Sendable func getCategoriesHandler(_ req: Request) -> EventLoopFuture<[Category]> {
		Acronym.find(req.parameters.get("acronymID"), on: req.db)
			.unwrap(or: Abort(.notFound))
			.flatMap { acronym in
				// Use the new property wrapper to get the categories. Then use a Fluent query to return all the categories.
				acronym.$categories.query(on: req.db).all()
			}
	}
	
	@Sendable func deleteHandler(_ req: Request) -> EventLoopFuture<HTTPStatus> {
		Acronym.find(req.parameters.get("acronymID"), on: req.db)
			.unwrap(or: Abort(.notFound))
			.flatMap { acronym in
				acronym.delete(on: req.db)
					.transform(to: .noContent)
			}
	}
	
	@Sendable func removeCategoriesHandler(_ req: Request) -> EventLoopFuture<HTTPStatus> {
		let acronymQuery = Acronym.find(req.parameters.get("acronymID"), on: req.db)
			.unwrap(or: Abort(.notFound))
		let categoryQuery = Category.find(req.parameters.get("categoryID"), on: req.db)
			.unwrap(or: Abort(.notFound))
		return acronymQuery.and(categoryQuery)
			.flatMap { acronym, category in
				acronym
					.$categories
					.detach(category, on: req.db)
					.transform(to: .noContent)
			}
	}
	
}

// DTO, or the JSON we expect from the client
struct CreateAcronymData: Content {
	let short: String
	let long: String
	let userID: UUID
}
 
