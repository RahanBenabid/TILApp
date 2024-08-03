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
		
	}
	
	// define the functions
	@Sendable func getAllHandler(_ req: Request) -> EventLoopFuture<[Acronym]> {
		Acronym.query(on: req.db).all()
	}
	
	@Sendable func createHandler(_ req: Request) throws -> EventLoopFuture<Acronym> {
		let acronym = try req.content.decode(Acronym.self)
		return acronym.save(on: req.db).map { acronym }
	}
	
	@Sendable func getHandler(_ req: Request) -> EventLoopFuture<Acronym> {
		Acronym.find(req.parameters.get("acronymID"), on: req.db)
			.unwrap(or: Abort(.notFound))
	}
	
	@Sendable func updateHandler(_ req: Request) throws -> EventLoopFuture<Acronym> {
		let updatedAcronym = try req.content.decode(Acronym.self)
		return Acronym.find(req.parameters.get("acronymID"), on: req.db)
			.unwrap(or: Abort(.notFound))
			.flatMap { acronym in
				acronym.short = updatedAcronym.short
				acronym.long = updatedAcronym.long
				return acronym.save(on: req.db).map {
					acronym
				}
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
	
}
