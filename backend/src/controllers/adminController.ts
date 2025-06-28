import {Request, Response, NextFunction} from "express";
import * as documentService from '../services/documentService';
import {ServiceErorr} from '../services/usersService';
import * as declarationService from '../services/declarationService';
import * as decujusService from '../services/decujusService';
import * as usersService from '../services/usersService';
import * as notificationService from '../services/notificationService';
import * as appointmentService from '../services/appointmentService';
import {Status as DeclarationStatus} from "../models/Declarations";
import {AppointmentStatus} from "../models/Appointment";


export const getAllDeclarationsForAdmin = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const adminId = (req as any).user.userId;
        
        // Get query parameters for filtering and pagination
        const page = parseInt(req.query.page as string) || 1;
        const limit = parseInt(req.query.limit as string) || 10;
        const offset = (page - 1) * limit;
        const status = req.query.status as string;
        const search = req.query.search as string;
        
        // Get all declarations with user information and document counts
        const result = await declarationService.getAllDeclarationsForAdmin(limit, offset, status, search);
        
        res.status(200).json({
            success: true,
            data: result.declarations,
            pagination: {
                page,
                limit,
                total: result.total,
                totalPages: Math.ceil(result.total / limit)
            }
        });
        
    } catch (error: unknown) {
        console.error('Controller error during admin declarations retrieval:', error);
        next(error);
    }
};

export const getDeclarationDetails = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const adminId = (req as any).user.userId;
        const declarationId = parseInt(req.params.declarationId, 10);
        
        if (isNaN(declarationId)) {
            res.status(400).json({ message: 'Invalid declaration ID' });
            return;
        }
        
        // Get declaration details
        const declaration = await declarationService.getDeclarationById(declarationId);
        if (!declaration) {
            res.status(404).json({ message: 'Declaration not found' });
            return;
        }
        
        // Get user information
        const user = await usersService.getUserbyId(declaration.applicant_user_id);
        if (!user) {
            res.status(404).json({ message: 'User not found for this declaration' });
            return;
        }
        
        // Get declaration documents with status
        const documents = await documentService.getDeclarationDocumentsStatus(declarationId);
        
        // Count document statuses
        const documentStats = {
            total: documents.length,
            pending: documents.filter(doc => doc.status === 'pending').length,
            uploaded: documents.filter(doc => doc.status === 'uploaded').length,
            verified: documents.filter(doc => doc.status === 'verified').length,
            rejected: documents.filter(doc => doc.status === 'rejected').length,
            mandatory: documents.filter(doc => doc.is_mandatory).length,
            mandatoryVerified: documents.filter(doc => doc.is_mandatory && doc.status === 'verified').length
        };
        
        // Prepare response with all details
        const response = {
            declaration: {
                ...declaration,
                declarant_name: `${user.first_name || ''} ${user.last_name || ''}`.trim() || 'Unknown',
                declarant_email: user.email
            },
            documents,
            documentStats,
            canApprove: documentStats.mandatoryVerified === documentStats.mandatory && documentStats.mandatory > 0,
            user: {
                user_id: user.user_id,
                email: user.email,
                first_name: user.first_name,
                last_name: user.last_name,
                created_at: user.created_at
            }
        };
        
        res.status(200).json(response);
        
    } catch (error: unknown) {
        console.error('Controller error during admin declaration details retrieval:', error);
        next(error);
    }
};

