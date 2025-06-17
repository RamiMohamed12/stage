// Appointment model interfaces and types
export interface Appointment {
    appointment_id: number;
    declaration_id: number;
    user_id: number;
    admin_id: number;
    appointment_date: Date;
    appointment_time: string; // TIME format as string
    location: string;
    notes: string | null;
    status: AppointmentStatus;
    created_at: Date;
    updated_at: Date;
}

export enum AppointmentStatus {
    SCHEDULED = 'scheduled',
    COMPLETED = 'completed',
    CANCELLED = 'cancelled'
}

export interface CreateAppointmentInput {
    declaration_id: number;
    user_id: number;
    admin_id: number;
    appointment_date: Date;
    appointment_time: string;
    location: string;
    notes?: string;
    status?: AppointmentStatus;
}

export interface UpdateAppointmentInput {
    appointment_date?: Date;
    appointment_time?: string;
    location?: string;
    notes?: string;
    status?: AppointmentStatus;
}

export interface AppointmentWithDetails extends Appointment {
    declarant_name: string;
    declarant_email: string;
    admin_name: string;
    admin_email: string;
    declaration_pension_number: string | null;
}