import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Match } from './entities/match.entity';
import { User } from '../users/entities/user.entity';
import { MatchesService } from './matches.service';
import { MatchesController } from './matches.controller';

@Module({
  imports: [TypeOrmModule.forFeature([Match, User])],
  controllers: [MatchesController],
  providers: [MatchesService],
  exports: [MatchesService],
})
export class MatchesModule {}
