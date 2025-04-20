import { body } from 'express-validator';

export const validateDecujusVerificationInput = [
    body('pension_number')
        .notEmpty().withMessage('Pension number is required.')
        .isLength({ min: 9, max: 9 }).withMessage('Pension number must be exactly 9 characters long.') // Adjust length as needed
        .trim()
        .escape(), // Basic sanitization

    body('first_name')
        .optional({ checkFalsy: true }) // Treat empty strings as optional
        .trim()
        .escape(),

    body('last_name')
        .optional({ checkFalsy: true })
        .trim()
        .escape(),

    body('date_of_birth')
        .optional({ checkFalsy: true })
        .isISO8601().withMessage('Date of birth must be a valid date (YYYY-MM-DD).')
        .toDate(), // Convert valid string to Date object

    body('agency_id')
        .optional({ checkFalsy: true })
        .isInt({ min: 1 }).withMessage('Agency ID must be a positive integer.')
        .toInt() // Convert valid string/number to integer
];
