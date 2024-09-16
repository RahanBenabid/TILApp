## Introduction

TILApp is a mainly backend app I'm using to learn backend using *Vapor*, the swift backend framework, I try to include as many functionalities as i possibly can, such as:
- hashing the passwords for a more secure database
- Google OAuth
- GitHub OAuth
- Apple Authentication (does not work because I don't have a paid Apple dev account, but the work was implemented in a seperate branch called *SIWA*)
- Password Reset using the email, also doesn't work, I'm using SendGrid, and had issues creating an account, here is the `.env` file template

  ```.env
  GOOGLE_CALLBACK_URL=http://127.0.0.1:8080/oauth/google
  GOOGLE_CLIENT_ID=<YOUR_GOOGLE_CLIENT_ID>
  GOOGLE_CLIENT_SECRET=<YOUR_GOOGLE_CLIENT_SECRET>

  GITHUB_CALLBACK_URL=http://127.0.0.1:8080/oauth/github
  GITHUB_CLIENT_ID=<YOUR_GITHUB_CLIENT_ID>
  GITHUB_CLIENT_SECRET=<YOUR_GITHUB_CLIENT_SECRET>

  IOS_APPLICATION_IDENTIFIER=com.example.appname
  SIWA_REDIRECT_URL=https://<YOUR_NGROK_DOMAIN>/login/siwa/callback

  SENDGRID_API_KEY=<YOUR_API_KEY>
  ```
- some other minor stuff not worth mentioning but that help with the UX

## Requirements

- macOS
- [Swift 5.3+](https://swift.org/download/)
- [Vapor 4](https://vapor.codes/)
- [PostgreSQL](https://www.postgresql.org/) (or any other database supported by Fluent, in this version i'm using postgres and configuring everything with it)

## Installation

1. **Clone the repository**
    ```bash
    git clone https://github.com/RahanBenabid/TILApp.git
    cd TILApp
    ```

2. **Install dependencies**
    ```bash
    swift package update
    swift build
    ```
    on mac just open the folder using Xcode, it will download all the dependencies

3. **Start the server**
    ```bash
    vapor run serve
    ```

Or just skip all this if you're on mac using Xcode, open the project, wait for the Dependencies to download, create a docker container, and run, here's the docker container command:

```bash
docker rm -f postgres
docker run --name postgres \
  -e POSTGRES_DB=vapor_database \
  -e POSTGRES_USER=vapor_username \
  -e POSTGRES_PASSWORD=vapor_password \
  -p 5432:5432 -d postgres
```
run as such, don't replace anything unless you know what you're doing
