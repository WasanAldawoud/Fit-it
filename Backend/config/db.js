// 1. Import the 'pg' library.
// This is the driver that lets this Node.js app talk to PostgreSQL.
import pg from "pg";

// 2. Import the 'dotenv' library.
// This allows us to read secret passwords from the .env file.
import env from "dotenv";

// 3. Load the environment variables.
// This reads the .env file and saves the values (like PG_PASSWORD) into 'process.env'.
env.config();

// 4. Create a new Connection Pool.
// We use a 'Pool' to manage multiple connections at once.
// This prevents the server from crashing when many users try to connect.
const db = new pg.Pool({
  // 5. Set the database username using the value from the .env file.
  user: process.env.PG_USER,

  // 6. Set the server address (usually 'localhost') from the .env file.
  host: process.env.PG_HOST,

  // 7. Set the specific database name to connect to from the .env file.
  database: process.env.PG_DATABASE,

  // 8. Set the secret password for the database from the .env file.
  password: process.env.PG_PASSWORD,

  // 9. Set the port number (default is 5432) from the .env file.
  port: process.env.PG_PORT,
});

// 10. Export this configured 'db' connection.
// Other files can now import this 'db' variable to run SQL queries.
export default db; // Makes db available everywhere (controllers, passport)