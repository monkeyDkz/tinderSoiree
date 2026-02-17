import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
  Unique,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { Event } from './event.entity';

export enum CheckinSource {
  NFC = 'nfc',
  QR = 'qr',
  MANUAL = 'manual',
  DEEP_LINK = 'deep_link',
}

@Entity('checkins')
@Unique(['userId', 'eventId'])
export class Checkin {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id', type: 'uuid' })
  userId: string;

  @Column({ name: 'event_id', type: 'uuid' })
  eventId: string;

  @Column({ name: 'joined_at', type: 'timestamptz', default: () => 'NOW()' })
  joinedAt: Date;

  @Column({ name: 'left_at', type: 'timestamptz', nullable: true })
  leftAt: Date | null;

  @Column({ type: 'enum', enum: CheckinSource })
  source: CheckinSource;

  @Column({ type: 'jsonb', default: {} })
  metadata: Record<string, any>;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'user_id' })
  user: User;

  @ManyToOne(() => Event)
  @JoinColumn({ name: 'event_id' })
  event: Event;
}
