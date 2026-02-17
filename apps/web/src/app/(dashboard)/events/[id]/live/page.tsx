'use client';

import { useEffect, useState } from 'react';
import { useParams } from 'next/navigation';
import Link from 'next/link';
import { useAuth } from '@/hooks/useAuth';
import { api } from '@/lib/api';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card';
import { ArrowLeft, Users, Heart, Zap, TrendingUp } from 'lucide-react';
import type { Event, EventStats } from '@/types';

export default function EventLivePage() {
  const params = useParams();
  const { token } = useAuth();
  const eventId = params.id as string;

  const [event, setEvent] = useState<Event | null>(null);
  const [stats, setStats] = useState<EventStats | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  const fetchStats = async () => {
    if (!token) return;
    try {
      const [eventData, statsData] = await Promise.all([
        api.get<Event>(`/admin/events/${eventId}`, token),
        api.get<EventStats>(`/admin/events/${eventId}/stats`, token),
      ]);
      setEvent(eventData);
      setStats(statsData);
    } catch (error) {
      console.error('Failed to fetch stats:', error);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchStats();

    // Poll every 5 seconds for live updates
    const interval = setInterval(fetchStats, 5000);
    return () => clearInterval(interval);
  }, [eventId, token]);

  if (isLoading) {
    return (
      <div className="flex justify-center py-16">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <Link
          href={`/events/${eventId}`}
          className="p-2 rounded-lg hover:bg-gray-100 transition-colors"
        >
          <ArrowLeft className="w-5 h-5" />
        </Link>
        <div className="flex-1">
          <h1 className="text-2xl font-bold text-gray-900">
            {event?.name} - Stats Live
          </h1>
          <div className="flex items-center gap-2 mt-1">
            <span className="flex items-center gap-1">
              <span className="w-2 h-2 rounded-full bg-green-500 animate-pulse" />
              <span className="text-sm text-gray-500">Temps réel</span>
            </span>
          </div>
        </div>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center gap-3">
              <div className="p-2 rounded-lg bg-blue-100">
                <Users className="w-5 h-5 text-blue-600" />
              </div>
              <div>
                <p className="text-sm text-gray-500">Participants actifs</p>
                <p className="text-2xl font-bold">
                  {stats?.checkins?.active || 0}
                </p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center gap-3">
              <div className="p-2 rounded-lg bg-green-100">
                <TrendingUp className="w-5 h-5 text-green-600" />
              </div>
              <div>
                <p className="text-sm text-gray-500">Total entrées</p>
                <p className="text-2xl font-bold">
                  {stats?.checkins?.total || 0}
                </p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center gap-3">
              <div className="p-2 rounded-lg bg-pink-100">
                <Heart className="w-5 h-5 text-pink-600" />
              </div>
              <div>
                <p className="text-sm text-gray-500">Matchs</p>
                <p className="text-2xl font-bold">
                  {stats?.activity?.totalMatches || 0}
                </p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center gap-3">
              <div className="p-2 rounded-lg bg-orange-100">
                <Zap className="w-5 h-5 text-orange-600" />
              </div>
              <div>
                <p className="text-sm text-gray-500">Taux de match</p>
                <p className="text-2xl font-bold">
                  {((stats?.activity?.matchRate || 0) * 100).toFixed(1)}%
                </p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Activity */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <Card>
          <CardHeader>
            <CardTitle>Activité</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              <div className="flex justify-between items-center">
                <span className="text-gray-600">Total swipes</span>
                <span className="font-semibold">
                  {stats?.activity?.totalSwipes || 0}
                </span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-gray-600">Total likes</span>
                <span className="font-semibold">
                  {stats?.activity?.totalLikes || 0}
                </span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-gray-600">Matchs créés</span>
                <span className="font-semibold">
                  {stats?.activity?.totalMatches || 0}
                </span>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Check-ins</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              <div className="flex justify-between items-center">
                <span className="text-gray-600">Actuellement présents</span>
                <span className="font-semibold text-green-600">
                  {stats?.checkins?.active || 0}
                </span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-gray-600">Partis</span>
                <span className="font-semibold text-gray-400">
                  {stats?.checkins?.left || 0}
                </span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-gray-600">Total</span>
                <span className="font-semibold">
                  {stats?.checkins?.total || 0}
                </span>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
