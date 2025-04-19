import {RowDataPacket} from 'mysql2';

export interface Agency {
    agency_id: number; 
    name_agency: string; 
}

export interface AgencyRow extends Agency, RowDataPacket {}

