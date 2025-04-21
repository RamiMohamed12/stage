import {RowDataPacket} from 'mysql2';

export interface DeathCause { 
    id: number; 
    cause_name: string; 
}

export interface DeathCauseRow extends DeathCause, RowDataPacket {}