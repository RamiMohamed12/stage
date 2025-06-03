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
    
    // Valid mysql2 options only
    timezone: '+00:00',
    charset: 'utf8mb4',
    
    // InnoDB specific settings
    typeCast: function (field, next) {
        if (field.type === 'TINY' && field.length === 1) {
            return (field.string() === '1'); // Convert TINYINT(1) to boolean
        }
        return next();
    }
});  

export default pool;
