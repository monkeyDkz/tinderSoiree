import {
  IsString,
  IsOptional,
  IsEnum,
  IsArray,
  ValidateNested,
  MaxLength,
  ArrayMaxSize,
} from 'class-validator';
import { Type } from 'class-transformer';
import { Orientation } from '../entities/user.entity';

class PhotoDto {
  @IsString()
  url: string;

  @IsOptional()
  position?: number;

  @IsOptional()
  isMain?: boolean;
}

export class UpdateProfileDto {
  @IsOptional()
  @IsString()
  @MaxLength(100)
  firstName?: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  bio?: string;

  @IsOptional()
  @IsEnum(Orientation)
  orientation?: Orientation;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(6)
  @ValidateNested({ each: true })
  @Type(() => PhotoDto)
  photos?: PhotoDto[];
}
