import {
  IsString,
  IsOptional,
  IsDateString,
  IsNumber,
  IsUrl,
  Min,
  Max,
  MaxLength,
} from 'class-validator';

export class CreateEventDto {
  @IsString()
  @MaxLength(255)
  name: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsString()
  @MaxLength(255)
  locationName: string;

  @IsOptional()
  @IsString()
  locationAddress?: string;

  @IsOptional()
  @IsNumber()
  locationLat?: number;

  @IsOptional()
  @IsNumber()
  locationLng?: number;

  @IsOptional()
  @IsUrl()
  coverImageUrl?: string;

  @IsDateString()
  startAt: string;

  @IsDateString()
  endAt: string;

  @IsOptional()
  @IsNumber()
  @Min(1)
  maxParticipants?: number;

  @IsOptional()
  @IsNumber()
  @Min(1)
  @Max(24)
  joinTokenExpiresHours?: number;
}
