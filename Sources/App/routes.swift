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
}
