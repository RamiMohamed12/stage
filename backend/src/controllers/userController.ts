import { Request, Response, NextFunction } from "express";
import * as usersService from '../services/usersService'; // Import service functions
import { ServiceErorr } from '../services/usersService'; // Import custom error
import { hashPassword, comparePassword } from '../utils/passwordUtils'; // Import password utilities
import { generateToken, JwtPayload } from '../utils/jwtUtils'; // Import JWT utility and payload type
import { Role, Users, CreateUserInput, UpdateUserInput } from '../models/Users'; // Import models and types

export const signupUser = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const { email, password, first_name, last_name } = req.body;

        if (!password) {
            res.status(400).json({ message: 'Password is required for signup.' });
            return;
        }

        const password_hash = await hashPassword(password);

        const userData: CreateUserInput = {
            email,
            password_hash,
            first_name,
            last_name,
            role: Role.USER  // Explicitly set role to USER
        };

        const newUser = await usersService.createUser(userData);

        const { password_hash: _, ...userResponse } = newUser;
        res.status(201).json(userResponse);

    } catch (error: unknown) {
        if (error instanceof ServiceErorr) {
            res.status(error.statusCode).json({ message: error.message });
        } else if (error instanceof Error) {
            console.error("Signup Error:", error);
            res.status(500).json({ message: "An internal error occurred during signup.", error: error.message });
        } else {
            console.error("Signup Error (Unknown):", error);
            res.status(500).json({ message: "An unknown internal error occurred during signup." });
        }
    }
};

// Controller for user login
export const loginUser = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const { email, password } = req.body;

        // Find user by email
        const user = await usersService.getUserByEmail(email);

        // Check if user exists and password matches
        if (!user || !(await comparePassword(password, user.password_hash))) {
            res.status(401).json({ message: 'Invalid email or password.' });
            return; // Add return
        }

        // Generate JWT token
        const token = generateToken(user.user_id, user.role);

        // Send token back to client
        res.status(200).json({ token });
        // No return needed here (end of try block)

    } catch (error: unknown) {
        if (error instanceof ServiceErorr) {
            // Don't reveal specific service errors during login for security
            console.error("Login Service Error:", error);
            res.status(500).json({ message: "An internal error occurred during login." });
             // No return needed here
        } else if (error instanceof Error) {
            console.error("Login Error:", error);
            res.status(500).json({ message: "An internal error occurred during login.", error: error.message });
             // No return needed here
        } else {
            console.error("Login Error (Unknown):", error);
            res.status(500).json({ message: "An unknown internal error occurred during login." });
             // No return needed here
        }
    }
};

// Controller to get all users (Admin only)
export const getAllUsers = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    // Authorization already handled by checkRole([Role.ADMIN]) middleware
    try {
        const users = await usersService.getAllUsers();
        // Exclude password hashes from the response list
        const usersResponse = users.map(({ password_hash, ...user }) => user);
        res.status(200).json(usersResponse);
        // No return needed here
    } catch (error: unknown) {
        // Handle potential errors
        if (error instanceof ServiceErorr) {
            res.status(error.statusCode).json({ message: error.message });
             // No return needed here
        } else if (error instanceof Error) {
            console.error("GetAllUsers Error:", error);
            res.status(500).json({ message: "An internal error occurred.", error: error.message });
             // No return needed here
        } else {
            console.error("GetAllUsers Error (Unknown):", error);
            res.status(500).json({ message: "An unknown internal error occurred." });
             // No return needed here
        }
    }
};

// Controller to get a user by ID (Admin or self)
export const getUserById = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const requestedUserId = parseInt(req.params.id, 10);
        const authenticatedUser = req.user; // From authenticateToken middleware

        // Authorization Check: Admin can get any user, regular user can only get self
        if (authenticatedUser?.role !== Role.ADMIN && authenticatedUser?.userId !== requestedUserId) {
            res.status(403).json({ message: 'Forbidden: You do not have permission to access this user.' });
            return; // Add return
        }

        const user = await usersService.getUserbyId(requestedUserId);

        if (!user) {
            res.status(404).json({ message: `User with ID ${requestedUserId} not found.` });
            return; // Add return
        }

        // Exclude password hash from the response
        const { password_hash, ...userResponse } = user;
        res.status(200).json(userResponse);
        // No return needed here

    } catch (error: unknown) {
        if (error instanceof ServiceErorr) {
            res.status(error.statusCode).json({ message: error.message });
             // No return needed here
        } else if (error instanceof Error) {
            console.error("GetUserById Error:", error);
            res.status(500).json({ message: "An internal error occurred.", error: error.message });
             // No return needed here
        } else {
            console.error("GetUserById Error (Unknown):", error);
            res.status(500).json({ message: "An unknown internal error occurred." });
             // No return needed here
        }
    }
};

