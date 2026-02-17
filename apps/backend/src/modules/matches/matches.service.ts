import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Match } from './entities/match.entity';
import { User } from '../users/entities/user.entity';

@Injectable()
export class MatchesService {
  constructor(
    @InjectRepository(Match)
    private matchRepository: Repository<Match>,
    @InjectRepository(User)
    private userRepository: Repository<User>,
  ) {}

  async findByUser(userId: string, eventId?: string) {
    const query = this.matchRepository
      .createQueryBuilder('m')
      .where('(m.user1_id = :userId OR m.user2_id = :userId)', { userId })
      .andWhere('m.is_active = true')
      .orderBy('m.last_message_at', 'DESC', 'NULLS LAST')
      .addOrderBy('m.created_at', 'DESC');

    if (eventId) {
      query.andWhere('m.event_id = :eventId', { eventId });
    }

    const matches = await query.getMany();

    // Get user details for each match
    const result = await Promise.all(
      matches.map(async (match) => {
        const otherUserId =
          match.user1Id === userId ? match.user2Id : match.user1Id;

        const otherUser = await this.userRepository.findOne({
          where: { id: otherUserId },
          select: ['id', 'firstName', 'photos'],
        });

        return {
          id: match.id,
          user: otherUser,
          eventId: match.eventId,
          lastMessageAt: match.lastMessageAt,
          createdAt: match.createdAt,
        };
      }),
    );

    return { matches: result };
  }

  async findById(id: string, userId: string) {
    const match = await this.matchRepository.findOne({
      where: { id },
    });

    if (!match) {
      throw new NotFoundException('Match not found');
    }

    // Verify user is part of the match
    if (match.user1Id !== userId && match.user2Id !== userId) {
      throw new ForbiddenException('Not authorized');
    }

    const otherUserId =
      match.user1Id === userId ? match.user2Id : match.user1Id;

    const otherUser = await this.userRepository.findOne({
      where: { id: otherUserId },
      select: ['id', 'firstName', 'bio', 'photos', 'birthDate'],
    });

    return {
      id: match.id,
      user: otherUser
        ? {
            ...otherUser,
            age: this.calculateAge(new Date(otherUser.birthDate)),
          }
        : null,
      eventId: match.eventId,
      createdAt: match.createdAt,
    };
  }

  async verifyUserInMatch(matchId: string, userId: string): Promise<Match> {
    const match = await this.matchRepository.findOne({
      where: { id: matchId },
    });

    if (!match) {
      throw new NotFoundException('Match not found');
    }

    if (match.user1Id !== userId && match.user2Id !== userId) {
      throw new ForbiddenException('Not authorized');
    }

    return match;
  }

  getOtherUserId(match: Match, userId: string): string {
    return match.user1Id === userId ? match.user2Id : match.user1Id;
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
