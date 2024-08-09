import Foundation

struct AcronymRequest {
	let resource: URL
	
	// sets the resource prop to the URL for that acronym
	init(acronymID: UUID) {
		let resourceString = "http://localhost:8080/api/acronyms/\(acronymID)"
		guard let resourceURL = URL(string: resourceString) else {
			fatalError("unable to create URL")
		}
		self.resource = resourceURL
	}
	
	// get the acronym's user
	func getUser(
		completion: @escaping (
			Result<User, ResourceRequestError>
		) -> Void
	) {
		// to get the acronym's user
		let url = resource.appendingPathComponent("user")
		
		// create a URLSessionDataTask to fetch the data
		let dataTask = URLSession.shared
			.dataTask(with: url) { data, _, _ in
				// check if the data is not nil
				guard let jsonData = data else {
					completion(.failure(.noData))
					return
				}
				do {
					// decode the data into a User object
					let user  = try JSONDecoder()
						.decode(User.self, from: jsonData)
					completion(.success(user))
				} catch {
					// handle decoding error
					completion(.failure(.decodingError))
				}
			}
		// start the network task
		dataTask.resume()
	}
	
	// get the acronym's category
	func getCategories(
		completion: @escaping (
			Result<[Category], ResourceRequestError>
		) -> Void
	) {
		let url = resource.appendingPathComponent("categories")
		let dataTask = URLSession.shared
			.dataTask(with: url) { data, _,  _ in
				guard let jsonData = data else {
					completion(.failure(.noData))
					return
				}
				do {
					let categories = try JSONDecoder()
						.decode([Category].self, from: jsonData)
					completion(.success(categories))
				} catch {
					completion(.failure(.decodingError))
				}
			}
		dataTask.resume()
	}
	
	func update(
		with updateData: CreateAcronymData,
		completion: @escaping (
			Result<Acronym, ResourceRequestError>
		) -> Void
	) {
		do {
			// configure the Request, body, method and all
			var urlRequest = URLRequest(url: resource)
			urlRequest.httpMethod = "PUT"
			urlRequest.httpBody = try JSONEncoder().encode(updateData)
			urlRequest.addValue(
				"application/json",
				forHTTPHeaderField: "Content-Type")
			let dataTask = URLSession.shared
				.dataTask(with: urlRequest) { data, response, _ in
					// make sure the response is 200
					guard
						let httpResponse = response as? HTTPURLResponse,
						httpResponse.statusCode == 200,
						let jsonData = data
					else {
						completion(.failure(.noData))
						return
					}
					
					do {
						// Decode the response body into an acronym and call the completion dandler
						let acronym = try JSONDecoder().decode(Acronym.self, from: jsonData)
						completion(.success(acronym))
					} catch {
						completion(.failure(.decodingError))
					}
				}
			dataTask.resume()
		} catch {
			completion(.failure(.encodingError))
		}
	}
	
	func delete() {
		// create urlRequest and set the Method
		var urlRequest = URLRequest(url: resource)
		urlRequest.httpMethod = "DELETE"
		// Create a data task for the request using the shared URLSession and send the request
		let dataTask = URLSession.shared.dataTask(with: urlRequest)
		dataTask.resume()
	}
}
