import pool from '../config/db';
import {PoolConnection, RowDataPacket, ResultSetHeader} from 'mysql2/promise';
import {ServiceErorr} from '../services/usersService';
import {
    Appointment,
    CreateAppointmentInput,
    UpdateAppointmentInput,
    AppointmentStatus,
    AppointmentWithDetails
} from '../models/Appointment';

// Create a new appointment
export const createAppointment = async (appointmentData: CreateAppointmentInput): Promise<Appointment> => {
    let connection: PoolConnection | undefined;
    try {
        connection = await pool.getConnection();
        
        const sql = `
            INSERT INTO appointments (
                declaration_id, user_id, admin_id, appointment_date, 
                appointment_time, location, notes, status
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        `;
        
        const [result] = await connection.execute<ResultSetHeader>(sql, [
            appointmentData.declaration_id,
            appointmentData.user_id,
            appointmentData.admin_id,
            appointmentData.appointment_date,
            appointmentData.appointment_time,
            appointmentData.location,
            appointmentData.notes || null,
            appointmentData.status || AppointmentStatus.SCHEDULED
        ]);
        
        if (result.affectedRows === 0) {
            throw new ServiceErorr('Failed to create appointment', 500);
        }
        
        // Fetch the created appointment
        const appointmentId = result.insertId;
        const createdAppointment = await getAppointmentById(appointmentId);
        
        if (!createdAppointment) {
            throw new ServiceErorr('Failed to retrieve created appointment', 500);
        }
        
        return createdAppointment;
        
    } catch (error) {
        console.error('[appointmentService] Error in createAppointment:', error);
        if (error instanceof ServiceErorr) {
            throw error;
        }
        throw new ServiceErorr('Failed to create appointment', 500);
    } finally {
        if (connection) {
            connection.release();
        }
    }
};

// Get appointment by ID
export const getAppointmentById = async (appointmentId: number): Promise<Appointment | null> => {
    let connection: PoolConnection | undefined;
    try {
        connection = await pool.getConnection();
        
        const sql = `SELECT * FROM appointments WHERE appointment_id = ?`;
        const [rows] = await connection.query<RowDataPacket[]>(sql, [appointmentId]);
        
        if (rows.length === 0) {
            return null;
        }
        
        return rows[0] as Appointment;
        
    } catch (error) {
        console.error('[appointmentService] Error in getAppointmentById:', error);
        throw new ServiceErorr('Failed to get appointment', 500);
    } finally {
        if (connection) {
            connection.release();
        }
    }
};

// Get appointments for a user
export const getUserAppointments = async (userId: number): Promise<AppointmentWithDetails[]> => {
    let connection: PoolConnection | undefined;
    try {
        connection = await pool.getConnection();
        
        const sql = `
            SELECT 
                a.*,
                CONCAT(COALESCE(u.first_name, ''), ' ', COALESCE(u.last_name, '')) as declarant_name,
                u.email as declarant_email,
                CONCAT(COALESCE(admin.first_name, ''), ' ', COALESCE(admin.last_name, '')) as admin_name,
                admin.email as admin_email,
                d.decujus_pension_number as declaration_pension_number
            FROM appointments a
            JOIN users u ON a.user_id = u.user_id
            JOIN users admin ON a.admin_id = admin.user_id
            JOIN declarations d ON a.declaration_id = d.declaration_id
            WHERE a.user_id = ?
            ORDER BY a.appointment_date ASC, a.appointment_time ASC
        `;
        
        const [rows] = await connection.query<RowDataPacket[]>(sql, [userId]);
        
        return rows.map(row => ({
            ...row,
            declarant_name: row.declarant_name?.trim() || 'Unknown',
            admin_name: row.admin_name?.trim() || 'Unknown'
        })) as AppointmentWithDetails[];
        
    } catch (error) {
        console.error('[appointmentService] Error in getUserAppointments:', error);
        throw new ServiceErorr('Failed to get user appointments', 500);
    } finally {
        if (connection) {
            connection.release();
        }
    }
};

// Get appointment by declaration ID
export const getAppointmentByDeclarationId = async (declarationId: number): Promise<Appointment | null> => {
    let connection: PoolConnection | undefined;
    try {
        connection = await pool.getConnection();
        
        const sql = `SELECT * FROM appointments WHERE declaration_id = ? ORDER BY created_at DESC LIMIT 1`;
        const [rows] = await connection.query<RowDataPacket[]>(sql, [declarationId]);
        
        if (rows.length === 0) {
            return null;
        }
        
        return rows[0] as Appointment;
        
    } catch (error) {
        console.error('[appointmentService] Error in getAppointmentByDeclarationId:', error);
        throw new ServiceErorr('Failed to get appointment by declaration', 500);
    } finally {
        if (connection) {
            connection.release();
        }
    }
};

