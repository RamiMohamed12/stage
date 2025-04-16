import { body, param } from 'express-validator';
import { Role } from '../../models/Users'; // Import Role enum for validation

// Validation rules for user signup
export const validateSignup = [
    body('email')
        .isEmail().withMessage('Must be a valid email address')
        .normalizeEmail(), // Sanitizes email format
    body('password')
        .isLength({ min: 8 }).withMessage('Password must be at least 8 characters long')

        .trim(), // Remove leading/trailing whitespace
    body('first_name')
        .notEmpty().withMessage('First name is required')
        .trim()
        .escape(), // Prevent HTML/script injection
    body('last_name')
        .notEmpty().withMessage('Last name is required')
        .trim()
        .escape(), // Prevent HTML/script injection
    body('role')
    .not()
    .exists()
    .withMessage('Role cannot be specified during signup'),
];

// Validation rules for user login
export const validateLogin = [
    body('email')
        .isEmail().withMessage('Must be a valid email address')
        .normalizeEmail(),
    body('password')
        .notEmpty().withMessage('Password is required')
];

// Validation rules for updating a user
export const validateUpdateUser = [
    // Validate the user ID in the URL parameters
    param('id')
        .isInt({ gt: 0 }).withMessage('User ID must be a positive integer'),
    // Optional fields in the body
    body('email')
        .optional()
        .isEmail().withMessage('Must be a valid email address')
        .normalizeEmail(),
    body('password')
        .optional()
        .isLength({ min: 8 }).withMessage('Password must be at least 8 characters long')
        // Optional: Add complexity rules if allowing password update here
        .trim(),
    body('first_name')
        .optional()
        .notEmpty().withMessage('First name cannot be empty if provided')
        .trim()
        .escape(),
    body('last_name')
        .optional()
        .notEmpty().withMessage('Last name cannot be empty if provided')
        .trim()
        .escape(),
    body('role')
        .optional()
        .isIn(Object.values(Role)).withMessage(`Invalid role. Must be one of: ${Object.values(Role).join(', ')}`)
];

// Validation rule specifically for checking the user ID parameter
export const validateUserId = [
    param('id')
        .isInt({ gt: 0 }).withMessage('User ID must be a positive integer')
];