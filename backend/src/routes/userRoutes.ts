import express from 'express';
import { Role } from '../models/Users';

// Import Controllers
import {
    signupUser,
    loginUser,
    getAllUsers,
    getUserById,
    updateUser,
    deleteUser
} from '../controllers/userController'; // Adjust path if needed

// Import Validation Middleware & Validator
import {
    validateSignup,
    validateLogin,
    validateUpdateUser,
    validateUserId // Assuming you create this validator for param('id')
} from '../middleware/validators/userValidators'; // Adjust path if needed

// Import General Validation Error Handler
import { handleValidationErrors } from '../middleware/validationMiddleware'; // Adjust path if needed

// Import Auth Middleware
import { authenticateToken, checkRole } from '../middleware/authMiddleware'; // Adjust path if needed

const router = express.Router();

// --- Public Routes ---

// POST /api/users/signup - Create a new user
router.post(
    '/signup',
    validateSignup,       // Apply signup validation rules
    handleValidationErrors, // Check for validation errors
    signupUser            // Proceed to controller if validation passes
);

// POST /api/users/login - Authenticate a user and get a token
router.post(
    '/login',
    validateLogin,        // Apply login validation rules
    handleValidationErrors, // Check for validation errors
    loginUser             // Proceed to controller if validation passes
);


// --- Protected Routes (Require Authentication) ---

// GET /api/users - Get all users (Admin only)
router.get(
    '/',
    authenticateToken,    // Ensure user is logged in
    checkRole([Role.ADMIN]), // Ensure user is an Admin
    getAllUsers
);

// GET /api/users/:id - Get a specific user by ID (Admin or the user themselves)
router.get(
    '/:id',
    authenticateToken,    // Ensure user is logged in
    validateUserId,       // Validate the :id parameter is a positive integer
    handleValidationErrors, // Check for validation errors
    // Authorization: Allow Admin or User role initially. Controller handles specific user check.
    checkRole([Role.ADMIN, Role.USER]),
    getUserById           // Controller performs the final check (is user accessing self?)
);

// PUT /api/users/:id - Update a specific user (Admin or the user themselves)
router.put(
    '/:id',
    authenticateToken,    // Ensure user is logged in
    validateUserId,       // Validate the :id parameter
    validateUpdateUser,   // Validate request body for update (fields are optional)
    handleValidationErrors, // Check for validation errors
    // Authorization: Allow Admin or User role initially. Controller handles specific user check.
    checkRole([Role.ADMIN, Role.USER]),
    updateUser            // Controller performs final checks (is user updating self? prevent role change?)
);

// DELETE /api/users/:id - Delete a specific user (User themselves ONLY - NO ADMINS)
router.delete(
    '/:id',
    authenticateToken,    // Ensure user is logged in
    validateUserId,       // Validate the :id parameter
    handleValidationErrors, // Check for validation errors
    // Authorization: Allow ONLY the user themselves. Explicitly exclude Admin.
    checkRole([Role.USER]), // Only allow users with the USER role
    deleteUser            // Controller performs the final check (is user deleting self?)
);

export default router;