import { IsUUID, IsEnum } from 'class-validator';
import { SwipeAction } from '../entities/swipe.entity';

export class CreateSwipeDto {
  @IsUUID()
  toUserId: string;

  @IsUUID()
  eventId: string;

  @IsEnum(SwipeAction)
  action: SwipeAction;
}
