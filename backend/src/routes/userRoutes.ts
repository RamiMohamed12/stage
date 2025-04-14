import express from 'express';

import { getUser, getAllUsers, createUser, updateUser, deleteUser, getUserbyID} from '../controllers/userController';

const router = express.Router();

router.get('/', getAllUsers);
router.get('/:id', getUserbyID);
router.post('/', createUser);
router.put('/:id', updateUser);
router.delete('/:id', deleteUser);
router.get('/:id', getUser);

export default router;