export const handleReviewDocument = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try { 
        const adminId = (req as any).user.userId; 
        const delcarationDocumentId = parseInt(req.params.declarationDocumentId, 10);
        if (isNaN(delcarationDocumentId)) {
            res.status(400).json({ message: 'Invalid declaration document ID' });
            return;
        }
        const {newStatus, rejectionReason} = req.body;
        if (!newStatus) {
            res.status(400).json({ message: 'New status is required' });
            return;
        }
        if (newStatus === 'rejected' && !rejectionReason) {
            res.status(400).json({ message: 'Rejection reason is required when status is rejected' });
            return;
        }
        const result = await documentService.reviewDocument(delcarationDocumentId, newStatus, rejectionReason, adminId);
        
        // Send notification to user about document review
        const applicantUserId = await documentService.getApplicantUserIdForDeclarationDocument(delcarationDocumentId);
        if (applicantUserId) {
            const title = newStatus === 'verified' ? 'Document Approuvé' : 'Document Rejeté';
            const body = newStatus === 'verified' 
                ? 'Un de vos documents a été approuvé par l\'administrateur.'
                : `Un de vos documents a été rejeté. Raison: ${rejectionReason || 'Aucune raison fournie'}`;
            
            await notificationService.sendNotificationToUser(
                applicantUserId,
                title,
                body,
                adminId,
                'document_review',
                delcarationDocumentId
            );
        }
        
        res.status(200).json({message: 'Document reviewed successfully', result});
    } catch (error: unknown) {
        console.error('Controller error during document review:', error);
        next(error);
    }
}

export const handleApproveDeclaration = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const adminId = (req as any).user.userId; 
        const declarationId = parseInt(req.params.declarationId, 10);
        if (isNaN(declarationId)) {
            res.status(400).json({message: 'Invalid declaration ID'});
            return; 
        } 
        const allVerifed = await documentService.checkAllMandatoryDocumentsVerified(declarationId);
        if (!allVerifed) {
            res.status(400).json({message: 'All mandatory documents must be verified before approving the declaration'});
            return; 
        }
        const declaration = await declarationService.getDeclarationById(declarationId); 
        if (!declaration) {
            res.status(404).json({message: 'Declaration not found'});
            return; 
        }
        if (declaration.status == 'approved'){ 
            res.status(400).json({message: 'Declaration already approved'});
            return; 
        }
        if (!declaration.decujus_pension_number) {
            res.status(400).json({ message: 'Decujus pension number is required' });
            return;
        }

        await decujusService.deactivatePension(declaration.decujus_pension_number, adminId);
        await declarationService.updateDeclarationStatus(declarationId, DeclarationStatus.APPROVED, adminId);
        
        // Send notification to user about declaration approval
        await notificationService.sendDeclarationApprovedNotification(
            declaration.applicant_user_id,
            adminId,
            declarationId
        );
    
        res.status(200).json({message: 'Declaration approved successfully'});
    } catch (error: unknown) {
        console.error('Controller error during declaration approval:', error);
        next(error);
    }
}

export const handleRejectDeclaration = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try { 
        const adminId = (req as any).user.userId; 
        const declarationId = parseInt(req.params.declarationId, 10);
        if (isNaN(declarationId)) {
            res.status(400).json({message: 'Invalid declaration ID'});
            return; 
        } 
        const {rejectionReason} = req.body;
        if (!rejectionReason) {
            res.status(400).json({ message: 'Rejection reason is required' });
            return;
        }
        const declaration = await declarationService.getDeclarationById(declarationId);
        if (!declaration) {
            res.status(404).json({message: 'Declaration not found'});
            return; 
        }
        
        if (declaration.status === DeclarationStatus.APPROVED) {
            res.status(400).json({ message: 'Cannot reject a declaration that has already been approved' });
            return;
        }
        if (declaration.status === DeclarationStatus.REJECTED) {
            res.status(400).json({ message: 'Declaration is already rejected' });
            return;
        }
        
       await declarationService.updateDeclarationStatus(declarationId, DeclarationStatus.REJECTED, adminId);
       
       // Send notification to user about declaration rejection
       await notificationService.sendDeclarationRejectedNotification(
           declaration.applicant_user_id,
           adminId,
           declarationId,
           rejectionReason
       );
       
       res.status(200).json({ message: 'Declaration rejected successfully' });
    } catch (error: unknown) {
        console.error('Controller error during declaration rejection:', error);
        next(error);
    }
}

