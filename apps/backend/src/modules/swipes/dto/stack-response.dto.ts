import { Gender } from '../../users/entities/user.entity';

export interface StackProfileDto {
  id: string;
  firstName: string;
  age: number;
  bio: string | null;
  photos: { url: string; isMain: boolean }[];
  gender: Gender;
}

export interface StackPaginationDto {
  nextCursor: string | null;
  hasMore: boolean;
  remainingCount: number;
}

export interface StackResponseDto {
  profiles: StackProfileDto[];
  pagination: StackPaginationDto;
}
