import Vapor
import Fluent

// defines the class that conforms to Model
final class Acronym: Model {
    // this is the name of the table in the db
    static let schema = "acronyms"
    
    // this is an optional ID, this tells fluent what to use to search the model in the db
    @ID
    var id: UUID?
    
    // the field prop is a generic wrapper
    @Field(key: "short")
    var short: String
    
    @Field(key: "long")
    var long: String
    
    // empty initialiser (required by model)
    init() {}
    
    // the initialiser to create the model
    init(id: UUID? = nil, short: String, long: String) {
        self.id = id
        self.short = short
        self.long = long
    }
}

extension Acronym: Content {}
