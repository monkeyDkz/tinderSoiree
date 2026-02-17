import {
  WebSocketGateway,
  WebSocketServer,
  OnGatewayConnection,
  OnGatewayDisconnect,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';

interface AuthenticatedSocket extends Socket {
  userId?: string;
  eventId?: string;
}

@WebSocketGateway({
  cors: {
    origin: '*',
    credentials: true,
  },
  transports: ['websocket', 'polling'],
})
export class AppGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private userSockets: Map<string, Set<string>> = new Map();

  constructor(
    private jwtService: JwtService,
    private configService: ConfigService,
  ) {}

  async handleConnection(socket: AuthenticatedSocket) {
    try {
      const token =
        socket.handshake.auth?.token ||
        socket.handshake.headers?.authorization?.replace('Bearer ', '');

      if (!token) {
        socket.emit('error', { code: 'UNAUTHORIZED', message: 'Token requis' });
        socket.disconnect();
        return;
      }

      const payload = this.jwtService.verify(token, {
        secret: this.configService.get<string>('jwt.secret'),
      });

      socket.userId = payload.sub;

      // Join user room
      socket.join(`user:${socket.userId}`);

      // Track socket
      const userId = socket.userId!;
      if (!this.userSockets.has(userId)) {
        this.userSockets.set(userId, new Set());
      }
      this.userSockets.get(userId)!.add(socket.id);

      socket.emit('connected', { userId: socket.userId });

      console.log(`User ${socket.userId} connected (socket: ${socket.id})`);
    } catch (error) {
      socket.emit('error', { code: 'INVALID_TOKEN', message: 'Token invalide' });
      socket.disconnect();
    }
  }

  handleDisconnect(socket: AuthenticatedSocket) {
    if (socket.userId) {
      const userSocketIds = this.userSockets.get(socket.userId);
      if (userSocketIds) {
        userSocketIds.delete(socket.id);
        if (userSocketIds.size === 0) {
          this.userSockets.delete(socket.userId);
        }
      }

      if (socket.eventId) {
        socket.leave(`event:${socket.eventId}`);
      }

      console.log(`User ${socket.userId} disconnected (socket: ${socket.id})`);
    }
  }

  @SubscribeMessage('event:join')
  handleEventJoin(
    @ConnectedSocket() socket: AuthenticatedSocket,
    @MessageBody() data: { eventId: string },
  ) {
    if (socket.eventId) {
      socket.leave(`event:${socket.eventId}`);
    }

    socket.eventId = data.eventId;
    socket.join(`event:${data.eventId}`);

    socket.emit('event:joined', { eventId: data.eventId });
  }

  @SubscribeMessage('event:leave')
  handleEventLeave(@ConnectedSocket() socket: AuthenticatedSocket) {
    if (socket.eventId) {
      socket.leave(`event:${socket.eventId}`);
      socket.emit('event:left', { eventId: socket.eventId });
      socket.eventId = undefined;
    }
  }

  @SubscribeMessage('chat:typing')
  handleTyping(
    @ConnectedSocket() socket: AuthenticatedSocket,
    @MessageBody() data: { matchId: string; isTyping: boolean },
  ) {
    // Broadcast to match room (both users)
    this.server.to(`match:${data.matchId}`).emit('chat:typing', {
      matchId: data.matchId,
      userId: socket.userId,
      isTyping: data.isTyping,
    });
  }

  // Public methods for services to call

  broadcastToEvent(eventId: string, event: string, payload: any): void {
    this.server.to(`event:${eventId}`).emit(event, payload);
  }

  sendToUser(userId: string, event: string, payload: any): void {
    this.server.to(`user:${userId}`).emit(event, payload);
  }

  sendToMatch(matchId: string, event: string, payload: any): void {
    this.server.to(`match:${matchId}`).emit(event, payload);
  }

  isUserOnline(userId: string): boolean {
    return this.userSockets.has(userId) && this.userSockets.get(userId)!.size > 0;
  }

  // Emit match created to both users
  emitMatchCreated(
    user1Id: string,
    user2Id: string,
    matchId: string,
    user1Info: any,
    user2Info: any,
    eventId: string,
  ) {
    this.sendToUser(user1Id, 'match:created', {
      matchId,
      user: user2Info,
      eventId,
      createdAt: new Date(),
    });

    this.sendToUser(user2Id, 'match:created', {
      matchId,
      user: user1Info,
      eventId,
      createdAt: new Date(),
    });
  }

  // Emit new message
  emitNewMessage(matchId: string, senderId: string, receiverId: string, message: any) {
    this.sendToUser(receiverId, 'chat:message', {
      matchId,
      message,
    });
  }
}
