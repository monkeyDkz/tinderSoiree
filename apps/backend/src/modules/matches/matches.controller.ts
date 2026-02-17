import {
  Controller,
  Get,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { MatchesService } from './matches.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@ApiTags('Matches')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('matches')
export class MatchesController {
  constructor(private readonly matchesService: MatchesService) {}

  @Get()
  @ApiOperation({ summary: 'Get all matches for current user' })
  async getMatches(
    @CurrentUser('id') userId: string,
    @Query('eventId') eventId?: string,
  ) {
    return this.matchesService.findByUser(userId, eventId);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get match details' })
  async getMatch(
    @Param('id') id: string,
    @CurrentUser('id') userId: string,
  ) {
    return this.matchesService.findById(id, userId);
  }
}
