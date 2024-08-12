import Vapor
import Leaf

struct WebsiteController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    routes.get(use: indexHandler)
		routes.get("acronyms", ":acronymID", use: acronymHandler)
  }
  
  @Sendable func indexHandler(_ req: Request) -> EventLoopFuture<View> {
		Acronym.query(on: req.db).all().flatMap { acronyms in
			// ensure the acronym isn't empty
			let acronymsData = acronyms.isEmpty ? nil : acronyms
			// create an Encodable IndexTitle containing the title we want
			let context = IndexContext(title: "Home Page", acronyms: acronymsData)
			// pass it as a second parameter
			return req.view.render("index", context)
		}
  }
	
	@Sendable func acronymHandler(_ req: Request) -> EventLoopFuture<View> {
		Acronym.find(req.parameters.get("acronymID"), on: req.db)
			.unwrap(or: Abort(.notFound))
			.flatMap { acronym in
				acronym.$user.get(on: req.db).flatMap { user in
					let context = AcronymContext(title: acronym.short,
																			 acronym: acronym,
																			 user: user)
					return req.view.render("acronym", context)
				}
			}
	}
}

struct IndexContext: Encodable {
  let title: String
	let acronyms: [Acronym]?
}

struct AcronymContext: Encodable {
	let title: String
	let acronym: Acronym
	let user: User
}
