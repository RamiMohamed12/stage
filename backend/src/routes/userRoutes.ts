import express from 'express';

import {getAllUsers, createUser, updateUser, deleteUser, getUserbyID} from '../controllers/userController';
import { create } from 'domain';

const router = express.Router();

router.get('/', getAllUsers);
router.get('/', createUser);
router.get('/',updateUser);
router.get('/',deleteUser);
router.get('/',getUserbyID);

export default router;