// Get all appointments for admin
export const getAllAppointments = async (
    limit: number = 50,
    offset: number = 0
): Promise<{ appointments: AppointmentWithDetails[]; total: number }> => {
    let connection: PoolConnection | undefined;
    try {
        connection = await pool.getConnection();
        
        // Get total count
        const countSql = `SELECT COUNT(*) as total FROM appointments`;
        const [countRows] = await connection.query<RowDataPacket[]>(countSql);
        const total = countRows[0].total;
        
        // Get appointments with details
        const sql = `
            SELECT 
                a.*,
                CONCAT(COALESCE(u.first_name, ''), ' ', COALESCE(u.last_name, '')) as declarant_name,
                u.email as declarant_email,
                CONCAT(COALESCE(admin.first_name, ''), ' ', COALESCE(admin.last_name, '')) as admin_name,
                admin.email as admin_email,
                d.decujus_pension_number as declaration_pension_number
            FROM appointments a
            JOIN users u ON a.user_id = u.user_id
            JOIN users admin ON a.admin_id = admin.user_id
            JOIN declarations d ON a.declaration_id = d.declaration_id
            ORDER BY a.appointment_date ASC, a.appointment_time ASC
            LIMIT ? OFFSET ?
        `;
        
        const [rows] = await connection.query<RowDataPacket[]>(sql, [limit, offset]);
        
        const appointments = rows.map(row => ({
            ...row,
            declarant_name: row.declarant_name?.trim() || 'Unknown',
            admin_name: row.admin_name?.trim() || 'Unknown'
        })) as AppointmentWithDetails[];
        
        return { appointments, total };
        
    } catch (error) {
        console.error('[appointmentService] Error in getAllAppointments:', error);
        throw new ServiceErorr('Failed to get all appointments', 500);
    } finally {
        if (connection) {
            connection.release();
        }
    }
};

// Update appointment
export const updateAppointment = async (
    appointmentId: number,
    updateData: UpdateAppointmentInput
): Promise<Appointment> => {
    let connection: PoolConnection | undefined;
    try {
        connection = await pool.getConnection();
        
        const updates: string[] = [];
        const values: any[] = [];
        
        if (updateData.appointment_date !== undefined) {
            updates.push('appointment_date = ?');
            values.push(updateData.appointment_date);
        }
        
        if (updateData.appointment_time !== undefined) {
            updates.push('appointment_time = ?');
            values.push(updateData.appointment_time);
        }
        
        if (updateData.location !== undefined) {
            updates.push('location = ?');
            values.push(updateData.location);
        }
        
        if (updateData.notes !== undefined) {
            updates.push('notes = ?');
            values.push(updateData.notes);
        }
        
        if (updateData.status !== undefined) {
            updates.push('status = ?');
            values.push(updateData.status);
        }
        
        if (updates.length === 0) {
            const appointment = await getAppointmentById(appointmentId);
            if (!appointment) {
                throw new ServiceErorr('Appointment not found', 404);
            }
            return appointment;
        }
        
        updates.push('updated_at = CURRENT_TIMESTAMP');
        values.push(appointmentId);
        
        const sql = `UPDATE appointments SET ${updates.join(', ')} WHERE appointment_id = ?`;
        const [result] = await connection.execute<ResultSetHeader>(sql, values);
        
        if (result.affectedRows === 0) {
            throw new ServiceErorr('Appointment not found', 404);
        }
        
        const updatedAppointment = await getAppointmentById(appointmentId);
        if (!updatedAppointment) {
            throw new ServiceErorr('Failed to retrieve updated appointment', 500);
        }
        
        return updatedAppointment;
        
    } catch (error) {
        console.error('[appointmentService] Error in updateAppointment:', error);
        if (error instanceof ServiceErorr) {
            throw error;
        }
        throw new ServiceErorr('Failed to update appointment', 500);
    } finally {
        if (connection) {
            connection.release();
        }
    }
};

// Delete appointment
export const deleteAppointment = async (appointmentId: number): Promise<void> => {
    let connection: PoolConnection | undefined;
    try {
        connection = await pool.getConnection();
        
        const sql = `DELETE FROM appointments WHERE appointment_id = ?`;
        const [result] = await connection.execute<ResultSetHeader>(sql, [appointmentId]);
        
        if (result.affectedRows === 0) {
            throw new ServiceErorr('Appointment not found', 404);
        }
        
    } catch (error) {
        console.error('[appointmentService] Error in deleteAppointment:', error);
        if (error instanceof ServiceErorr) {
            throw error;
        }
        throw new ServiceErorr('Failed to delete appointment', 500);
    } finally {
        if (connection) {
            connection.release();
        }
    }
};