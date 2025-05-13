import {Request, Response, NextFunction} from "express";
import * as documentService from '../services/documentService';
import {ServiceErorr} from '../services/usersService';
import * as declarationService from '../services/declarationService';
import * as decujusService from '../services/decujusService';
import {Status as DeclarationStatus} from "../models/Declarations";


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
       res.status(200).json({ message: 'Declaration rejected successfully' });
    } catch (error: unknown) {
        console.error('Controller error during declaration rejection:', error);
        next(error);
    }
}