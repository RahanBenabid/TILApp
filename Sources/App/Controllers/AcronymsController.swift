import Vapor
import Fluent

struct AcronymsController: RouteCollection {
	func boot(routes: RoutesBuilder) throws {
		func getAllHandler(_ req: Request) -> EventLoopFuture<[Acronym]> {
			Acronym.query(on: req.db).all()
		}
				
		// registering the routes
		routes.get("api", "acronyms", use: getAllHandler)
	}
}