// Controller to update a user (Admin or self)
export const updateUser = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const requestedUserId = parseInt(req.params.id, 10);
        const authenticatedUser = req.user;
        const updateData = req.body as UpdateUserInput & { password?: string };

        // Authorization Check: Admin can update any user, regular user can only update self
        if (authenticatedUser?.role !== Role.ADMIN && authenticatedUser?.userId !== requestedUserId) {
            res.status(403).json({ message: 'Forbidden: You do not have permission to update this user.' });
            return; // Add return
        }

        // Authorization Check: Prevent non-admins from changing the role
        if (authenticatedUser?.role !== Role.ADMIN && updateData.role !== undefined) {
            console.warn(`User ${authenticatedUser?.userId} attempted to change role for user ${requestedUserId}. Denying role change.`);
            delete updateData.role; // Remove role from update data if user is not admin
        }

        // Hash password if it's being updated
        let password_hash: string | undefined;
        if (updateData.password) {
            password_hash = await hashPassword(updateData.password);
            delete updateData.password; // Remove plain password before sending to service
        }

        // Prepare final update data for the service
        const finalUpdateData: UpdateUserInput = {
            ...updateData,
            ...(password_hash && { password_hash }), // Add hashed password if it was provided
        };

        // Check if there's anything left to update after potential role removal
        if (Object.keys(finalUpdateData).length === 0) {
             const currentUser = await usersService.getUserbyId(requestedUserId);
             if (!currentUser) {
                 res.status(404).json({ message: `User with ID ${requestedUserId} not found.` });
                 return; // Add return
             }
             const { password_hash: _, ...userResponse } = currentUser;
             res.status(200).json(userResponse); // Return current data as no valid update was provided
             return; // Add return
        }

        const updatedUser = await usersService.updateUser(requestedUserId, finalUpdateData);

        // Exclude password hash from the response
        const { password_hash: _, ...userResponse } = updatedUser;
        res.status(200).json(userResponse);
        // No return needed here

    } catch (error: unknown) {
        if (error instanceof ServiceErorr) {
            res.status(error.statusCode).json({ message: error.message });
             // No return needed here
        } else if (error instanceof Error) {
            console.error("UpdateUser Error:", error);
            res.status(500).json({ message: "An internal error occurred during update.", error: error.message });
             // No return needed here
        } else {
            console.error("UpdateUser Error (Unknown):", error);
            res.status(500).json({ message: "An unknown internal error occurred during update." });
             // No return needed here
        }
    }
};

// Controller to delete a user (Self only)
export const deleteUser = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const requestedUserId = parseInt(req.params.id, 10);
        const authenticatedUser = req.user;

        // Authorization Check: User can only delete self. Role check already done by middleware.
        if (authenticatedUser?.userId !== requestedUserId) {
            res.status(403).json({ message: 'Forbidden: You can only delete your own account.' });
            return; // Add return
        }

        await usersService.deleteUser(requestedUserId);

        res.status(204).send(); // No content on successful deletion
        return; // Add return

    } catch (error: unknown) {
        if (error instanceof ServiceErorr) {
            res.status(error.statusCode).json({ message: error.message });
             // No return needed here
        } else if (error instanceof Error) {
            console.error("DeleteUser Error:", error);
            res.status(500).json({ message: "An internal error occurred during deletion.", error: error.message });
             // No return needed here
        } else {
            console.error("DeleteUser Error (Unknown):", error);
            res.status(500).json({ message: "An unknown internal error occurred during deletion." });
             // No return needed here
        }
    }
};