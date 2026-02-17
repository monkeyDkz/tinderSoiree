import { IsString, IsEnum, IsUUID } from 'class-validator';
import { CheckinSource } from '../entities/checkin.entity';

export class JoinEventDto {
  @IsUUID()
  eventId: string;

  @IsString()
  token: string;

  @IsEnum(CheckinSource)
  source: CheckinSource;
}
