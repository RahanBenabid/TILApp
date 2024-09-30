import Fluent

// we define the new type
struct CreateAcronym: Migration {
	/*
    // this part below is required by miration, this metthod is called when you run it
    func prepare(on database: Database) -> EventLoopFuture<Void> {      
        // the table name, must match the schema from the model
        database.schema("acronyms")
        // we define the id column
            .id()
        // we define the other 2 columns, mark it as a required string, just like in the model
            .field("short", .string, .required)
            .field("long", .string, .required)
			// adds a new column for the User
						.field("userID", .uuid, .required, .references("users", "id"))
        
			// create the table
            .create()
    }
	 */
	
	func prepare(on database: any Database) -> EventLoopFuture<Void> {
		database.schema(Acronym.v30092024.schemaName)
			.id()
			.field(Acronym.v30092024.short, .string, .required)
			.field(Acronym.v30092024.long, .string, .required)
			.field(Acronym.v30092024.userID, .uuid, .required, .references(User.v20240929.schemaName, User.v20240929.id))
			.create()
		
	}
    
    // also required by Migration, will be called on revert, this deleltes the referenced table
    func revert(on database: Database) -> EventLoopFuture<Void> {
			database.schema(Acronym.v30092024.schemaName).delete()
    }
}

extension Acronym {
	enum v30092024 {
		static let schemaName = "acronyms"
		static let id = FieldKey(stringLiteral: "id")
		static let short = FieldKey(stringLiteral: "short")
		static let long = FieldKey(stringLiteral: "long")
		static let userID = FieldKey(stringLiteral: "userID")
	}
}