// New function to approve all pending declarations at once
export const handleApproveAllDeclarations = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const adminId = (req as any).user.userId;
        
        // Get all pending declarations that can be approved
        const result = await declarationService.getAllDeclarationsForAdmin(1000, 0, 'submitted');
        const pendingDeclarations = result.declarations.filter(
            declaration => declaration.mandatory_verified === declaration.mandatory_documents && declaration.mandatory_documents > 0
        );
        
        if (pendingDeclarations.length === 0) {
            res.status(200).json({
                message: 'No declarations available for approval',
                approved: 0
            });
            return;
        }
        
        let approvedCount = 0;
        let errors: string[] = [];
        
        // Process each declaration
        for (const declaration of pendingDeclarations) {
            try {
                // Check if all mandatory documents are verified
                const allVerified = await documentService.checkAllMandatoryDocumentsVerified(declaration.declaration_id);
                if (!allVerified) {
                    errors.push(`Declaration #${declaration.declaration_id}: Not all mandatory documents are verified`);
                    continue;
                }
                
                // Get full declaration details
                const fullDeclaration = await declarationService.getDeclarationById(declaration.declaration_id);
                if (!fullDeclaration) {
                    errors.push(`Declaration #${declaration.declaration_id}: Declaration not found`);
                    continue;
                }
                
                if (fullDeclaration.status !== 'submitted') {
                    errors.push(`Declaration #${declaration.declaration_id}: Declaration not in submitted status`);
                    continue;
                }
                
                if (!fullDeclaration.decujus_pension_number) {
                    errors.push(`Declaration #${declaration.declaration_id}: Decujus pension number is required`);
                    continue;
                }
                
                // Approve the declaration
                await decujusService.deactivatePension(fullDeclaration.decujus_pension_number, adminId);
                await declarationService.updateDeclarationStatus(declaration.declaration_id, DeclarationStatus.APPROVED, adminId);
                
                // Send notification to user
                await notificationService.sendDeclarationApprovedNotification(
                    fullDeclaration.applicant_user_id,
                    adminId,
                    declaration.declaration_id
                );
                
                approvedCount++;
                
            } catch (error) {
                console.error(`Error approving declaration ${declaration.declaration_id}:`, error);
                errors.push(`Declaration #${declaration.declaration_id}: ${error instanceof Error ? error.message : 'Unknown error'}`);
            }
        }
        
        res.status(200).json({
            message: `Bulk approval completed. ${approvedCount} declarations approved.`,
            approved: approvedCount,
            total: pendingDeclarations.length,
            errors: errors.length > 0 ? errors : undefined
        });
        
    } catch (error: unknown) {
        console.error('Controller error during bulk declaration approval:', error);
        next(error);
    }
};

