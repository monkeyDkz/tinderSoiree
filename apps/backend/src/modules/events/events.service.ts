import {
  Injectable,
  BadRequestException,
  ConflictException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, IsNull } from 'typeorm';
import { Event, EventStatus } from './entities/event.entity';
import { Checkin } from './entities/checkin.entity';
import { TokenService } from './token.service';
import { CreateEventDto } from './dto/create-event.dto';
import { JoinEventDto } from './dto/join-event.dto';

@Injectable()
export class EventsService {
  constructor(
    @InjectRepository(Event)
    private eventRepository: Repository<Event>,
    @InjectRepository(Checkin)
    private checkinRepository: Repository<Checkin>,
    private tokenService: TokenService,
  ) {}

  async create(dto: CreateEventDto, organizerId: string): Promise<Event> {
    const startAt = new Date(dto.startAt);
    const endAt = new Date(dto.endAt);

    if (endAt <= startAt) {
      throw new BadRequestException({
        code: 'INVALID_DATES',
        message: 'End date must be after start date',
      });
    }

    const event = this.eventRepository.create({
      ...dto,
      startAt,
      endAt,
      organizerId,
      joinTokenSecret: this.tokenService.generateEventSecret(),
    });

    return this.eventRepository.save(event);
  }

  async findById(id: string): Promise<Event | null> {
    return this.eventRepository.findOne({ where: { id } });
  }

  async findByOrganizer(organizerId: string): Promise<Event[]> {
    return this.eventRepository.find({
      where: { organizerId },
      order: { createdAt: 'DESC' },
    });
  }

  async publish(id: string, organizerId: string): Promise<Event> {
    const event = await this.findById(id);

    if (!event) {
      throw new NotFoundException('Event not found');
    }

    if (event.organizerId !== organizerId) {
      throw new ForbiddenException('Not authorized');
    }

    if (event.status !== EventStatus.DRAFT) {
      throw new BadRequestException({
        code: 'INVALID_STATUS',
        message: 'Only draft events can be published',
      });
    }

    event.status = EventStatus.LIVE;
    return this.eventRepository.save(event);
  }

  async close(id: string, organizerId: string): Promise<Event> {
    const event = await this.findById(id);

    if (!event) {
      throw new NotFoundException('Event not found');
    }

    if (event.organizerId !== organizerId) {
      throw new ForbiddenException('Not authorized');
    }

    if (event.status !== EventStatus.LIVE) {
      throw new BadRequestException({
        code: 'INVALID_STATUS',
        message: 'Only live events can be closed',
      });
    }

    event.status = EventStatus.CLOSED;
    return this.eventRepository.save(event);
  }

  async getJoinToken(id: string, organizerId: string): Promise<string> {
    const event = await this.findById(id);

    if (!event) {
      throw new NotFoundException('Event not found');
    }

    if (event.organizerId !== organizerId) {
      throw new ForbiddenException('Not authorized');
    }

    return this.tokenService.generateJoinToken(
      event.id,
      event.joinTokenSecret,
      event.joinTokenExpiresHours,
    );
  }

  async getJoinUrl(id: string, organizerId: string): Promise<string> {
    const token = await this.getJoinToken(id, organizerId);
    return this.tokenService.buildJoinUrl(id, token);
  }

  async getDeepLinkUrl(id: string, organizerId: string): Promise<string> {
    const token = await this.getJoinToken(id, organizerId);
    return this.tokenService.buildDeepLinkUrl(id, token);
  }

