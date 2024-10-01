# TILApp

## Introduction

TILApp is a backend-focused application developed to explore and learn the Vapor framework, a server-side Swift web application framework. This project serves as a comprehensive learning tool, incorporating various backend functionalities and best practices.
The User Interface is nothing crazy, but I'm more focused on implementing every major backend functionality a website should have.

### Key Features

- **Secure Password Hashing**: Implemented for enhanced database security.
- **OAuth Integration**:
	- Google OAuth
	- GitHub OAuth
- **Apple Authentication**: Implemented in a separate branch (`SIWA`) but currently inactive due to Apple Developer account limitations (needs a paid Apple Developer account).
- **Password Reset via Email**: Functionality in place, but I didn't test it due to SendGrid account setup issues.
- **Caching**: Ended up taking this functionality to another smaller project in a private repository, since it ended up making the app a little buggy.
- **Additional UX Enhancements**: Various minor features to improve user experience.

## Requirements

- macOS
- [Swift 5][1]
- [Vapor 4][2]
- [PostgreSQL][3] (or any Fluent-supported database, mine uses PostgreSQL)

## Installation

### Option 1: Xcode (macOS only)

1. Open the project in Xcode.
2. Wait for dependencies to download automatically.
3. Set up a Docker container (see below).
4. Run the project.

### Option 2: Command Line

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

3. **Start the server**
```bash
vapor run server
```

## Docker Setup

To set up a PostgreSQL database using Docker:

```bash
docker rm -f postgres
docker run --name postgres \
  -e POSTGRES_DB=vapor_database \
  -e POSTGRES_USER=vapor_username \
  -e POSTGRES_PASSWORD=vapor_password \
  -p 5432:5432 -d postgres
```

**Note**: Only modify these settings if you're familiar with Docker and database configuration.

## Environment Configuration

Create a `.env` file in the project root with the following template:

```env
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

Replace placeholder values with your actual credentials.

## iOS Companion App

An iOS companion app for this project is available in a separate repository: [TILiOS][4]. While functional, it may not be as refined as the web interface.

## Contributing

Contributions, issues, and feature requests are welcome. Feel free to check [issues page][5] if you want to contribute.

[1]:	https://swift.org/download/
[2]:	https://vapor.codes/
[3]:	https://www.postgresql.org/
[4]:	https://github.com/RahanBenabid/TILiOS
[5]:	https://github.com/RahanBenabid/TILApp/issues
