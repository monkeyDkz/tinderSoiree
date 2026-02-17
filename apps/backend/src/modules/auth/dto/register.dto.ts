import {
  IsEmail,
  IsString,
  IsEnum,
  IsDateString,
  MinLength,
  MaxLength,
  Matches,
} from 'class-validator';
import { Gender, Orientation } from '../../users/entities/user.entity';

export class RegisterDto {
  @IsEmail()
  email: string;

  @IsString()
  @MinLength(8)
  @MaxLength(100)
  @Matches(
    /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]+$/,
    {
      message:
        'Password must contain at least 1 uppercase, 1 lowercase, 1 number and 1 special character',
    },
  )
  password: string;

  @IsString()
  @MinLength(2)
  @MaxLength(100)
  firstName: string;

  @IsDateString()
  birthDate: string;

  @IsEnum(Gender)
  gender: Gender;

  @IsEnum(Orientation)
  orientation: Orientation;
}
