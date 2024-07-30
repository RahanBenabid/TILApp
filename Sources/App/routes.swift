import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get { req async in
        "It works!"
    }

    app.get("hello") { req async -> String in
        "Hello, world!" 
    }
    
    // the route api/acronyms accepts a POST req and returns an EvenLoopFuture<Acronym> which means it returns the acronym once its saved
    app.post("api", "acronyms") { req -> EventLoopFuture<Acronym> in
        // using Codable, we can decode the request JSON data into an Acronym
        let acronym = try req.content.decode(Acronym.self)
        // save the model
        return acronym.save(on: req.db).map {
            // returns the acronym when the save is complete and here we use .map
            acronym
        }
    }
	
	// get all the data
	app.get("api", "acronyms") { req -> EventLoopFuture<[Acronym]> in
		Acronym.query(on: req.db).all()
    }
	
	// gets the value in the request path
	app.get("api", "acronyms", ":acronymID") {
		req -> EventLoopFuture<Acronym> in
		// find() takes a UUID as a param
		Acronym.find(req.parameters.get("acronymID"), on: req.db)
			// since find() returns EventLoopFuture<Acronym?>, we handle this difference by adding unwrap()
			.unwrap(or: Abort(.notFound))
	}
	
	// update using the UUID
	app.put("api", "acronyms", ":acronymID") {
		req -> EventLoopFuture<Acronym> in
		// decode the request body
		let updatedAcronym = try req.content.decode(Acronym.self)
		// find the acronym with the specified UUID
		return Acronym.find(
			req.parameters.get("acronymID"),
			on: req.db)
		// returns an error if not found
		.unwrap(or: Abort(.notFound))
		// waits for the future to complete, flatMap  is used because the operation inside involves another asynchronous operation, saving the updated acronym to the database.
		.flatMap { acronym in
			acronym.short = updatedAcronym.short
			acronym.long = updatedAcronym.long
			return acronym.save(on: req.db).map {
				acronym
			}
		}
	}
	
	// delete operation that returns an HTTPStatus
	app.delete("api", "acronyms", ":acronymID") {
		req -> EventLoopFuture<HTTPStatus> in
		// exract the ID from the request
		Acronym.find(req.parameters.get("acronymID"), on: req.db)
			.unwrap(or: Abort(.notFound))
		
			// wait for the acronym to return from the database
			.flatMap { acronym in
				// deletes it
				acronym.delete(on: req.db)
					// trandforms the result into a 204 code: no result
					.transform(to: .noContent)
			}
	}
	
	app.get("api", "acronyms", "search") {
		req -> EventLoopFuture<[Acronym]> in
		// retrieve the search term from the URL query string
		guard let searchTerm = req.query[String.self, at: "term"] else {
			throw Abort(.badRequest)
		}
		// find all the acronyms whos short prop matches
		return Acronym.query(on: req.db)
			.filter(\.$short == searchTerm)
			.all()
	}
	// testin fork
}
