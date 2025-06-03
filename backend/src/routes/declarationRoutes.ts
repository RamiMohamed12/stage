import express from 'express';
import * as declarationController from '../controllers/declarationController';
import { authenticateToken } from '../middleware/authMiddleware';
import multer from 'multer';
import path from 'path';
import fs from 'fs';


const UPLOAD_DIR = path.join(__dirname, '../uploads');

if (!fs.existsSync(UPLOAD_DIR)) {
    fs.mkdirSync(UPLOAD_DIR, { recursive: true });
}

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
    const allowedFileTypes = /jpeg|jpg|png|pdf|doc|docx|svg|heic|/i; 
    if (!allowedFileTypes.test(path.extname(file.originalname).toLowerCase())) {
        return cb(new Error('Invalid file type. Only JPEG, PNG, PDF, DOC, DOCX, SVG, HEIC files are allowed.'));
    }
    if (!allowedFileTypes.test(file.mimetype)) {
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
// Middleware to authenticate token
router.use(authenticateToken);

// Add route to check for existing declarations
router.get('/check/:pensionNumber', authenticateToken, declarationController.handleCheckDeclaration);

router.post('/', authenticateToken, declarationController.handleCreateDeclaration);

router.get('/',authenticateToken, declarationController.handleGetAllDeclarationsForUser);

router.get('/:declarationId', authenticateToken, declarationController.handleGetDeclarationById);

router.get('/:declarationId/documents', authenticateToken, declarationController.handleGetDeclarationDocumentsStatus);

router.post('/:declarationDocumentId/upload', authenticateToken, upload.single('documentFile'), declarationController.handleUploadDeclarationDocument);

export default router;

