import { DataSource } from 'typeorm';
import * as bcrypt from 'bcryptjs';
import { v4 as uuidv4 } from 'uuid';
import { User, Gender, Orientation, UserRole } from '../../modules/users/entities/user.entity';
import { Event, EventStatus } from '../../modules/events/entities/event.entity';
import { Checkin, CheckinSource } from '../../modules/events/entities/checkin.entity';

// Photos from randomuser.me (free API for profile photos)
const femalePhotos = [
  'https://randomuser.me/api/portraits/women/1.jpg',
  'https://randomuser.me/api/portraits/women/2.jpg',
  'https://randomuser.me/api/portraits/women/3.jpg',
  'https://randomuser.me/api/portraits/women/4.jpg',
  'https://randomuser.me/api/portraits/women/5.jpg',
  'https://randomuser.me/api/portraits/women/6.jpg',
  'https://randomuser.me/api/portraits/women/7.jpg',
  'https://randomuser.me/api/portraits/women/8.jpg',
  'https://randomuser.me/api/portraits/women/9.jpg',
  'https://randomuser.me/api/portraits/women/10.jpg',
  'https://randomuser.me/api/portraits/women/11.jpg',
  'https://randomuser.me/api/portraits/women/12.jpg',
  'https://randomuser.me/api/portraits/women/13.jpg',
  'https://randomuser.me/api/portraits/women/14.jpg',
  'https://randomuser.me/api/portraits/women/15.jpg',
];

const malePhotos = [
  'https://randomuser.me/api/portraits/men/1.jpg',
  'https://randomuser.me/api/portraits/men/2.jpg',
  'https://randomuser.me/api/portraits/men/3.jpg',
  'https://randomuser.me/api/portraits/men/4.jpg',
  'https://randomuser.me/api/portraits/men/5.jpg',
  'https://randomuser.me/api/portraits/men/6.jpg',
  'https://randomuser.me/api/portraits/men/7.jpg',
  'https://randomuser.me/api/portraits/men/8.jpg',
  'https://randomuser.me/api/portraits/men/9.jpg',
  'https://randomuser.me/api/portraits/men/10.jpg',
  'https://randomuser.me/api/portraits/men/11.jpg',
  'https://randomuser.me/api/portraits/men/12.jpg',
  'https://randomuser.me/api/portraits/men/13.jpg',
  'https://randomuser.me/api/portraits/men/14.jpg',
  'https://randomuser.me/api/portraits/men/15.jpg',
];

const femaleNames = [
  'Emma', 'Lea', 'Chloe', 'Manon', 'Camille', 'Sarah', 'Julie', 'Laura',
  'Marie', 'Clara', 'Lucie', 'Pauline', 'Marine', 'Oceane', 'Lisa',
];

const maleNames = [
  'Lucas', 'Hugo', 'Nathan', 'Thomas', 'Leo', 'Theo', 'Mathis', 'Maxime',
  'Alexandre', 'Antoine', 'Julien', 'Romain', 'Nicolas', 'Pierre', 'Louis',
];

const bios = [
  "Passionee de voyages et de decouvertes. J'adore les soirees entre amis !",
  "Amateur de bonne musique et de cocktails. Toujours partant pour faire la fete.",
  "Spontane et curieux, j'aime rencontrer de nouvelles personnes.",
  "Fan de sport le jour, feter le soir. La vie est courte, profitons-en !",
  "J'adore danser et m'amuser. Cherche quelqu'un pour partager de bons moments.",
  "Gourmand et bon vivant. Les meilleures soirees sont celles qu'on n'avait pas prevues.",
  "Aventurier dans l'ame, je cherche quelqu'un pour explorer la vie nocturne.",
  "Simple, authentique et toujours de bonne humeur. Let's party !",
  "Amoureux de la vie et des belles rencontres. Swipe right si tu aimes danser !",
  "Creatif et reveur, mais toujours pret pour une soiree memorable.",
  "La vie est une fete, autant en profiter ensemble !",
  "Plutot afterwork ou rave ? Je suis ouvert aux deux !",
  "Ici pour rencontrer des gens cools et passer de bonnes soirees.",
  "Amateur de techno et de house. On se retrouve sur le dancefloor ?",
  "Epicurien convaincu. Bon vin, bonne musique, bonne compagnie.",
];

