import Vapor
import Fluent

// defines the class that conforms to Model
final class Acronym: Model {
	// this is the name of the table in the db
	static let schema = Acronym.v30092024.schemaName
	
	// this is an optional ID, this tells fluent what to use to search the model in the db
	@ID
	var id: UUID?
	
	// the field prop is a generic wrapper
	@Field(key: Acronym.v30092024.short)
	var short: String
	
	@Field(key: Acronym.v30092024.long)
	var long: String
	
	@Parent(key: "userID")
	var user: User
	
	@Siblings(
		through: AcronymCategoryPivot.self,
		from: \.$acronym,
		to: \.$category)
	var categories: [Category]
	
	// empty initialiser (required by model)
	init() {}
	
	// the initialiser to create the model
	init(id: UUID? = nil, short: String, long: String, userID: User.IDValue) {
		self.id = id
		self.short = short
		self.long = long
		self.$user.id = userID
	}
}

extension Acronym: Content {}
