// ../controllers/userController.ts

import { Request, Response, NextFunction } from "express";
import * as usersService from '../services/usersService'; // Import service functions
import { ServiceErorr } from '../services/usersService'; // Import custom error
import { hashPassword, comparePassword } from '../utils/passwordUtils'; // Import password utilities
import { generateToken,JwtPayload } from '../utils/jwtUtils'; // Import JWT utility (ensure JwtPayload is imported if used by generateToken directly, or in its own file)
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

        // ---- MODIFIED PART FOR OPTION 1 ----
        // Generate JWT token for the new user
        // Ensure newUser has user_id and role properties as expected by generateToken
        const token = generateToken(newUser.user_id, newUser.role);

        // Prepare response, excluding password_hash from the user object
        const { password_hash: _, ...userSafeDetails } = newUser;

        res.status(201).json({
            message: "User created and logged in successfully", // Updated message
            token: token,                                     // Include the token
            user: userSafeDetails                             // Include user details
        });
        // ---- END MODIFIED PART ----

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
            return;
        }

        // Generate JWT token
        const token = generateToken(user.user_id, user.role);

        // Send token back to client
        res.status(200).json({ token }); // Login response only includes the token currently

    } catch (error: unknown) {
        if (error instanceof ServiceErorr) {
            console.error("Login Service Error:", error);
            res.status(500).json({ message: "An internal error occurred during login." });
        } else if (error instanceof Error) {
            console.error("Login Error:", error);
            res.status(500).json({ message: "An internal error occurred during login.", error: error.message });
        } else {
            console.error("Login Error (Unknown):", error);
            res.status(500).json({ message: "An unknown internal error occurred during login." });
        }
    }
};

// Controller to get all users (Admin only)
export const getAllUsers = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const users = await usersService.getAllUsers();
        const usersResponse = users.map(({ password_hash, ...user }) => user);
        res.status(200).json(usersResponse);
    } catch (error: unknown) {
        if (error instanceof ServiceErorr) {
            res.status(error.statusCode).json({ message: error.message });
        } else if (error instanceof Error) {
            console.error("GetAllUsers Error:", error);
            res.status(500).json({ message: "An internal error occurred.", error: error.message });
        } else {
            console.error("GetAllUsers Error (Unknown):", error);
            res.status(500).json({ message: "An unknown internal error occurred." });
        }
    }
};

// Controller to get a user by ID (Admin or self)
export const getUserById = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const requestedUserId = parseInt(req.params.id, 10);
        const authenticatedUser = req.user as JwtPayload; // Type assertion for req.user

        if (authenticatedUser?.role !== Role.ADMIN && authenticatedUser?.userId !== requestedUserId) {
            res.status(403).json({ message: 'Forbidden: You do not have permission to access this user.' });
            return;
        }

        const user = await usersService.getUserbyId(requestedUserId);

        if (!user) {
            res.status(404).json({ message: `User with ID ${requestedUserId} not found.` });
            return;
        }

        const { password_hash, ...userResponse } = user;
        res.status(200).json(userResponse);

    } catch (error: unknown) {
        if (error instanceof ServiceErorr) {
            res.status(error.statusCode).json({ message: error.message });
        } else if (error instanceof Error) {
            console.error("GetUserById Error:", error);
            res.status(500).json({ message: "An internal error occurred.", error: error.message });
        } else {
            console.error("GetUserById Error (Unknown):", error);
            res.status(500).json({ message: "An unknown internal error occurred." });
        }
    }
};

// Controller to update a user (Admin or self)
export const updateUser = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const requestedUserId = parseInt(req.params.id, 10);
        const authenticatedUser = req.user as JwtPayload; // Type assertion for req.user
        const updateData = req.body as UpdateUserInput & { password?: string };

        if (authenticatedUser?.role !== Role.ADMIN && authenticatedUser?.userId !== requestedUserId) {
            res.status(403).json({ message: 'Forbidden: You do not have permission to update this user.' });
            return;
        }

        if (authenticatedUser?.role !== Role.ADMIN && updateData.role !== undefined) {
            console.warn(`User ${authenticatedUser?.userId} attempted to change role for user ${requestedUserId}. Denying role change.`);
            delete updateData.role;
        }

        let password_hash_to_update: string | undefined; // Renamed to avoid conflict
        if (updateData.password) {
            password_hash_to_update = await hashPassword(updateData.password);
            delete updateData.password;
        }

        const finalUpdateData: UpdateUserInput = {
            ...updateData,
            ...(password_hash_to_update && { password_hash: password_hash_to_update }),
        };

        if (Object.keys(finalUpdateData).filter(key => key !== 'password_hash' || finalUpdateData.password_hash !== undefined).length === 0 && !password_hash_to_update) {
             const currentUser = await usersService.getUserbyId(requestedUserId);
             if (!currentUser) {
                 res.status(404).json({ message: `User with ID ${requestedUserId} not found.` });
                 return;
             }
             const { password_hash: _, ...userResponse } = currentUser;
             res.status(200).json(userResponse);
             return;
        }


        const updatedUser = await usersService.updateUser(requestedUserId, finalUpdateData);
        const { password_hash: _, ...userResponse } = updatedUser;
        res.status(200).json(userResponse);

    } catch (error: unknown) {
        if (error instanceof ServiceErorr) {
            res.status(error.statusCode).json({ message: error.message });
        } else if (error instanceof Error) {
            console.error("UpdateUser Error:", error);
            res.status(500).json({ message: "An internal error occurred during update.", error: error.message });
        } else {
            console.error("UpdateUser Error (Unknown):", error);
            res.status(500).json({ message: "An unknown internal error occurred during update." });
        }
    }
};

// Controller to delete a user (Self only)
export const deleteUser = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const requestedUserId = parseInt(req.params.id, 10);
        const authenticatedUser = req.user as JwtPayload; // Type assertion for req.user

        if (authenticatedUser?.userId !== requestedUserId) {
            res.status(403).json({ message: 'Forbidden: You can only delete your own account.' });
            return;
        }

        await usersService.deleteUser(requestedUserId);
        res.status(204).send();
        return;

    } catch (error: unknown) {
        if (error instanceof ServiceErorr) {
            res.status(error.statusCode).json({ message: error.message });
        } else if (error instanceof Error) {
            console.error("DeleteUser Error:", error);
            res.status(500).json({ message: "An internal error occurred during deletion.", error: error.message });
        } else {
            console.error("DeleteUser Error (Unknown):", error);
            res.status(500).json({ message: "An unknown internal error occurred during deletion." });
        }
    }
};