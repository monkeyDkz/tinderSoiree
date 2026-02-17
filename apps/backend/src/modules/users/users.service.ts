import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './entities/user.entity';
import { UpdateProfileDto } from './dto/update-profile.dto';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private usersRepository: Repository<User>,
  ) {}

  async findById(id: string): Promise<User | null> {
    return this.usersRepository.findOne({
      where: { id, isActive: true },
    });
  }

  async findByEmail(email: string): Promise<User | null> {
    return this.usersRepository.findOne({
      where: { email, isActive: true },
    });
  }

  async findByPhone(phone: string): Promise<User | null> {
    return this.usersRepository.findOne({
      where: { phone, isActive: true },
    });
  }

  async findByAppleId(appleId: string): Promise<User | null> {
    return this.usersRepository.findOne({
      where: { appleId, isActive: true },
    });
  }

  async create(data: Partial<User>): Promise<User> {
    const user = this.usersRepository.create(data);
    return this.usersRepository.save(user);
  }

  async update(id: string, data: UpdateProfileDto): Promise<User> {
    const user = await this.findById(id);
    if (!user) {
      throw new NotFoundException('User not found');
    }

    Object.assign(user, data);
    return this.usersRepository.save(user);
  }

  async updateLastSeen(id: string): Promise<void> {
    await this.usersRepository.update(id, { lastSeenAt: new Date() });
  }

  async softDelete(id: string): Promise<void> {
    await this.usersRepository.update(id, {
      deletedAt: new Date(),
      isActive: false,
    });
  }

  async getDataExport(id: string): Promise<any> {
    const user = await this.usersRepository.findOne({
      where: { id },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Remove sensitive data
    const { passwordHash, ...userData } = user;

    return {
      user: userData,
      exportedAt: new Date().toISOString(),
    };
  }
}