// New function to approve declaration with appointment creation and auto-verify documents
export const handleApproveDeclarationWithAppointment = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const adminId = (req as any).user.userId;
        const declarationId = parseInt(req.params.declarationId, 10);
        const { appointment_date, appointment_time, location, notes } = req.body;

        if (isNaN(declarationId)) {
            res.status(400).json({ message: 'Invalid declaration ID' });
            return;
        }

        if (!appointment_date || !appointment_time || !location) {
            res.status(400).json({ 
                message: 'Appointment date, time, and location are required for approval' 
            });
            return;
        }

        const declaration = await declarationService.getDeclarationById(declarationId);
        if (!declaration) {
            res.status(404).json({ message: 'Declaration not found' });
            return;
        }

        if (declaration.status === DeclarationStatus.APPROVED) {
            res.status(400).json({ message: 'Declaration already approved' });
            return;
        }

        if (!declaration.decujus_pension_number) {
            res.status(400).json({ message: 'Decujus pension number is required' });
            return;
        }

        // Get all documents for this declaration
        const documents = await documentService.getDeclarationDocumentsStatus(declarationId);
        
        // Auto-verify all uploaded documents
        for (const document of documents) {
            if (document.uploaded_file_path && document.status === 'uploaded') {
                await documentService.reviewDocument(
                    document.declaration_document_id,
                    'verified',
                    null,
                    adminId
                );
            }
        }

        // Check if all mandatory documents are now verified
        const allVerified = await documentService.checkAllMandatoryDocumentsVerified(declarationId);
        if (!allVerified) {
            res.status(400).json({ 
                message: 'Cannot approve: some mandatory documents are missing or not uploaded' 
            });
            return;
        }

        // Deactivate pension and approve declaration
        await decujusService.deactivatePension(declaration.decujus_pension_number, adminId);
        await declarationService.updateDeclarationStatus(declarationId, DeclarationStatus.APPROVED, adminId);

        // Create appointment
        const appointment = await appointmentService.createAppointment({
            declaration_id: declarationId,
            user_id: declaration.applicant_user_id,
            admin_id: adminId,
            appointment_date: new Date(appointment_date),
            appointment_time,
            location,
            notes,
            status: AppointmentStatus.SCHEDULED
        });

        // Send notification about approval and appointment
        const appointmentDateTime = new Date(`${appointment_date} ${appointment_time}`);
        await notificationService.sendNotificationToUser(
            declaration.applicant_user_id,
            'Déclaration Approuvée - Rendez-vous Planifié',
            `Excellente nouvelle! Votre déclaration a été approuvée. Un rendez-vous a été planifié pour le ${appointmentDateTime.toLocaleDateString('fr-FR')} à ${appointmentDateTime.toLocaleTimeString('fr-FR', {hour: '2-digit', minute: '2-digit'})} à ${location}. Veuillez apporter tous les documents requis.`,
            adminId,
            'appointment',
            declarationId
        );

        res.status(200).json({ 
            message: 'Declaration approved successfully and appointment created',
            appointment: {
                appointment_id: appointment.appointment_id,
                appointment_date: appointment.appointment_date,
                appointment_time: appointment.appointment_time,
                location: appointment.location
            }
        });

    } catch (error: unknown) {
        console.error('Controller error during declaration approval with appointment:', error);
        next(error);
    }
};

