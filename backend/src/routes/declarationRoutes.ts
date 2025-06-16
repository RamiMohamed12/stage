import express from 'express';
import * as declarationController from '../controllers/declarationController';
import { authenticateToken } from '../middleware/authMiddleware';
import multer from 'multer';
import path from 'path';
import fs from 'fs';


// Fix: Point to the src/uploads directory instead of dist/uploads
const UPLOAD_DIR = path.join(__dirname, '../../src/uploads');


// Ensure the directory exists
if (!fs.existsSync(UPLOAD_DIR)) {
    fs.mkdirSync(UPLOAD_DIR, { recursive: true });
    console.log(`Created uploads directory at: ${UPLOAD_DIR}`);
}

console.log(`Upload directory set to: ${UPLOAD_DIR}`);

const storage = multer.diskStorage({ 
    destination: function(req, file,cb){ 
        cb(null,UPLOAD_DIR); 
    }, 
    filename: function(req,file,cb){
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname)); 
    }
})

const fileFilter = (req: express.Request, file: Express.Multer.File, cb: multer.FileFilterCallback) => {
    const allowedExtensions = /jpeg|jpg|png|pdf|doc|docx|svg|heic/i;
    const allowedMimeTypes = [
        'image/jpeg',
        'image/jpg', 
        'image/png',
        'image/svg+xml',
        'image/heic',
        'application/pdf',
        'application/msword',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
    ];
    
    const fileExtension = path.extname(file.originalname).toLowerCase();
    const isValidExtension = allowedExtensions.test(fileExtension);
    const isValidMimeType = allowedMimeTypes.includes(file.mimetype.toLowerCase());
    
    if (!isValidExtension) {
        return cb(new Error('Invalid file extension. Only JPEG, JPG, PNG, PDF, DOC, DOCX, SVG, HEIC files are allowed.'));
    }
    if (!isValidMimeType) {
        return cb(new Error('Invalid file type. Only JPEG, PNG, PDF, DOC, DOCX, SVG, HEIC files are allowed.'));
    }
    cb(null, true);
};

const upload = multer({ 
    storage: storage, 
    limits: { fileSize: 10 * 1024 * 1024 }, // Limit file size to 10MB
    fileFilter: fileFilter
});

const router = express.Router();

// Add route to check for existing declarations
router.get('/check/:pensionNumber', authenticateToken, declarationController.handleCheckDeclaration);

router.post('/', authenticateToken, declarationController.handleCreateDeclaration);

router.get('/',authenticateToken, declarationController.handleGetAllDeclarationsForUser);

router.get('/:declarationId', authenticateToken, declarationController.handleGetDeclarationById);

router.get('/:declarationId/documents', authenticateToken, declarationController.handleGetDeclarationDocumentsStatus);

// Fix: Add authentication middleware to the upload route
router.post('/documents/:declarationDocumentId/upload', 
    authenticateToken, 
    upload.single('documentFile'), 
    declarationController.handleUploadDeclarationDocument
);

// Add route for downloading formulaire
router.get('/formulaire/:declarationId', authenticateToken, declarationController.handleDownloadFormulaire);

// Get user pending declaration
router.get('/user/pending', authenticateToken, declarationController.handleGetUserPendingDeclaration);

export default router;

