import mysql from 'mysql2/promise';
import dotenv from 'dotenv'; 

dotenv.config();

const pool = mysql.createPool({

    database: process.env.DB_DATABASE,
    user: process.env.DB_USER, 
    password: process.env.DB_PASSWORD,
    host: process.env.DB_HOST,
    port: Number(process.env.DB_PORT),
    
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0,

});  

// this is just a test to see if the connection is working
pool.getConnection() 
    .then(connection => {
        console.log("Connected to the database"); 
        connection.release(); // release the connection back to the pool
    })
    .catch(err => {
        console.log("Error connecting to the database: ", err);
        process.exit(1); // exit the process with failure
    }); 


export default pool; 
