import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
  Unique,
  Check,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { Event } from '../../events/entities/event.entity';

@Entity('matches')
@Unique(['user1Id', 'user2Id', 'eventId'])
@Check('"user1_id" < "user2_id"')
export class Match {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user1_id', type: 'uuid' })
  user1Id: string;

  @Column({ name: 'user2_id', type: 'uuid' })
  user2Id: string;

  @Column({ name: 'event_id', type: 'uuid' })
  eventId: string;

  @Column({ name: 'is_active', type: 'boolean', default: true })
  isActive: boolean;

  @Column({ name: 'last_message_at', type: 'timestamptz', nullable: true })
  lastMessageAt: Date | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'user1_id' })
  user1: User;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'user2_id' })
  user2: User;

  @ManyToOne(() => Event)
  @JoinColumn({ name: 'event_id' })
  event: Event;
}