// Enhanced bulk approval to include appointment creation
export const handleApproveAllDeclarationsWithAppointments = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const adminId = (req as any).user.userId;
        const { default_appointment_date, default_appointment_time, default_location, default_notes } = req.body;

        if (!default_appointment_date || !default_appointment_time || !default_location) {
            res.status(400).json({
                message: 'Default appointment date, time, and location are required for bulk approval'
            });
            return;
        }

        // Get all pending declarations
        const result = await declarationService.getAllDeclarationsForAdmin(1000, 0, 'submitted');
        const pendingDeclarations = result.declarations.filter(
            declaration => declaration.total_documents > 0 // Has uploaded documents
        );

        if (pendingDeclarations.length === 0) {
            res.status(200).json({
                message: 'No declarations available for approval',
                approved: 0
            });
            return;
        }

        let approvedCount = 0;
        let errors: string[] = [];
        let appointmentCount = 0;

        // Process each declaration
        for (const declaration of pendingDeclarations) {
            try {
                // Get full declaration details
                const fullDeclaration = await declarationService.getDeclarationById(declaration.declaration_id);
                if (!fullDeclaration || fullDeclaration.status !== 'submitted') {
                    continue;
                }

                // Get all documents for this declaration
                const documents = await documentService.getDeclarationDocumentsStatus(declaration.declaration_id);
                
                // Auto-verify all uploaded documents
                for (const document of documents) {
                    if (document.uploaded_file_path && document.status === 'uploaded') {
                        await documentService.reviewDocument(
                            document.declaration_document_id,
                            'verified',
                            null,
                            adminId
                        );
                    }
                }

                // Check if all mandatory documents are now verified
                const allVerified = await documentService.checkAllMandatoryDocumentsVerified(declaration.declaration_id);
                if (!allVerified) {
                    errors.push(`Declaration #${declaration.declaration_id}: Not all mandatory documents are uploaded`);
                    continue;
                }

                if (!fullDeclaration.decujus_pension_number) {
                    errors.push(`Declaration #${declaration.declaration_id}: Decujus pension number is required`);
                    continue;
                }

                // Approve the declaration
                await decujusService.deactivatePension(fullDeclaration.decujus_pension_number, adminId);
                await declarationService.updateDeclarationStatus(declaration.declaration_id, DeclarationStatus.APPROVED, adminId);

                // Create appointment with time slots (spread appointments throughout the day)
                const appointmentTime = calculateAppointmentTime(default_appointment_time, appointmentCount);
                const appointment = await appointmentService.createAppointment({
                    declaration_id: declaration.declaration_id,
                    user_id: fullDeclaration.applicant_user_id,
                    admin_id: adminId,
                    appointment_date: new Date(default_appointment_date),
                    appointment_time: appointmentTime,
                    location: default_location,
                    notes: default_notes,
                    status: AppointmentStatus.SCHEDULED
                });

                // Send notification
                const appointmentDateTime = new Date(`${default_appointment_date} ${appointmentTime}`);
                await notificationService.sendNotificationToUser(
                    fullDeclaration.applicant_user_id,
                    'Déclaration Approuvée - Rendez-vous Planifié',
                    `Excellente nouvelle! Votre déclaration a été approuvée. Un rendez-vous a été planifié pour le ${appointmentDateTime.toLocaleDateString('fr-FR')} à ${appointmentDateTime.toLocaleTimeString('fr-FR', {hour: '2-digit', minute: '2-digit'})} à ${default_location}. Veuillez apporter tous les documents requis.`,
                    adminId,
                    'declaration_approved',
                    declaration.declaration_id
                );

                approvedCount++;
                appointmentCount++;

            } catch (error) {
                console.error(`Error approving declaration ${declaration.declaration_id}:`, error);
                errors.push(`Declaration #${declaration.declaration_id}: ${error instanceof Error ? error.message : 'Unknown error'}`);
            }
        }

        res.status(200).json({
            message: `Bulk approval completed. ${approvedCount} declarations approved with appointments created.`,
            approved: approvedCount,
            appointments_created: appointmentCount,
            total: pendingDeclarations.length,
            errors: errors.length > 0 ? errors : undefined
        });

    } catch (error: unknown) {
        console.error('Controller error during bulk declaration approval with appointments:', error);
        next(error);
    }
};

// Helper function to calculate appointment times with intervals
function calculateAppointmentTime(baseTime: string, index: number): string {
    const [hours, minutes] = baseTime.split(':').map(Number);
    const intervalMinutes = 30; // 30-minute intervals
    
    const totalMinutes = hours * 60 + minutes + (index * intervalMinutes);
    const newHours = Math.floor(totalMinutes / 60) % 24;
    const newMinutes = totalMinutes % 60;
    
    return `${String(newHours).padStart(2, '0')}:${String(newMinutes).padStart(2, '0')}:00`;
}


/**
 * [NEW] Gets all approved declarations, grouped by decujus pension number.
 */
export const getApprovedDeclarationGroups = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const groups = await declarationService.getApprovedDeclarationsGroupedByPensionNumber();
        res.status(200).json(groups);
    } catch (error) {
        console.error('Controller error during getApprovedDeclarationGroups:', error);
        next(error);
    }
};

/**
 * [NEW] Handles the request to calculate pension distribution and notify users.
 */
export const handlePensionCalculation = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const adminId = (req as any).user.userId;
        const { decujusPensionNumber } = req.body;

        if (!decujusPensionNumber) {
            res.status(400).json({ message: 'decujusPensionNumber is required.' });
            return;
        }

        await declarationService.triggerPensionCalculationAndNotification(decujusPensionNumber, adminId);

        res.status(200).json({ success: true, message: `Bénéficiaires pour le N° ${decujusPensionNumber} notifiés avec succès.` });

    } catch (error) {
        console.error('Controller error during handlePensionCalculation:', error);
        next(error);
    }
};