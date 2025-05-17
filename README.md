# Himachali Taxi - Backend

This is the backend server for the Himachali Taxi application. It handles user authentication, captain management, ride requests, location updates, and more.

## Project Structure

```
Backend/
├── config/         # Configuration files (database, socket.io)
├── controllers/    # Request handlers and business logic
├── middleware/     # Custom middleware (e.g., authentication)
├── models/         # Mongoose schemas and data models
├── routes/         # API route definitions
├── services/       # External service integrations (e.g., email)
├── uploads/        # Directory for user uploads (e.g., profile images) - Should be in .gitignore if not versioned
├── utils/          # Utility functions (OTP generation, email templates, logger)
├── .env.example    # Example environment variables file
├── .gitignore      # Specifies intentionally untracked files that Git should ignore
├── package.json    # Project metadata and dependencies
├── package-lock.json # Records exact versions of dependencies
└── server.js       # Main application entry point
```

## Prerequisites

*   [Node.js](https://nodejs.org/) (LTS version recommended, e.g., v18.x or v20.x)
*   [npm](https://www.npmjs.com/) (usually comes with Node.js)
*   [MongoDB](https://www.mongodb.com/) (either a local instance or a cloud-hosted solution like MongoDB Atlas)
*   A Git client

## Setup and Installation

1.  **Clone the repository (if you haven't already):**
    ```bash
    git clone https://github.com/KashishIndoria/Himachali_Taxi.git
    cd Himachali_Taxi/Backend
    ```

2.  **Install dependencies:**
    ```bash
    npm install
    ```

3.  **Set up environment variables:**
    *   Create a `.env` file in the `Backend` root directory.
    *   Copy the contents of `.env.example` (if you create one) or add the following variables, replacing the placeholder values with your actual configuration:
        ```env
        PORT=3000
        MONGODB_URI=your_mongodb_connection_string
        JWT_SECRET=your_very_strong_jwt_secret_key
        EMAIL_HOST=your_email_host
        EMAIL_PORT=your_email_port
        EMAIL_USER=your_email_user
        EMAIL_PASS=your_email_password
        NODE_ENV=development
        ```
    *   **`MONGODB_URI`**: Your MongoDB connection string.
    *   **`JWT_SECRET`**: A strong, random string for signing JSON Web Tokens.
    *   **`EMAIL_*`**: Credentials for your email sending service (if applicable).
    *   **`NODE_ENV`**: Set to `development` for local development, `production` for deployment.

## Available Scripts

In the `Backend` directory, you can run the following scripts:

*   **Start the server (development mode):**
    ```bash
    npm start
    ```
    This will typically start the server using `nodemon` if configured (for auto-restarts on file changes) or `node server.js`. Check your `package.json` for the exact command.

*   **Start the server (production mode):**
    (Assuming your `package.json` has a specific script or your `start` script handles `NODE_ENV=production` appropriately)
    ```bash
    npm start 
    ```
    or
    ```bash
    NODE_ENV=production npm start
    ```

## API Endpoints

(Consider adding a brief overview of major API endpoints or linking to API documentation if you have it, e.g., using Postman or Swagger/OpenAPI).

Example:
*   `POST /api/auth/user/signup` - User registration
*   `POST /api/auth/user/login` - User login
*   `POST /api/auth/captain/signup` - Captain registration
*   `POST /api/auth/captain/login` - Captain login
*   `GET /api/captains/profile/:captainId` - Get captain profile
*   ... and so on.

## Deployment

This backend can be deployed to various platforms like:
*   Render
*   Heroku
*   Azure App Service
*   AWS Elastic Beanstalk
*   Google App Engine

Ensure environment variables are set correctly on the deployment platform.

## Contributing

(Optional: Add guidelines if you plan to have others contribute to the project).

---

*This README is a template. Please update it with specific details relevant to your Himachali Taxi backend.*
