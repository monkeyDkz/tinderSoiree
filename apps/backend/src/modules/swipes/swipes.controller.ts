import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Query,
  UseGuards,
  ForbiddenException,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { SwipesService } from './swipes.service';
import { StackService } from './stack.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { CreateSwipeDto } from './dto/create-swipe.dto';
import { StackResponseDto } from './dto/stack-response.dto';
import { EventsService } from '../events/events.service';
import { UsersService } from '../users/users.service';

@ApiTags('Swipes')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller()
export class SwipesController {
  constructor(
    private readonly swipesService: SwipesService,
    private readonly stackService: StackService,
    private readonly eventsService: EventsService,
    private readonly usersService: UsersService,
  ) {}

  @Get('events/:id/stack')
  @ApiOperation({ summary: 'Get stack of profiles to swipe' })
  async getStack(
    @Param('id') eventId: string,
    @CurrentUser('id') userId: string,
    @Query('limit') limit?: number,
    @Query('cursor') cursor?: string,
  ): Promise<StackResponseDto> {
    // Verify user has participated in this event (active or not)
    // Users can continue swiping even after leaving or event ends
    const checkin = await this.eventsService.getAnyCheckin(userId, eventId);
    if (!checkin) {
      throw new ForbiddenException({
        code: 'NOT_CHECKED_IN',
        message: 'Vous devez avoir participé à cette soirée',
      });
    }

    // Get user for orientation filter
    const user = await this.usersService.findById(userId);
    if (!user) {
      throw new ForbiddenException('User not found');
    }

    return this.stackService.getStack({
      userId,
      eventId,
      userGender: user.gender,
      userOrientation: user.orientation,
      limit: Math.min(limit || 10, 50),
      cursor,
    });
  }

  @Post('swipes')
  @ApiOperation({ summary: 'Create a swipe (like/dislike)' })
  async createSwipe(
    @Body() dto: CreateSwipeDto,
    @CurrentUser('id') userId: string,
  ) {
    return this.swipesService.createSwipe(userId, dto);
  }
}
