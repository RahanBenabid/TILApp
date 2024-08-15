import Vapor
import Leaf

struct WebsiteController: RouteCollection {
	func boot(routes: RoutesBuilder) throws {
		routes.get(use: indexHandler)
		routes.get("acronyms", ":acronymID", use: acronymHandler)
		routes.get("users", ":userID", use: userHandler)
		routes.get("users", use: allUserHandler)
		routes.get("categories", use: allCategoriesHandler)
		routes.get("categories", ":categoryID", use: categoryHandler)
		routes.get("acronyms", "create", use: createAcronymHandler)
		routes.post("acronyms", "create", use: createAcronymPostHandler)
		routes.get("acronyms", ":acronymID", "edit", use: editAcronymHandler)
		routes.post("acronyms", ":acronymID", "edit", use: editAcronymPostHandler)
		routes.post("acronyms", ":acronymID", "delete", use: deleteAcronymHandler)
	}
	
	@Sendable func indexHandler(_ req: Request) -> EventLoopFuture<View> {
		Acronym.query(on: req.db).all().flatMap { acronyms in
			// create an Encodable IndexTitle containing the title we want
			let context = IndexContext(title: "Home Page", acronyms: acronyms)
			// pass it as a second parameter
			return req.view.render("index", context)
		}
	}
	
	@Sendable func acronymHandler(_ req: Request) -> EventLoopFuture<View> {
		Acronym.find(req.parameters.get("acronymID"), on: req.db)
			.unwrap(or: Abort(.notFound))
			.flatMap { acronym in
				let userFuture = acronym.$user.get(on: req.db)
				let categoriesFuture = acronym.$categories.query(on: req.db).all()
				return userFuture.and(categoriesFuture)
					.flatMap { user, categories in
						let context = AcronymContext(
							title: acronym.short,
							acronym: acronym,
							user: user,
							categories: categories)
						return req.view.render("acronym", context)
					}
			}
	}
	
	@Sendable func userHandler(_ req: Request) -> EventLoopFuture<View> {
		User.find(req.parameters.get("userID"), on: req.db)
			.unwrap(or: Abort(.notFound))
			.flatMap { user in
				user.$acronyms.get(on: req.db).flatMap { acronyms in
					let context = UserContext(title: "user.name",
																		user: user,
																		acronyms: acronyms)
					return req.view.render("user", context)
				}
			}
	}
	
	@Sendable func allUserHandler(_ req: Request) -> EventLoopFuture<View> {
		User.query(on: req.db)
			.all()
			.flatMap { users in
				let context = AllUsersContext(title: "All Users", users: users)
				return req.view.render("allUsers", context)
			}
	}
	
	@Sendable func allCategoriesHandler(_ req: Request) -> EventLoopFuture<View> {
		Category.query(on: req.db).all().flatMap { categories in
			let context = AllCategoriesContext(categories: categories)
			return req.view.render("allCategories", context)
		}
	}
	
	@Sendable func categoryHandler(_ req: Request) -> EventLoopFuture<View> {
		Category.find(req.parameters.get("categoryID"), on: req.db)
			.unwrap(or: Abort(.notFound))
			.flatMap { category in
				category.$acronyms.get(on: req.db).flatMap { acronyms in
					let context = CategoryContext(title: category.name,
																				category: category,
																				acronyms: acronyms)
					return req.view.render("category", context)
				}
			}
	}
	
	@Sendable func createAcronymHandler(_ req: Request) -> EventLoopFuture<View> {
		User.query(on: req.db).all().flatMap { users in
			let context = CreateAcronymContext(users: users)
			return req.view.render("createAcronym", context)
		}
	}
	
	@Sendable func createAcronymPostHandler(_ req: Request) throws -> EventLoopFuture<Response> {
		let data = try req.content.decode(CreateAcronymFormData.self)
		let acronym = Acronym(
			short: data.short,
			long: data.long,
			userID: data.userID)
		
		return acronym.save(on: req.db).flatMap {
			// ensures the ID is set or else throws a server error
			guard let id = acronym.id else {
				return req.eventLoop.future(error: Abort(.internalServerError))
			}
			var categySaves: [EventLoopFuture<Void>] = []
			for category in data.categories ?? [] {
				categySaves.append(
					Category.addCategory(category, to: acronym, on: req))
			}
			let redirect = req.redirect(to: "/acronyms/\(id)")
			return categySaves.flatten(on: req.eventLoop)
				.transform(to: redirect)
		}
	}
	
