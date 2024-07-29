import Fluent

// we define the new type
struct CreateAcronym: Migration {
    // this part below is required by miration, this metthod is called when you run it
    func prepare(on database: Database) -> EventLoopFuture<Void> {      
        // the table name, must match the schema from the model
        database.schema("acronyms")
        // we define the id column
            .id()
        // we define the other 2 columns, mark it as a required string, just like in the model
            .field("short", .string, .required)
            .field("long", .string, .required)
        // create the table
            .create()
    }
    
    // also required by Migration, will be called on revert, this deleltes the referenced table
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("acronyms").delete()
    }
}
