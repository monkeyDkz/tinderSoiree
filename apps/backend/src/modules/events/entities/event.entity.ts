import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
  OneToMany,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';

export enum EventStatus {
  DRAFT = 'draft',
  LIVE = 'live',
  CLOSED = 'closed',
  CANCELLED = 'cancelled',
}

@Entity('events')
export class Event {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'varchar', length: 255 })
  name: string;

  @Column({ type: 'text', nullable: true })
  description: string | null;

  @Column({ name: 'location_name', type: 'varchar', length: 255 })
  locationName: string;

  @Column({ name: 'location_address', type: 'text', nullable: true })
  locationAddress: string | null;

  @Column({ name: 'location_lat', type: 'decimal', precision: 10, scale: 8, nullable: true })
  locationLat: number | null;

  @Column({ name: 'location_lng', type: 'decimal', precision: 11, scale: 8, nullable: true })
  locationLng: number | null;

  @Column({ name: 'cover_image_url', type: 'text', nullable: true })
  coverImageUrl: string | null;

  @Column({ name: 'start_at', type: 'timestamptz' })
  startAt: Date;

  @Column({ name: 'end_at', type: 'timestamptz' })
  endAt: Date;

  @Column({ type: 'enum', enum: EventStatus, default: EventStatus.DRAFT })
  status: EventStatus;

  @Column({ name: 'join_token_secret', type: 'varchar', length: 64 })
  joinTokenSecret: string;

  @Column({ name: 'join_token_expires_hours', type: 'int', default: 2 })
  joinTokenExpiresHours: number;

  @Column({ name: 'max_participants', type: 'int', nullable: true })
  maxParticipants: number | null;

  @Column({ name: 'organizer_id', type: 'uuid' })
  organizerId: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'organizer_id' })
  organizer: User;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
