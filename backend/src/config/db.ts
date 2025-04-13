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

// this is just a test 

export default pool; 