	@Sendable func editAcronymHandler(_ req: Request) -> EventLoopFuture<View> {
		let acronymFuture = Acronym
			.find(req.parameters.get("acronymID"), on: req.db)
			.unwrap(or: Abort(.notFound))
		
		let userQuery = User.query(on: req.db).all()
		
		return acronymFuture.and(userQuery)
			.flatMap { acronym, users in
				acronym.$categories.get(on: req.db).flatMap { categories in
					let context = EditAcronymContext(
						acronym: acronym,
						users: users,
						categories: categories)
					return req.view.render("createAcronym", context)
				}
			}
	}
	
	@Sendable func editAcronymPostHandler(_ req: Request) throws -> EventLoopFuture<Response> {
		// now the request decodes a CreateAcronymFormData
		let updateData = try req.content.decode(CreateAcronymFormData.self)
		return Acronym
			.find(req.parameters.get("acronymID"), on: req.db)
			.unwrap(or: Abort(.notFound)).flatMap { acronym in
				acronym.short = updateData.short
				acronym.long = updateData.long
				acronym.$user.id = updateData.userID
				guard let id = acronym.id else {
					return req.eventLoop
						.future(error: Abort(.internalServerError))
				}
				// chaining futures, this returns all the acronym's categories
				return acronym.save(on: req.db).flatMap {
					// get the categories from the db
					acronym.$categories.get(on: req.db)
				}.flatMap { existingCategories in
					// creates an array of categories
					let existingStringArray = existingCategories.map {
						$0.name
					}
					// creates a Set for the categories and the categories supplied with the request
					let existingSet = Set<String>(existingStringArray)
					let newSet = Set<String>(updateData.categories ?? [])
					// calculates the categories to add and to remove to the acronym
					let categoriesToAdd = newSet.subtracting(existingSet)
					let categoriesToRemove = existingSet
						.subtracting(newSet)
					// creates an array of category operation results
					var categoryResults: [EventLoopFuture<Void>] = []
					// loop through the cats and sets up the relationship
					for newCategory in categoriesToAdd {
						categoryResults.append(
							Category.addCategory(
								newCategory,
								to: acronym,
								on: req))
					}
					// loops though the category names to remove from the acronym
					for categoryNameToRemove in categoriesToRemove {
						// Get the Category object from the name of the category to remove
						let categoryToRemove = existingCategories.first {
							$0.name == categoryNameToRemove
						}
						// if the cat object exists, use detach to remove the relationship
						if let category = categoryToRemove {
							categoryResults.append(
								acronym.$categories.detach(category, on: req.db))
						}
					}
					let redirect = req.redirect(to: "/acronyms/\(id)")
					// Flatten all the future category results. Transform the result to redirect to the updated acronym’s page
					return categoryResults.flatten(on: req.eventLoop)
						.transform(to: redirect)
				}
			}
	}
	
	@Sendable func deleteAcronymHandler(_ req: Request) -> EventLoopFuture<Response> {
		Acronym
			.find(req.parameters.get("acronymID"), on: req.db)
			.unwrap(or: Abort(.notFound))
			.flatMap { acronym in
				acronym.delete(on: req.db)
					.transform(to: req.redirect(to: "/"))
			}
	}
	
	
	
	
	
	
	
	
	
	
	
}

struct IndexContext: Encodable {
	let title: String
	let acronyms: [Acronym]
}

struct AcronymContext: Encodable {
	let title: String
	let acronym: Acronym
	let user: User
	let categories: [Category]
}

struct UserContext: Encodable {
	let title: String
	let user: User
	let acronyms: [Acronym]
}

struct AllUsersContext: Encodable {
	let title: String
	let users: [User]
}

struct AllCategoriesContext: Encodable {
	let title = "All Categories"
	let categories: [Category]
}

struct CategoryContext: Encodable {
	let title: String
	let category: Category
	let acronyms: [Acronym]
}

struct CreateAcronymContext: Encodable {
	let title = "Create an acronym" // static because the title doesn't change
	let users: [User]
}

struct EditAcronymContext: Encodable {
	let title = "Edit Acronym"
	let acronym: Acronym
	let users: [User]
	let editing = true
	let categories: [Category]
}

struct CreateAcronymFormData: Content {
	let userID: UUID
	let short: String
	let long: String
	let categories: [String]?
}
