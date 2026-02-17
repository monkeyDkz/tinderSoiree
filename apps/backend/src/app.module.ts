import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { EventsModule } from './modules/events/events.module';
import { SwipesModule } from './modules/swipes/swipes.module';
import { MatchesModule } from './modules/matches/matches.module';
import { ChatModule } from './modules/chat/chat.module';
import { UploadModule } from './modules/upload/upload.module';
import { AdminModule } from './modules/admin/admin.module';
import { GatewayModule } from './modules/gateway/gateway.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import configuration from './config/configuration';

@Module({
  imports: [
    // Configuration
    ConfigModule.forRoot({
      isGlobal: true,
      load: [configuration],
      envFilePath: ['.env', '../../.env'],
    }),

    // Database
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: (configService: ConfigService) => ({
        type: 'postgres',
        url: configService.get<string>('database.url') || process.env.DATABASE_URL,
        autoLoadEntities: true,
        synchronize: false, // Schema created by init.sql
        logging: configService.get<string>('nodeEnv') === 'development',
      }),
      inject: [ConfigService],
    }),

    // Feature modules
    AuthModule,
    UsersModule,
    EventsModule,
    SwipesModule,
    MatchesModule,
    ChatModule,
    UploadModule,
    AdminModule,
    GatewayModule,
    NotificationsModule,
  ],
})
export class AppModule {}
