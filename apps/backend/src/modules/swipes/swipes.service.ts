import {
  Injectable,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
import { Swipe, SwipeAction } from './entities/swipe.entity';
import { Match } from '../matches/entities/match.entity';
import { Checkin } from '../events/entities/checkin.entity';
import { User } from '../users/entities/user.entity';
import { CreateSwipeDto } from './dto/create-swipe.dto';
import { NotificationsService } from '../notifications/notifications.service';

@Injectable()
export class SwipesService {
  constructor(
    @InjectRepository(Swipe)
    private swipeRepository: Repository<Swipe>,
    @InjectRepository(Match)
    private matchRepository: Repository<Match>,
    @InjectRepository(Checkin)
    private checkinRepository: Repository<Checkin>,
    @InjectRepository(User)
    private userRepository: Repository<User>,
    private dataSource: DataSource,
    private notificationsService: NotificationsService,
  ) {}

  async createSwipe(userId: string, dto: CreateSwipeDto) {
    const { toUserId, eventId, action } = dto;

    // Validation
    if (userId === toUserId) {
      throw new BadRequestException({
        code: 'CANNOT_SWIPE_SELF',
        message: 'Vous ne pouvez pas vous swiper vous-même',
      });
    }

    // Use transaction for atomicity
    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction('SERIALIZABLE');

    try {
      // Check checkins - allow users who have participated (not just active ones)
      // This allows matching to continue even after the event ends
      const [fromCheckin, toCheckin] = await Promise.all([
        queryRunner.manager.findOne(Checkin, {
          where: { userId, eventId },
        }),
        queryRunner.manager.findOne(Checkin, {
          where: { userId: toUserId, eventId },
        }),
      ]);

      if (!fromCheckin) {
        throw new ForbiddenException({
          code: 'NOT_CHECKED_IN',
          message: 'Vous devez avoir participé à la soirée pour swiper',
        });
      }

      if (!toCheckin) {
        throw new BadRequestException({
          code: 'TARGET_NOT_IN_EVENT',
          message: "Cette personne n'a pas participé à cette soirée",
        });
      }

      // Check existing swipe
      const existingSwipe = await queryRunner.manager.findOne(Swipe, {
        where: { fromUserId: userId, toUserId, eventId },
      });

      if (existingSwipe) {
        throw new BadRequestException({
          code: 'ALREADY_SWIPED',
          message: 'Vous avez déjà swipé cette personne',
        });
      }

      // Create swipe
      const swipe = queryRunner.manager.create(Swipe, {
        fromUserId: userId,
        toUserId,
        eventId,
        action,
      });

      await queryRunner.manager.save(swipe);

      let match: Match | null = null;
      let matched = false;

      // Check for mutual like
      if (action === SwipeAction.LIKE) {
        const reciprocalLike = await queryRunner.manager.findOne(Swipe, {
          where: {
            fromUserId: toUserId,
            toUserId: userId,
            eventId,
            action: SwipeAction.LIKE,
          },
        });

        if (reciprocalLike) {
          // Create match (order IDs)
          const [user1Id, user2Id] = [userId, toUserId].sort();

          const existingMatch = await queryRunner.manager.findOne(Match, {
            where: { user1Id, user2Id, eventId },
          });

          if (!existingMatch) {
            match = queryRunner.manager.create(Match, {
              user1Id,
              user2Id,
              eventId,
            });

            await queryRunner.manager.save(match);
            matched = true;
          }
        }
      }

      await queryRunner.commitTransaction();

      // Get matched user info if match created
      let matchedUser = null;
      if (matched && match) {
        matchedUser = await this.userRepository.findOne({
          where: { id: toUserId },
          select: ['id', 'firstName', 'photos'],
        });

        // Get current user info for notification
        const currentUser = await this.userRepository.findOne({
          where: { id: userId },
          select: ['firstName'],
        });

        // Send push notification to the other user (they just got matched!)
        if (currentUser && matchedUser) {
          this.notificationsService
            .sendNewMatchNotification(
              toUserId,
              currentUser.firstName,
              match.id,
            )
            .catch((err) => console.error('Failed to send match notification:', err));
        }
      }

      return {
        swipe: {
          id: swipe.id,
          action: swipe.action,
          createdAt: swipe.createdAt,
        },
        matched,
        match: match
          ? {
              id: match.id,
              user: matchedUser,
              createdAt: match.createdAt,
            }
          : undefined,
      };
    } catch (error) {
      await queryRunner.rollbackTransaction();
      throw error;
    } finally {
      await queryRunner.release();
    }
  }
}
