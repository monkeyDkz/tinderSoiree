export interface User {
  id: string;
  email: string;
  firstName: string;
  role: 'user' | 'admin' | 'super_admin';
}

export interface Event {
  id: string;
  name: string;
  description?: string;
  locationName: string;
  locationAddress?: string;
  coverImageUrl?: string;
  startAt: string;
  endAt: string;
  status: 'draft' | 'live' | 'closed' | 'cancelled';
  maxParticipants?: number;
  joinTokenExpiresHours: number;
  organizerId: string;
  createdAt: string;
  updatedAt: string;
  participantCount?: number;
  joinUrl?: string;
}

export interface EventStats {
  checkins: {
    total: number;
    active: number;
    left: number;
  };
  demographics?: {
    male: number;
    female: number;
    nonBinary: number;
  };
  activity: {
    totalSwipes: number;
    totalLikes: number;
    totalMatches: number;
    matchRate: number;
  };
}

export interface AuthResponse {
  user: User;
  tokens: {
    accessToken: string;
    refreshToken: string;
    expiresIn: number;
  };
}
