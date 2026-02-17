import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, LessThanOrEqual, IsNull } from 'typeorm';
import { Message } from './entities/message.entity';
import { Match } from '../matches/entities/match.entity';
import { User } from '../users/entities/user.entity';
import { MatchesService } from '../matches/matches.service';
import { NotificationsService } from '../notifications/notifications.service';

@Injectable()
export class ChatService {
  constructor(
    @InjectRepository(Message)
    private messageRepository: Repository<Message>,
    @InjectRepository(Match)
    private matchRepository: Repository<Match>,
    @InjectRepository(User)
    private userRepository: Repository<User>,
    private matchesService: MatchesService,
    private notificationsService: NotificationsService,
  ) {}

  async getMessages(matchId: string, userId: string, limit = 50, before?: string) {
    // Verify user is in match
    await this.matchesService.verifyUserInMatch(matchId, userId);

    const query = this.messageRepository
      .createQueryBuilder('m')
      .where('m.match_id = :matchId', { matchId })
      .orderBy('m.created_at', 'DESC')
      .limit(limit + 1);

    if (before) {
      const beforeDate = new Date(before);
      query.andWhere('m.created_at < :beforeDate', { beforeDate });
    }

    const messages = await query.getMany();

    const hasMore = messages.length > limit;
    const resultMessages = messages.slice(0, limit).reverse();

    return {
      messages: resultMessages.map((m) => ({
        id: m.id,
        content: m.content,
        senderId: m.senderId,
        isFromMe: m.senderId === userId,
        readAt: m.readAt,
        createdAt: m.createdAt,
      })),
      pagination: {
        hasMore,
        oldestCursor: resultMessages[0]?.createdAt?.toISOString() || null,
      },
    };
  }

  async sendMessage(matchId: string, userId: string, content: string) {
    // Verify user is in match
    const match = await this.matchesService.verifyUserInMatch(matchId, userId);
    const otherUserId = this.matchesService.getOtherUserId(match, userId);

    const message = this.messageRepository.create({
      matchId,
      senderId: userId,
      content: content.trim(),
    });

    const savedMessage = await this.messageRepository.save(message);

    // Update last_message_at on match (trigger handles this in DB)
    await this.matchRepository.update(matchId, {
      lastMessageAt: savedMessage.createdAt,
    });

    // Send push notification to the other user
    const sender = await this.userRepository.findOne({
      where: { id: userId },
      select: ['firstName'],
    });

    if (sender) {
      this.notificationsService
        .sendNewMessageNotification(
          otherUserId,
          sender.firstName,
          content.trim(),
          matchId,
        )
        .catch((err) => console.error('Failed to send message notification:', err));
    }

    return {
      message: {
        id: savedMessage.id,
        content: savedMessage.content,
        senderId: savedMessage.senderId,
        isFromMe: true,
        createdAt: savedMessage.createdAt,
      },
    };
  }

  async markAsRead(matchId: string, userId: string, upToMessageId: string) {
    // Verify user is in match
    const match = await this.matchesService.verifyUserInMatch(matchId, userId);
    const otherUserId = this.matchesService.getOtherUserId(match, userId);

    // Get the message to get its timestamp
    const upToMessage = await this.messageRepository.findOne({
      where: { id: upToMessageId, matchId },
    });

    if (!upToMessage) {
      return { readCount: 0 };
    }

    // Mark all messages from the other user as read
    const result = await this.messageRepository.update(
      {
        matchId,
        senderId: otherUserId,
        readAt: IsNull(),
        createdAt: LessThanOrEqual(upToMessage.createdAt),
      },
      { readAt: new Date() },
    );

    return { readCount: result.affected || 0 };
  }

  async getUnreadCount(matchId: string, userId: string): Promise<number> {
    const match = await this.matchesService.verifyUserInMatch(matchId, userId);
    const otherUserId = this.matchesService.getOtherUserId(match, userId);

    return this.messageRepository.count({
      where: {
        matchId,
        senderId: otherUserId,
        readAt: IsNull(),
      },
    });
  }
}
