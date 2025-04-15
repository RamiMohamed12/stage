import bcrypt from 'bcrypt';

const SALT_ROUND: number = 12; 

export const hashPassword = async (password: string): Promise<string> => {
    
    try { 
    const salt = await bcrypt.genSalt(SALT_ROUND);
    const hash = await bcrypt.hash(password, salt);
    return hash;
    } catch (error) {
        if (error instanceof Error) {
            throw new Error('Error hashing password: ' + error.message);
        }
        throw new Error('Error hashing password: Unknown error');
    }
}

export const comparePassword = async (password: string, hash: string): Promise<boolean> => {
    
    try { 
    const isMatch = await bcrypt.compare(password, hash);
    return isMatch;
    } catch (error) {
        if (error instanceof Error) {
            throw new Error('Error comparing password: ' + error.message);
        }
        throw new Error('Error comparing password: Unknown error');
    } 

}