  async join(
    dto: JoinEventDto,
    userId: string,
    metadata: { ip: string; userAgent: string },
  ) {
    const event = await this.findById(dto.eventId);

    if (!event) {
      throw new NotFoundException({
        code: 'EVENT_NOT_FOUND',
        message: 'Soirée introuvable',
      });
    }

    if (event.status !== EventStatus.LIVE) {
      throw new ForbiddenException({
        code: 'EVENT_NOT_LIVE',
        message:
          event.status === EventStatus.DRAFT
            ? "Cette soirée n'a pas encore commencé"
            : 'Cette soirée est terminée',
      });
    }

    const now = new Date();
    if (now > event.endAt) {
      throw new ForbiddenException({
        code: 'EVENT_ENDED',
        message: 'Cette soirée est terminée',
      });
    }

    // Validate token
    const tokenValidation = this.tokenService.validateJoinToken(
      dto.token,
      dto.eventId,
      event.joinTokenSecret,
    );

    if (!tokenValidation.valid) {
      throw new BadRequestException({
        code: 'INVALID_JOIN_TOKEN',
        message: this.getTokenErrorMessage(tokenValidation.error),
      });
    }

    // Check existing checkin
    const existingCheckin = await this.checkinRepository.findOne({
      where: { userId, eventId: dto.eventId },
    });

    if (existingCheckin) {
      if (existingCheckin.leftAt === null) {
        throw new ConflictException({
          code: 'ALREADY_CHECKED_IN',
          message: 'Vous êtes déjà inscrit à cette soirée',
        });
      }

      // Re-join
      existingCheckin.leftAt = null;
      existingCheckin.joinedAt = new Date();
      existingCheckin.source = dto.source;
      existingCheckin.metadata = metadata;

      const updatedCheckin = await this.checkinRepository.save(existingCheckin);
      return { checkin: updatedCheckin, event };
    }

    // Create new checkin
    const checkin = this.checkinRepository.create({
      userId,
      eventId: dto.eventId,
      source: dto.source,
      metadata,
    });

    const savedCheckin = await this.checkinRepository.save(checkin);
    return { checkin: savedCheckin, event };
  }

  async leave(eventId: string, userId: string) {
    const checkin = await this.checkinRepository.findOne({
      where: { userId, eventId, leftAt: IsNull() },
    });

    if (!checkin) {
      throw new NotFoundException({
        code: 'NOT_CHECKED_IN',
        message: "Vous n'êtes pas inscrit à cette soirée",
      });
    }

    checkin.leftAt = new Date();
    await this.checkinRepository.save(checkin);

    return { message: 'Vous avez quitté la soirée' };
  }

  async getCurrentEvent(userId: string) {
    const checkin = await this.checkinRepository.findOne({
      where: { userId, leftAt: IsNull() },
      relations: ['event'],
    });

    if (!checkin) {
      return null;
    }

    return {
      event: checkin.event,
      checkin: {
        id: checkin.id,
        joinedAt: checkin.joinedAt,
        source: checkin.source,
      },
    };
  }

  async getEventHistory(userId: string) {
    const checkins = await this.checkinRepository.find({
      where: { userId },
      relations: ['event'],
      order: { joinedAt: 'DESC' },
    });

    return {
      events: checkins.map((checkin) => ({
        event: checkin.event,
        checkin: {
          id: checkin.id,
          joinedAt: checkin.joinedAt,
          leftAt: checkin.leftAt,
          source: checkin.source,
        },
      })),
    };
  }

  async getParticipantCount(eventId: string): Promise<number> {
    return this.checkinRepository.count({
      where: { eventId, leftAt: IsNull() },
    });
  }

  async getActiveCheckin(userId: string, eventId: string): Promise<Checkin | null> {
    return this.checkinRepository.findOne({
      where: { userId, eventId, leftAt: IsNull() },
    });
  }

  async getAnyCheckin(userId: string, eventId: string): Promise<Checkin | null> {
    return this.checkinRepository.findOne({
      where: { userId, eventId },
    });
  }

  private getTokenErrorMessage(error: string): string {
    switch (error) {
      case 'TOKEN_EXPIRED':
        return "Ce lien a expiré. Demandez un nouveau lien à l'organisateur.";
      case 'EVENT_MISMATCH':
        return 'Ce lien ne correspond pas à cette soirée.';
      default:
        return 'Lien invalide. Vérifiez que vous avez le bon lien.';
    }
  }

  async delete(eventId: string, organizerId: string): Promise<void> {
    const event = await this.eventRepository.findOne({
      where: { id: eventId, organizerId },
    });

    if (!event) {
      throw new NotFoundException({
        code: 'EVENT_NOT_FOUND',
        message: 'Événement introuvable',
      });
    }

    if (event.status !== EventStatus.DRAFT) {
      throw new ForbiddenException({
        code: 'CANNOT_DELETE_PUBLISHED_EVENT',
        message: 'Seuls les événements en brouillon peuvent être supprimés',
      });
    }

    await this.eventRepository.remove(event);
  }
}
