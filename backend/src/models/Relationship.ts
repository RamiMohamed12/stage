import {RowDataPacket} from "mysql2"; 

export interface Relationship {
    id: number; 
    description: string | null; 
} 

export interface RelationshipRow extends Relationship, RowDataPacket {}

