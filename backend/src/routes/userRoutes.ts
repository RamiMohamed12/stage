import express from 'express';
import { Role } from '../models/Users';

// Import Controllers
import {
    signupUser,
    signupAdmin,
    loginUser,
    loginAdmin,
    getAllUsers,
    getUserById,
    updateUser,
    deleteUser
} from '../controllers/userController'; 

// Import Validation Middleware & Validator
import {
    validateSignup,
    validateLogin,
    validateUpdateUser,
    validateUserId 
} from '../middleware/validators/userValidators'; 

// Import General Validation Error Handler
import { handleValidationErrors } from '../middleware/validationMiddleware';

// Import Auth Middleware
import { authenticateToken, checkRole } from '../middleware/authMiddleware'; 

const router = express.Router();


// Create a new user
router.post(
    '/signup',
    validateSignup,       
    handleValidationErrors, 
    signupUser            
);

// Create a new admin user
router.post(
    '/admin/signup',
    validateSignup,       
    handleValidationErrors, 
    signupAdmin           
);

// Authenticate a user and get a token
router.post(
    '/login',
    validateLogin,       
    handleValidationErrors, 
    loginUser             
);

// Authenticate an admin and get a token
router.post(
    '/admin/login',
    validateLogin,       
    handleValidationErrors, 
    loginAdmin            
);

// Get all users (Admin only)
router.get(
    '/',
    authenticateToken,    
    checkRole([Role.ADMIN]),
    getAllUsers
);

// Get a specific user by Id 
router.get(
    '/:id',
    authenticateToken,   
    validateUserId,       
    handleValidationErrors, 
    checkRole([Role.ADMIN, Role.USER]),
    getUserById           
);

//  Update a specific user 
router.put(
    '/:id',
    authenticateToken,    
    validateUserId,       
    validateUpdateUser,   
    handleValidationErrors, 
    checkRole([Role.ADMIN, Role.USER]),
    updateUser
);

// Delete a specific user 
router.delete(
    '/:id',
    authenticateToken,    
    validateUserId,      
    handleValidationErrors, 
    checkRole([Role.USER]), 
    deleteUser           
);

export default router;