import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User, Gender, Orientation } from '../users/entities/user.entity';
import { Checkin } from '../events/entities/checkin.entity';
import { Swipe } from './entities/swipe.entity';

export interface StackProfile {
  id: string;
  firstName: string;
  age: number;
  bio: string | null;
  photos: { url: string; isMain: boolean }[];
  gender: Gender;
}

interface GetStackParams {
  userId: string;
  eventId: string;
  userGender: Gender;
  userOrientation: Orientation;
  limit: number;
  cursor?: string;
}

@Injectable()
export class StackService {
  constructor(
    @InjectRepository(User)
    private userRepository: Repository<User>,
    @InjectRepository(Checkin)
    private checkinRepository: Repository<Checkin>,
    @InjectRepository(Swipe)
    private swipeRepository: Repository<Swipe>,
  ) {}

  async getStack(params: GetStackParams) {
    const { userId, eventId, userGender, userOrientation, limit, cursor } = params;

    // Build query - include all users who participated in the event (not just active ones)
    // This allows users to keep matching even after the event ends
    let query = this.userRepository
      .createQueryBuilder('u')
      .innerJoin(
        Checkin,
        'c',
        'c.user_id = u.id AND c.event_id = :eventId',
        { eventId },
      )
      .where('u.id != :userId', { userId })
      .andWhere('u.is_active = true')
      .andWhere(
        `NOT EXISTS (
          SELECT 1 FROM swipes s
          WHERE s.from_user_id = :userId
            AND s.to_user_id = u.id
            AND s.event_id = :eventId
        )`,
        { userId, eventId },
      );

    // Orientation filter
    query = this.applyOrientationFilter(query, userGender, userOrientation);

    // Cursor pagination
    if (cursor) {
      const cursorDate = new Date(Buffer.from(cursor, 'base64').toString());
      query = query.andWhere('c.joined_at < :cursorDate', { cursorDate });
    }

    // Count total
    const totalCount = await query.getCount();

    // Get profiles
    const rawProfiles = await query
      .select([
        'u.id AS id',
        'u.first_name AS "firstName"',
        'u.birth_date AS "birthDate"',
        'u.bio AS bio',
        'u.photos AS photos',
        'u.gender AS gender',
        'c.joined_at AS "joinedAt"',
      ])
      .orderBy('c.joined_at', 'DESC')
      .addOrderBy('RANDOM()')
      .limit(limit + 1)
      .getRawMany();

    const hasMore = rawProfiles.length > limit;
    const resultProfiles = rawProfiles.slice(0, limit);

    // Transform profiles
    const profiles: StackProfile[] = resultProfiles.map((row) => ({
      id: row.id,
      firstName: row.firstName,
      age: row.birthDate ? this.calculateAge(new Date(row.birthDate)) : 0,
      bio: row.bio,
      photos: row.photos || [],
      gender: row.gender,
    }));

    // Generate next cursor
    let nextCursor: string | null = null;
    if (hasMore && resultProfiles.length > 0) {
      const lastProfile = resultProfiles[resultProfiles.length - 1];
      nextCursor = Buffer.from(
        new Date(lastProfile.joinedAt).toISOString(),
      ).toString('base64');
    }

    return {
      profiles,
      pagination: {
        nextCursor,
        hasMore,
        remainingCount: Math.max(0, totalCount - limit),
      },
    };
  }

  private applyOrientationFilter(
    query: any,
    userGender: Gender,
    userOrientation: Orientation,
  ) {
    // What the current user wants to see
    const wantToSee = this.getGenderCondition(userOrientation);
    if (wantToSee) {
      query = query.andWhere(wantToSee);
    }

    // What users are interested in the current user's gender
    const interestedIn = this.getOrientationCondition(userGender);
    if (interestedIn) {
      query = query.andWhere(interestedIn);
    }

    return query;
  }

  private getGenderCondition(orientation: Orientation): string | null {
    switch (orientation) {
      case Orientation.MEN:
        return "u.gender = 'male'";
      case Orientation.WOMEN:
        return "u.gender = 'female'";
      default:
        return null;
    }
  }

  private getOrientationCondition(gender: Gender): string | null {
    switch (gender) {
      case Gender.MALE:
        return "(u.orientation = 'men' OR u.orientation = 'everyone')";
      case Gender.FEMALE:
        return "(u.orientation = 'women' OR u.orientation = 'everyone')";
      default:
        return "u.orientation = 'everyone'";
    }
  }

  private calculateAge(birthDate: Date): number {
    const today = new Date();
    let age = today.getFullYear() - birthDate.getFullYear();
    const monthDiff = today.getMonth() - birthDate.getMonth();
    if (
      monthDiff < 0 ||
      (monthDiff === 0 && today.getDate() < birthDate.getDate())
    ) {
      age--;
    }
    return age;
  }
}
