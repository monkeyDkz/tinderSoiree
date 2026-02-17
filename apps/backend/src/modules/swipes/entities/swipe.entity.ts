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

export enum SwipeAction {
  LIKE = 'like',
  DISLIKE = 'dislike',
}

@Entity('swipes')
@Unique(['fromUserId', 'toUserId', 'eventId'])
@Check('"from_user_id" != "to_user_id"')
export class Swipe {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'from_user_id', type: 'uuid' })
  fromUserId: string;

  @Column({ name: 'to_user_id', type: 'uuid' })
  toUserId: string;

  @Column({ name: 'event_id', type: 'uuid' })
  eventId: string;

  @Column({ type: 'enum', enum: SwipeAction })
  action: SwipeAction;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'from_user_id' })
  fromUser: User;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'to_user_id' })
  toUser: User;

  @ManyToOne(() => Event)
  @JoinColumn({ name: 'event_id' })
  event: Event;
}
