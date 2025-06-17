import {Request, Response, NextFunction} from "express";
import * as appointmentService from '../services/appointmentService';
import * as notificationService from '../services/notificationService';
import {ServiceErorr} from '../services/usersService';
import {CreateAppointmentInput, UpdateAppointmentInput, AppointmentStatus} from '../models/Appointment';

// Create a new appointment
export const createAppointment = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const adminId = (req as any).user.userId;
        const {declaration_id, user_id, appointment_date, appointment_time, location, notes} = req.body;

        if (!declaration_id || !user_id || !appointment_date || !appointment_time || !location) {
            res.status(400).json({
                message: 'Declaration ID, user ID, appointment date, time, and location are required'
            });
            return;
        }

        const appointmentData: CreateAppointmentInput = {
            declaration_id,
            user_id,
            admin_id: adminId,
            appointment_date: new Date(appointment_date),
            appointment_time,
            location,
            notes,
            status: AppointmentStatus.SCHEDULED
        };

        const appointment = await appointmentService.createAppointment(appointmentData);

        // Send notification to user about the appointment
        const appointmentDateTime = new Date(`${appointment_date} ${appointment_time}`);
        await notificationService.sendNotificationToUser(
            user_id,
            'Appointment Scheduled',
            `Your appointment has been scheduled for ${appointmentDateTime.toLocaleString()} at ${location}. Please be on time.`,
            adminId,
            'appointment',
            appointment.appointment_id
        );

        res.status(201).json({
            success: true,
            message: 'Appointment created successfully',
            appointment
        });

    } catch (error: unknown) {
        console.error('Controller error during appointment creation:', error);
        next(error);
    }
};

// Get user's appointments
export const getUserAppointments = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const userId = (req as any).user.userId;
        
        const appointments = await appointmentService.getUserAppointments(userId);
        
        res.status(200).json({
            success: true,
            appointments
        });

    } catch (error: unknown) {
        console.error('Controller error during user appointments retrieval:', error);
        next(error);
    }
};

// Get all appointments (admin only)
export const getAllAppointments = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const limit = parseInt(req.query.limit as string) || 50;
        const offset = parseInt(req.query.offset as string) || 0;
        
        const result = await appointmentService.getAllAppointments(limit, offset);
        
        res.status(200).json({
            success: true,
            appointments: result.appointments,
            total: result.total,
            limit,
            offset
        });

    } catch (error: unknown) {
        console.error('Controller error during all appointments retrieval:', error);
        next(error);
    }
};

// Get appointment by ID
export const getAppointmentById = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const userId = (req as any).user.userId;
        const userRole = (req as any).user.role;
        const appointmentId = parseInt(req.params.appointmentId, 10);

        if (isNaN(appointmentId)) {
            res.status(400).json({ message: 'Invalid appointment ID' });
            return;
        }

        const appointment = await appointmentService.getAppointmentById(appointmentId);
        
        if (!appointment) {
            res.status(404).json({ message: 'Appointment not found' });
            return;
        }

        // Check if user has permission to view this appointment
        if (userRole !== 'admin' && appointment.user_id !== userId) {
            res.status(403).json({ message: 'Forbidden: You do not have access to this appointment' });
            return;
        }

        res.status(200).json({
            success: true,
            appointment
        });

    } catch (error: unknown) {
        console.error('Controller error during appointment retrieval:', error);
        next(error);
    }
};

// Update appointment
export const updateAppointment = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const adminId = (req as any).user.userId;
        const appointmentId = parseInt(req.params.appointmentId, 10);

        if (isNaN(appointmentId)) {
            res.status(400).json({ message: 'Invalid appointment ID' });
            return;
        }

        const updateData: UpdateAppointmentInput = {};
        
        if (req.body.appointment_date) updateData.appointment_date = new Date(req.body.appointment_date);
        if (req.body.appointment_time) updateData.appointment_time = req.body.appointment_time;
        if (req.body.location) updateData.location = req.body.location;
        if (req.body.notes !== undefined) updateData.notes = req.body.notes;
        if (req.body.status) updateData.status = req.body.status;

        const appointment = await appointmentService.updateAppointment(appointmentId, updateData);

        // Send notification to user about appointment update
        const appointmentDateTime = new Date(`${appointment.appointment_date} ${appointment.appointment_time}`);
        await notificationService.sendNotificationToUser(
            appointment.user_id,
            'Appointment Updated',
            `Your appointment has been updated. New details: ${appointmentDateTime.toLocaleString()} at ${appointment.location}`,
            adminId,
            'appointment',
            appointment.appointment_id
        );

        res.status(200).json({
            success: true,
            message: 'Appointment updated successfully',
            appointment
        });

    } catch (error: unknown) {
        console.error('Controller error during appointment update:', error);
        next(error);
    }
};

// Delete appointment
export const deleteAppointment = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const adminId = (req as any).user.userId;
        const appointmentId = parseInt(req.params.appointmentId, 10);

        if (isNaN(appointmentId)) {
            res.status(400).json({ message: 'Invalid appointment ID' });
            return;
        }

        // Get appointment details before deletion for notification
        const appointment = await appointmentService.getAppointmentById(appointmentId);
        if (!appointment) {
            res.status(404).json({ message: 'Appointment not found' });
            return;
        }

        await appointmentService.deleteAppointment(appointmentId);

        // Send notification to user about appointment cancellation
        await notificationService.sendNotificationToUser(
            appointment.user_id,
            'Appointment Cancelled',
            `Your appointment scheduled for ${new Date(`${appointment.appointment_date} ${appointment.appointment_time}`).toLocaleString()} has been cancelled.`,
            adminId,
            'appointment',
            appointmentId
        );

        res.status(200).json({
            success: true,
            message: 'Appointment deleted successfully'
        });

    } catch (error: unknown) {
        console.error('Controller error during appointment deletion:', error);
        next(error);
    }
};