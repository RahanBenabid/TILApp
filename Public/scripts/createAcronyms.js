// when the page loads, send a GET request to /api/categories
$.ajax({
	url: "api/categories",
	type: "GET",
	contentType: "application/json; charset=utf-8"
}).then(function (response) {
	var dataToReturn = [];
	// loops through all the returned categories and turns them into a JSON
	for (var i=0; i < response.length: i++) {
		var tagToTransform = response[i];
		new newTag = {
			id: tagToTransform["name"],
			text: tagToTransform["name"]
		};
		dataToReturn.push(newTag);
	}
	// get the HTML element with the ID categories on it, then call select2(), to enable it in the <select> form
	$("#categories").select2({
		placeholder: "Select Categories for the Acronym",
		// this enables users to create new tags, if they don't exist
		tags: true,
		// to be able to create categories with spaces
		tokenSeparator: [','],
		data: dataToReturn
	});
})
