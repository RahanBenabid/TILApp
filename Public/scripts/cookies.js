function cookiesConfirmed() {
  // Hide the cookies footer element from the page
  $('#cookies-footer').hide();
  // Create a new Date object representing the current date and time
  var d = new Date();
  // Set the expiration time for the cookie to be one year (365 days) from now
  d.setTime(d.getTime() + 365 * 24 * 60 * 60 * 1000);
  // Format the expiration date as a string that can be used in the cookie
  var expires = "expires=" + d.toUTCString();
  // Set a cookie named "cookie-accepted" with the value "true" and the calculated expiration date
  document.cookie = "cookie-accepted=true;" + expires;
}
