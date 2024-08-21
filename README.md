## Introduction

TILApp is just and app i'm using to learn Vapor

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

3. **Configure environment variables**
    Create a `.env` file in the root directory and add your database configuration:
    ```plaintext
    DATABASE_URL=postgres://username:password@localhost:5432/tilapp
    ```

5. **Start the server**
    ```bash
    vapor run serve
    ```
    or just run using Xcode
    
    I added some iOS app (that you should run using Xcode separately) and even a web app, in [localhost://127.0.0.1:8080]