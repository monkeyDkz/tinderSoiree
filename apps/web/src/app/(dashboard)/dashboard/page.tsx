'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { useAuth } from '@/hooks/useAuth';
import { api } from '@/lib/api';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { CalendarDays, Users, Heart, Plus } from 'lucide-react';
import type { Event } from '@/types';

export default function DashboardPage() {
  const { token } = useAuth();
  const [events, setEvents] = useState<Event[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const fetchEvents = async () => {
      if (!token) return;
      try {
        const data = await api.get<{ events: Event[] }>('/admin/events', token);
        setEvents(data.events || []);
      } catch (error) {
        console.error('Failed to fetch events:', error);
      } finally {
        setIsLoading(false);
      }
    };

    fetchEvents();
  }, [token]);

  const liveEvents = events.filter((e) => e.status === 'live');
  const totalParticipants = events.reduce(
    (sum, e) => sum + (e.participantCount || 0),
    0,
  );

  return (
    <div className="space-y-8">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Dashboard</h1>
          <p className="text-gray-600">Vue d'ensemble de vos événements</p>
        </div>
        <Link href="/events/new">
          <Button>
            <Plus className="w-4 h-4 mr-2" />
            Nouvel événement
          </Button>
        </Link>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center gap-4">
              <div className="p-3 rounded-full bg-primary-100">
                <CalendarDays className="w-6 h-6 text-primary-600" />
              </div>
              <div>
                <p className="text-sm text-gray-600">Événements actifs</p>
                <p className="text-2xl font-bold">{liveEvents.length}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center gap-4">
              <div className="p-3 rounded-full bg-green-100">
                <Users className="w-6 h-6 text-green-600" />
              </div>
              <div>
                <p className="text-sm text-gray-600">Total participants</p>
                <p className="text-2xl font-bold">{totalParticipants}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center gap-4">
              <div className="p-3 rounded-full bg-pink-100">
                <Heart className="w-6 h-6 text-pink-600" />
              </div>
              <div>
                <p className="text-sm text-gray-600">Total événements</p>
                <p className="text-2xl font-bold">{events.length}</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Recent events */}
      <Card>
        <CardHeader>
          <CardTitle>Événements récents</CardTitle>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="flex justify-center py-8">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600" />
            </div>
          ) : events.length === 0 ? (
            <div className="text-center py-8">
              <p className="text-gray-500">Aucun événement</p>
              <Link href="/events/new">
                <Button variant="outline" className="mt-4">
                  Créer votre premier événement
                </Button>
              </Link>
            </div>
          ) : (
            <div className="space-y-4">
              {events.slice(0, 5).map((event) => (
                <Link
                  key={event.id}
                  href={`/events/${event.id}`}
                  className="flex items-center justify-between p-4 rounded-lg border border-gray-200 hover:bg-gray-50 transition-colors"
                >
                  <div>
                    <h3 className="font-medium text-gray-900">{event.name}</h3>
                    <p className="text-sm text-gray-500">{event.locationName}</p>
                  </div>
                  <span
                    className={`px-2 py-1 text-xs font-medium rounded-full ${
                      event.status === 'live'
                        ? 'bg-green-100 text-green-800'
                        : event.status === 'draft'
                          ? 'bg-gray-100 text-gray-800'
                          : 'bg-red-100 text-red-800'
                    }`}
                  >
                    {event.status === 'live'
                      ? 'En cours'
                      : event.status === 'draft'
                        ? 'Brouillon'
                        : 'Terminé'}
                  </span>
                </Link>
              ))}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
