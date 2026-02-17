import {
  Controller,
  Get,
  Patch,
  Delete,
  Body,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { UsersService } from './users.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { User } from './entities/user.entity';

@ApiTags('Users')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller()
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get('me')
  @ApiOperation({ summary: 'Get current user profile' })
  async getMe(@CurrentUser() user: User) {
    const fullUser = await this.usersService.findById(user.id);
    if (!fullUser) {
      return null;
    }

    // Update last seen
    await this.usersService.updateLastSeen(user.id);

    // Remove sensitive data
    const { passwordHash, ...userData } = fullUser;
    return userData;
  }

  @Patch('me')
  @ApiOperation({ summary: 'Update current user profile' })
  async updateMe(
    @CurrentUser() user: User,
    @Body() updateDto: UpdateProfileDto,
  ) {
    const updatedUser = await this.usersService.update(user.id, updateDto);
    const { passwordHash, ...userData } = updatedUser;
    return userData;
  }

  @Delete('me')
  @ApiOperation({ summary: 'Delete current user account (GDPR)' })
  async deleteMe(@CurrentUser() user: User) {
    await this.usersService.softDelete(user.id);
    return {
      message: 'Compte supprimé. Vos données seront effacées sous 30 jours.',
    };
  }

  @Get('me/data-export')
  @ApiOperation({ summary: 'Export user data (GDPR)' })
  async exportData(@CurrentUser() user: User) {
    return this.usersService.getDataExport(user.id);
  }
}
