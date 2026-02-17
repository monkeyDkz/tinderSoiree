'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { useAuth } from '@/hooks/useAuth';
import { api } from '@/lib/api';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Plus, MapPin, Calendar, Users } from 'lucide-react';
import { formatDateShort, getStatusColor, getStatusLabel } from '@/lib/utils';
import type { Event } from '@/types';

export default function EventsPage() {
  const { token } = useAuth();
  const [events, setEvents] = useState<Event[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [filter, setFilter] = useState<string>('all');

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

  const filteredEvents =
    filter === 'all' ? events : events.filter((e) => e.status === filter);

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Événements</h1>
          <p className="text-gray-600">Gérez vos événements</p>
        </div>
        <Link href="/events/new">
          <Button>
            <Plus className="w-4 h-4 mr-2" />
            Nouvel événement
          </Button>
        </Link>
      </div>

      {/* Filters */}
      <div className="flex gap-2">
        {['all', 'draft', 'live', 'closed'].map((status) => (
          <button
            key={status}
            onClick={() => setFilter(status)}
            className={`px-3 py-1.5 text-sm font-medium rounded-lg transition-colors ${
              filter === status
                ? 'bg-primary-100 text-primary-700'
                : 'text-gray-600 hover:bg-gray-100'
            }`}
          >
            {status === 'all'
              ? 'Tous'
              : status === 'draft'
                ? 'Brouillons'
                : status === 'live'
                  ? 'En cours'
                  : 'Terminés'}
          </button>
        ))}
      </div>

      {/* Events grid */}
      {isLoading ? (
        <div className="flex justify-center py-16">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600" />
        </div>
      ) : filteredEvents.length === 0 ? (
        <Card>
          <CardContent className="py-16 text-center">
            <p className="text-gray-500">Aucun événement trouvé</p>
            <Link href="/events/new">
              <Button variant="outline" className="mt-4">
                Créer un événement
              </Button>
            </Link>
          </CardContent>
        </Card>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {filteredEvents.map((event) => (
            <Link key={event.id} href={`/events/${event.id}`}>
              <Card className="hover:shadow-md transition-shadow cursor-pointer h-full">
                {event.coverImageUrl && (
                  <div className="h-32 bg-gray-200 rounded-t-xl overflow-hidden">
                    <img
                      src={event.coverImageUrl}
                      alt={event.name}
                      className="w-full h-full object-cover"
                    />
                  </div>
                )}
                <CardContent className="pt-4">
                  <div className="flex items-start justify-between gap-2">
                    <h3 className="font-semibold text-gray-900 line-clamp-1">
                      {event.name}
                    </h3>
                    <span
                      className={`px-2 py-0.5 text-xs font-medium rounded-full shrink-0 ${getStatusColor(event.status)}`}
                    >
                      {getStatusLabel(event.status)}
                    </span>
                  </div>

                  <div className="mt-3 space-y-2">
                    <div className="flex items-center gap-2 text-sm text-gray-600">
                      <MapPin className="w-4 h-4" />
                      <span className="line-clamp-1">{event.locationName}</span>
                    </div>
                    <div className="flex items-center gap-2 text-sm text-gray-600">
                      <Calendar className="w-4 h-4" />
                      <span>{formatDateShort(event.startAt)}</span>
                    </div>
                    {event.participantCount !== undefined && (
                      <div className="flex items-center gap-2 text-sm text-gray-600">
                        <Users className="w-4 h-4" />
                        <span>{event.participantCount} participants</span>
                      </div>
                    )}
                  </div>
                </CardContent>
              </Card>
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}