const eventNames = [
  { name: 'Nuit Electro au Warehouse', location: 'Warehouse Club', address: '42 Rue de la Roquette, Paris' },
  { name: 'Afterwork Rooftop', location: 'Le Perchoir', address: '14 Rue Crespin du Gast, Paris' },
  { name: 'Latin Night', location: 'Barrio Latino', address: '46 Rue du Faubourg Saint-Antoine, Paris' },
  { name: 'House Party', location: 'Rex Club', address: '5 Boulevard Poissonniere, Paris' },
  { name: 'Summer Vibes', location: 'Wanderlust', address: '32 Quai d\'Austerlitz, Paris' },
];

async function seed() {
  console.log('Starting database seed...');

  const dataSource = new DataSource({
    type: 'postgres',
    url: process.env.DATABASE_URL || 'postgresql://tindersoiree:tindersoiree_dev@localhost:5433/tindersoiree',
    entities: [User, Event, Checkin],
    synchronize: false,
  });

  await dataSource.initialize();
  console.log('Database connected');

  const userRepo = dataSource.getRepository(User);
  const eventRepo = dataSource.getRepository(Event);
  const checkinRepo = dataSource.getRepository(Checkin);

  // Clear existing data
  console.log('Clearing existing data...');
  await dataSource.query('DELETE FROM checkins');
  await dataSource.query('DELETE FROM matches');
  await dataSource.query('DELETE FROM swipes');
  await dataSource.query('DELETE FROM events');
  await dataSource.query('DELETE FROM users');

  // Create admin user
  const adminPassword = await bcrypt.hash('admin123', 10);
  const admin = await userRepo.save({
    id: uuidv4(),
    email: 'admin@tindersoiree.com',
    passwordHash: adminPassword,
    firstName: 'Admin',
    birthDate: new Date('1990-01-15'),
    gender: Gender.MALE,
    orientation: Orientation.EVERYONE,
    bio: 'Organisateur de soirees',
    photos: [{ url: malePhotos[0], position: 0, isMain: true }],
    role: UserRole.ADMIN,
    isVerified: true,
  });
  console.log('Admin user created:', admin.email);

  // Create test user
  const testPassword = await bcrypt.hash('test1234', 10);
  const testUser = await userRepo.save({
    id: uuidv4(),
    email: 'test@test.com',
    passwordHash: testPassword,
    firstName: 'Test',
    birthDate: new Date('1995-06-20'),
    gender: Gender.MALE,
    orientation: Orientation.WOMEN,
    bio: 'Compte de test',
    photos: [{ url: malePhotos[1], position: 0, isMain: true }],
    role: UserRole.USER,
    isVerified: true,
  });
  console.log('Test user created:', testUser.email);

  // Create female users
  const users: User[] = [admin, testUser];

  for (let i = 0; i < 15; i++) {
    const password = await bcrypt.hash('password123', 10);
    const birthYear = 1990 + Math.floor(Math.random() * 10);
    const birthMonth = Math.floor(Math.random() * 12) + 1;
    const birthDay = Math.floor(Math.random() * 28) + 1;

    const numPhotos = Math.floor(Math.random() * 3) + 1;
    const photoUrls = [];
    for (let j = 0; j < numPhotos; j++) {
      const photoIndex = (i + j) % femalePhotos.length;
      photoUrls.push({
        url: femalePhotos[photoIndex],
        position: j,
        isMain: j === 0,
      });
    }

    const user = await userRepo.save({
      id: uuidv4(),
      email: `${femaleNames[i].toLowerCase()}${i}@example.com`,
      passwordHash: password,
      firstName: femaleNames[i],
      birthDate: new Date(`${birthYear}-${birthMonth.toString().padStart(2, '0')}-${birthDay.toString().padStart(2, '0')}`),
      gender: Gender.FEMALE,
      orientation: i % 3 === 0 ? Orientation.MEN : (i % 3 === 1 ? Orientation.EVERYONE : Orientation.MEN),
      bio: bios[i % bios.length],
      photos: photoUrls,
      role: UserRole.USER,
      isVerified: Math.random() > 0.3,
    });
    users.push(user);
    console.log(`Female user created: ${user.firstName}`);
  }

  // Create male users
  for (let i = 0; i < 15; i++) {
    const password = await bcrypt.hash('password123', 10);
    const birthYear = 1988 + Math.floor(Math.random() * 12);
    const birthMonth = Math.floor(Math.random() * 12) + 1;
    const birthDay = Math.floor(Math.random() * 28) + 1;

    const numPhotos = Math.floor(Math.random() * 3) + 1;
    const photoUrls = [];
    for (let j = 0; j < numPhotos; j++) {
      const photoIndex = (i + j) % malePhotos.length;
      photoUrls.push({
        url: malePhotos[photoIndex],
        position: j,
        isMain: j === 0,
      });
    }

    const user = await userRepo.save({
      id: uuidv4(),
      email: `${maleNames[i].toLowerCase()}${i}@example.com`,
      passwordHash: password,
      firstName: maleNames[i],
      birthDate: new Date(`${birthYear}-${birthMonth.toString().padStart(2, '0')}-${birthDay.toString().padStart(2, '0')}`),
      gender: Gender.MALE,
      orientation: i % 3 === 0 ? Orientation.WOMEN : (i % 3 === 1 ? Orientation.EVERYONE : Orientation.WOMEN),
      bio: bios[i % bios.length],
      photos: photoUrls,
      role: UserRole.USER,
      isVerified: Math.random() > 0.3,
    });
    users.push(user);
    console.log(`Male user created: ${user.firstName}`);
  }

  // Create events
  const events: Event[] = [];
  for (let i = 0; i < eventNames.length; i++) {
    const eventData = eventNames[i];
    const startDate = new Date();
    startDate.setDate(startDate.getDate() + i); // Events start today and next days
    startDate.setHours(20, 0, 0, 0);

    const endDate = new Date(startDate);
    endDate.setHours(4, 0, 0, 0);
    endDate.setDate(endDate.getDate() + 1);

    const event = await eventRepo.save({
      id: uuidv4(),
      name: eventData.name,
      description: `Rejoins-nous pour une soiree incroyable au ${eventData.location} ! Ambiance garantie, rencontres assurees.`,
      locationName: eventData.location,
      locationAddress: eventData.address,
      locationLat: 48.8566 + (Math.random() - 0.5) * 0.1,
      locationLng: 2.3522 + (Math.random() - 0.5) * 0.1,
      startAt: startDate,
      endAt: endDate,
      status: i === 0 ? EventStatus.LIVE : (i < 3 ? EventStatus.LIVE : EventStatus.DRAFT),
      joinTokenSecret: uuidv4().replace(/-/g, ''),
      maxParticipants: 50 + Math.floor(Math.random() * 100),
      organizerId: admin.id,
    });
    events.push(event);
    console.log(`Event created: ${event.name}`);
  }

  // Create checkins for the first event (live event)
  const liveEvent = events[0];
  const shuffledUsers = users.sort(() => Math.random() - 0.5);
  const checkinUsers = shuffledUsers.slice(0, 20); // 20 users in the event

  for (const user of checkinUsers) {
    await checkinRepo.save({
      id: uuidv4(),
      userId: user.id,
      eventId: liveEvent.id,
      source: CheckinSource.QR,
      metadata: {},
    });
    console.log(`Checkin created for ${user.firstName} at ${liveEvent.name}`);
  }

  console.log('\n=== Seed completed successfully! ===');
  console.log(`Created ${users.length} users`);
  console.log(`Created ${events.length} events`);
  console.log(`Created ${checkinUsers.length} checkins`);
  console.log('\nTest accounts:');
  console.log('  Admin: admin@tindersoiree.com / admin123');
  console.log('  User:  test@test.com / test1234');

  await dataSource.destroy();
  process.exit(0);
}

seed().catch((error) => {
  console.error('Seed failed:', error);
  process.exit(1);
});
