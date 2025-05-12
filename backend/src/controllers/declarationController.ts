import {Request, Response, NextFunction} from "express";
import * as declarationService from '../services/declarationService';
import { CreateDeclarationInput, Status } from "../models/Declarations";
import * as documentService from '../services/documentService';
import {RowDataPacket} from 'mysql2/promise';
import {ServiceErorr} from '../services/usersService';


export const handleCreateDeclaration = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try { 

        const userId = (req as any).user.userId;

        const { decujus_pension_number, relationship_id, death_cause_id, declaration_date, status } = req.body;
        const declarationInput:CreateDeclarationInput = {
            applicant_user_id: userId,
            decujus_pension_number,
            relationship_id,
            death_cause_id,
            declaration_date: declaration_date ? new Date(declaration_date): new Date(),
            status: Status.SUBMITTED 
        };
        const createdDeclaration = await declarationService.createDeclaration(declarationInput);
        if (!createdDeclaration) {
            res.status(400).json({ message: 'Failed to create declaration' });
            return;
        }
        res.status(201).json(createdDeclaration);
    } catch (error: unknown) {
        console.error('Controller error during declaration creation:', error);
        next(error); 
    } 
}

export const handleGetDeclarationById = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try { 
        const userId = (req as any).user.userId;
        const declarationId = parseInt(req.params.declarationId, 10);
        if (isNaN(declarationId)) {
            res.status(400).json({ message: 'Invalid declaration ID' });
            return;
        }
        const declaration = await declarationService.getDeclarationById(declarationId);
        if (!declaration) {
            res.status(404).json({ message: 'Declaration not found' });
            return;
        }
        // Check if the user is authorized to view this declaration
        if (declaration.applicant_user_id !== userId) {
            res.status(403).json({ message: 'Forbidden: You do not have access to this declaration' });
            return;
        }
        const declarationDocuments = await documentService.getDeclarationDocumentsStatus(declarationId);
        if (!declarationDocuments) {
            res.status(404).json({ message: 'Declaration documents not found' });
            return;
        }
        const response = {
            ...declaration,
            documents: declarationDocuments
         };
        res.status(200).json(response);
    } catch (error: unknown) {  
        console.error('Controller error during declaration retrieval:', error);
        next(error);
    } 
} 

export const handleGetAllDeclarationsForUser = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try { 
        const userId = (req as any).user.userId;
        const declarations = await declarationService.getAllDeclarations();
        res.status(200).json(declarations);
    } catch (error: unknown) {
        console.error('Controller error during retrieval of all declarations for user:', error);
        next(error);
    }
} 

export const handleGetDeclarationDocumentsStatus = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try { 
        const userId = (req as any).user.userId;
        const declarationId = parseInt(req.params.declarationId, 10);
        if (isNaN(declarationId)) {
            res.status(400).json({ message: 'Invalid declaration ID' });
            return;
        }
        const declarationDocumentsStatus = await documentService.getDeclarationDocumentsStatus(declarationId);
        if (!declarationDocumentsStatus) {
            res.status(404).json({ message: 'Declaration documents status not found' });
            return;
        }
        res.status(200).json(declarationDocumentsStatus);
    } catch (error: unknown) {  
        console.error('Controller error during retrieval of declaration documents status:', error);
        next(error);
    } 
}

export const handleUploadDeclarationDocument = async (req: Request, res: Response, next: NextFunction): Promise<void> => { 
    try {
        const userId = (req as any).user.userId; // Assuming userId is on req.user from authMiddleware
        const declarationDocumentId = parseInt(req.params.declarationDocumentId, 10);

        if (isNaN(declarationDocumentId)) {
            res.status(400).json({ message: 'Invalid declaration document ID format.' });
            return;
        }

        if (!req.file) { 
            res.status(400).json({ message: 'No file uploaded. Please include a file named "documentFile".' });
            return;
        }

        const filePath = req.file.path; 
        const originalFilename = req.file.originalname; // Good to have for record-keeping if your service uses it

        const ownerApplicantId = await documentService.getApplicantUserIdForDeclarationDocument(declarationDocumentId);

        if (ownerApplicantId === null) {
            res.status(404).json({ message: 'Document record not found or invalid.' });
            return;
        }

        if (ownerApplicantId !== userId) {
            res.status(403).json({ message: 'Forbidden: You do not have permission to upload to this document record.' });
            return;
        }

        await documentService.updateDocumentOnUpload(declarationDocumentId, filePath, originalFilename);

        res.status(200).json({ message: 'Document uploaded successfully.' });

    } catch (error: unknown) {
        console.error('Controller error during document upload:', error);
        next(error);   
    }
}