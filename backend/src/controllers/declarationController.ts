import {Request, Response, NextFunction} from "express";
import * as declarationService from '../services/declarationService';
import { CreateDeclarationInput, Status } from "../models/Declarations";
import * as documentService from '../services/documentService';
import * as usersService from '../services/usersService'; // Add this import
import {RowDataPacket} from 'mysql2/promise';
import {ServiceErorr} from '../services/usersService';
import * as path from 'path';
import * as fs from 'fs';
import archiver from 'archiver'; // Changed to default import


export const handleCheckDeclaration = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const userId = (req as any).user.userId;
        const pensionNumber = req.params.pensionNumber;

        if (!pensionNumber) {
            res.status(400).json({ message: 'Pension number is required' });
            return;
        }

        const checkResult = await declarationService.checkExistingDeclaration(pensionNumber, userId);
        
        res.status(200).json({
            success: true,
            ...checkResult
        });
        
    } catch (error: unknown) {
        console.error('Controller error during declaration check:', error);
        next(error);
    }
}

export const handleCreateDeclaration = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try { 
        const userId = (req as any).user.userId;
        const { decujus_pension_number, relationship_id, death_cause_id, declaration_date, status } = req.body;
        
        // First check if declaration already exists
        const checkResult = await declarationService.checkExistingDeclaration(decujus_pension_number, userId);
        
        if (checkResult.exists && checkResult.declaration) {
            if (checkResult.declaration.applicant_user_id === userId) {
                // User's own existing declaration - return it with documents and user info
                const declarationDocuments = await documentService.getDeclarationDocumentsStatus(checkResult.declaration.declaration_id);
                
                // Get user information for declarant name
                const user = await usersService.getUserbyId(userId);
                const declarantName = user ? `${user.first_name || ''} ${user.last_name || ''}`.trim() || 'Unknown' : 'Unknown';
                
                res.status(200).json({
                    success: true,
                    message: checkResult.message,
                    declaration: {
                        ...checkResult.declaration,
                        declarant_name: declarantName
                    },
                    documents: declarationDocuments,
                    isExisting: true
                });
                return;
            } else {
                // Another user's declaration
                res.status(409).json({
                    success: false,
                    message: checkResult.message
                });
                return;
            }
        }
        
        // Create new declaration if none exists
        const declarationInput: CreateDeclarationInput = {
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
        
        // Get the created declaration with documents
        const declarationDocuments = await documentService.getDeclarationDocumentsStatus(createdDeclaration.declaration_id);
        
        // Get user information for declarant name
        const user = await usersService.getUserbyId(userId);
        const declarantName = user ? `${user.first_name || ''} ${user.last_name || ''}`.trim() || 'Unknown' : 'Unknown';
        
        res.status(201).json({
            success: true,
            message: 'Declaration created successfully',
            declaration: {
                ...createdDeclaration,
                declarant_name: declarantName
            },
            documents: declarationDocuments,
            isExisting: false
        });
        
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
        
        // Get user information for declarant name
        const user = await usersService.getUserbyId(userId);
        const declarantName = user ? `${user.first_name || ''} ${user.last_name || ''}`.trim() || 'Unknown' : 'Unknown';
        
        const response = {
            ...declaration,
            declarant_name: declarantName,
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

export const handleDownloadFormulaire = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const userId = (req as any).user.userId;
        const declarationId = parseInt(req.params.declarationId, 10);
        
        if (isNaN(declarationId)) {
            res.status(400).json({ message: 'Invalid declaration ID' });
            return;
        }
        
        // Verify the user has access to this declaration
        const declaration = await declarationService.getDeclarationById(declarationId);
        if (!declaration) {
            res.status(404).json({ message: 'Declaration not found' });
            return;
        }
        
        if (declaration.applicant_user_id !== userId) {
            res.status(403).json({ message: 'Forbidden: You do not have access to this declaration' });
            return;
        }
        
        // Path to formulaire directory
        const formulaireDir = path.join(__dirname, '../../src/formulaire');
        
        // Check if formulaire images exist
        const imageFiles = ['1.jpg', '2.jpg', '3.jpg', '4.jpg'];
        const existingFiles = imageFiles.filter(file => 
            fs.existsSync(path.join(formulaireDir, file))
        );
        
        if (existingFiles.length === 0) {
            res.status(404).json({ message: 'Formulaire files not found' });
            return;
        }
        
        // Set response headers for ZIP download
        res.setHeader('Content-Type', 'application/zip');
        res.setHeader('Content-Disposition', `attachment; filename="formulaire_declaration_${declarationId}.zip"`);
        
        // Create ZIP archive
        const archive = archiver('zip', {
            zlib: { level: 9 } // Compression level
        });
        
        // Handle archive errors
        archive.on('error', (err: any) => {
            console.error('Archive error:', err);
            if (!res.headersSent) {
                res.status(500).json({ message: 'Error creating archive' });
            }
        });
        
        // Pipe archive to response
        archive.pipe(res);
        
        // Add each image file to the archive
        existingFiles.forEach(file => {
            const filePath = path.join(formulaireDir, file);
            archive.file(filePath, { name: `formulaire_page_${file}` });
        });
        
        // Finalize the archive
        await archive.finalize();
        
    } catch (error: unknown) {
        console.error('Controller error during formulaire download:', error);
        if (!res.headersSent) {
            next(error);
        }
    }
}

export const handleGetUserPendingDeclaration = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const userId = (req as any).user.userId;
        
        // Get user's most recent declaration with uploaded documents that are still pending review
        const pendingDeclaration = await declarationService.getUserPendingDeclaration(userId);
        
        if (!pendingDeclaration) {
            res.status(404).json({ message: 'No pending declarations found' });
            return;
        }
        
        // Get user information for declarant name
        const user = await usersService.getUserbyId(userId);
        const declarantName = user ? `${user.first_name || ''} ${user.last_name || ''}`.trim() || 'Unknown' : 'Unknown';
        
        res.status(200).json({
            success: true,
            declaration: {
                ...pendingDeclaration,
                declarant_name: declarantName
            }
        });
        
    } catch (error: unknown) {
        console.error('Controller error during pending declaration retrieval:', error);
        next(error);
    }
}