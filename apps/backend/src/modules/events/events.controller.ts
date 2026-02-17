import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  UseGuards,
  Req,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { Request } from 'express';
import { EventsService } from './events.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JoinEventDto } from './dto/join-event.dto';

@ApiTags('Events')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('events')
export class EventsController {
  constructor(private readonly eventsService: EventsService) {}

  @Post('join')
  @ApiOperation({ summary: 'Join an event via NFC/QR token' })
  async join(
    @Body() dto: JoinEventDto,
    @CurrentUser('id') userId: string,
    @Req() req: Request,
  ) {
    const metadata = {
      ip: req.ip || 'unknown',
      userAgent: req.headers['user-agent'] || 'unknown',
    };

    return this.eventsService.join(dto, userId, metadata);
  }

  @Post('leave')
  @ApiOperation({ summary: 'Leave current event' })
  async leave(
    @Body('eventId') eventId: string,
    @CurrentUser('id') userId: string,
  ) {
    return this.eventsService.leave(eventId, userId);
  }

  @Get('current')
  @ApiOperation({ summary: 'Get current event for user' })
  async getCurrentEvent(@CurrentUser('id') userId: string) {
    return this.eventsService.getCurrentEvent(userId);
  }

  @Get('history')
  @ApiOperation({ summary: 'Get event history for user' })
  async getEventHistory(@CurrentUser('id') userId: string) {
    return this.eventsService.getEventHistory(userId);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get event details' })
  async getEvent(
    @Param('id') id: string,
    @CurrentUser('id') userId: string,
  ) {
    const event = await this.eventsService.findById(id);
    if (!event) {
      return null;
    }

    const checkin = await this.eventsService.getActiveCheckin(userId, id);
    const participantCount = await this.eventsService.getParticipantCount(id);

    return {
      ...event,
      participantCount,
      myCheckin: checkin
        ? { id: checkin.id, joinedAt: checkin.joinedAt }
        : null,
    };
  }

  @Get(':id/public')
  @ApiOperation({ summary: 'Get public event info (no auth required)' })
  async getPublicEvent(@Param('id') id: string) {
    const event = await this.eventsService.findById(id);
    if (!event) {
      return null;
    }

    return {
      id: event.id,
      name: event.name,
      locationName: event.locationName,
      startAt: event.startAt,
      coverImageUrl: event.coverImageUrl,
      status: event.status,
    };
  }
}
