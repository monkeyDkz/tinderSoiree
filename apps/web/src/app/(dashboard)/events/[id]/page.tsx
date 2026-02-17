'use client';

import { useEffect, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import Link from 'next/link';
import { useAuth } from '@/hooks/useAuth';
import { api } from '@/lib/api';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import {
  ArrowLeft,
  Copy,
  Download,
  MapPin,
  Calendar,
  Users,
  BarChart,
} from 'lucide-react';
import { formatDate, getStatusColor, getStatusLabel } from '@/lib/utils';
import type { Event } from '@/types';

export default function EventDetailPage() {
  const params = useParams();
  const router = useRouter();
  const { token } = useAuth();
  const eventId = params.id as string;

  const [event, setEvent] = useState<Event | null>(null);
  const [qrCode, setQrCode] = useState<string>('');
  const [isLoading, setIsLoading] = useState(true);
  const [isPublishing, setIsPublishing] = useState(false);
  const [isClosing, setIsClosing] = useState(false);

  useEffect(() => {
    const fetchEvent = async () => {
      if (!token) return;
      try {
        const data = await api.get<Event>(`/admin/events/${eventId}`, token);
        setEvent(data);

        // Fetch QR code
        const qrData = await api.get<{ qrCodeUrl: string }>(
          `/admin/events/${eventId}/qr`,
          token,
        );
        setQrCode(qrData.qrCodeUrl);
      } catch (error) {
        console.error('Failed to fetch event:', error);
      } finally {
        setIsLoading(false);
      }
    };

    fetchEvent();
  }, [eventId, token]);

  const handlePublish = async () => {
    if (!token || !event) return;
    setIsPublishing(true);
    try {
      const data = await api.post<{ event: Event }>(
        `/admin/events/${eventId}/publish`,
        {},
        token,
      );
      setEvent(data.event);
    } catch (error) {
      console.error('Failed to publish:', error);
    } finally {
      setIsPublishing(false);
    }
  };

  const handleClose = async () => {
    if (!token || !event) return;
    if (!confirm('Êtes-vous sûr de vouloir fermer cet événement ?')) return;

    setIsClosing(true);
    try {
      const data = await api.post<{ event: Event }>(
        `/admin/events/${eventId}/close`,
        {},
        token,
      );
      setEvent(data.event);
    } catch (error) {
      console.error('Failed to close:', error);
    } finally {
      setIsClosing(false);
    }
  };

  const copyToClipboard = (text: string) => {
    navigator.clipboard.writeText(text);
  };

  if (isLoading) {
    return (
      <div className="flex justify-center py-16">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600" />
      </div>
    );
  }

  if (!event) {
    return (
      <div className="text-center py-16">
        <p className="text-gray-500">Événement non trouvé</p>
        <Link href="/events">
          <Button variant="outline" className="mt-4">
            Retour aux événements
          </Button>
        </Link>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-start justify-between">
        <div className="flex items-center gap-4">
          <Link
            href="/events"
            className="p-2 rounded-lg hover:bg-gray-100 transition-colors"
          >
            <ArrowLeft className="w-5 h-5" />
          </Link>
          <div>
            <div className="flex items-center gap-3">
              <h1 className="text-2xl font-bold text-gray-900">{event.name}</h1>
              <span
                className={`px-2 py-1 text-xs font-medium rounded-full ${getStatusColor(event.status)}`}
              >
                {getStatusLabel(event.status)}
              </span>
            </div>
            <p className="text-gray-600">{event.locationName}</p>
          </div>
        </div>

        <div className="flex gap-2">
          {event.status === 'draft' && (
            <Button onClick={handlePublish} isLoading={isPublishing}>
              Publier
            </Button>
          )}
          {event.status === 'live' && (
            <>
              <Link href={`/events/${eventId}/live`}>
                <Button variant="outline">
                  <BarChart className="w-4 h-4 mr-2" />
                  Stats live
                </Button>
              </Link>
              <Button
                variant="destructive"
                onClick={handleClose}
                isLoading={isClosing}
              >
                Fermer
              </Button>
            </>
          )}
        </div>
      </div>

      {/* Content */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* QR Code */}
        <Card>
          <CardHeader>
            <CardTitle>QR Code d'entrée</CardTitle>
          </CardHeader>
          <CardContent className="flex flex-col items-center gap-4">
            {qrCode && (
              <div className="bg-white p-4 rounded-lg shadow-sm">
                <img src={qrCode} alt="QR Code" className="w-64 h-64" />
              </div>
            )}
            <p className="text-sm text-gray-500 text-center">
              Affichez ce QR code à l'entrée de votre soirée
            </p>
            <div className="flex gap-2">
              <Button
                variant="outline"
                size="sm"
                onClick={() => {
                  if (!qrCode || !qrCode.includes(',')) return;
                  try {
                    const base64Data = qrCode.split(',')[1];
                    const binaryData = atob(base64Data);
                    const bytes = new Uint8Array(binaryData.length);
                    for (let i = 0; i < binaryData.length; i++) {
                      bytes[i] = binaryData.charCodeAt(i);
                    }
                    const blob = new Blob([bytes], { type: 'image/png' });
                    const url = window.URL.createObjectURL(blob);
                    const link = document.createElement('a');
                    link.download = `qr-${event.name.replace(/[^a-zA-Z0-9]/g, '_')}.png`;
                    link.href = url;
                    document.body.appendChild(link);
                    link.click();
                    document.body.removeChild(link);
                    window.URL.revokeObjectURL(url);
                  } catch (e) {
                    console.error('Download error:', e);
                  }
                }}
                disabled={!qrCode}
              >
                <Download className="w-4 h-4 mr-2" />
                PNG
              </Button>
            </div>
          </CardContent>
        </Card>

        {/* NFC / Link */}
        <Card>
          <CardHeader>
            <CardTitle>Lien / Tag NFC</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div>
              <label className="text-sm font-medium text-gray-700">
                URL à écrire sur le tag NFC
              </label>
              <div className="mt-1 flex gap-2">
                <input
                  type="text"
                  readOnly
                  value={event.joinUrl || ''}
                  className="flex-1 px-3 py-2 bg-gray-50 border border-gray-200 rounded-lg text-sm font-mono"
                />
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => copyToClipboard(event.joinUrl || '')}
                >
                  <Copy className="w-4 h-4" />
                </Button>
              </div>
            </div>

            <div className="p-4 bg-blue-50 rounded-lg">
              <h4 className="font-medium text-blue-900">
                Comment configurer un tag NFC ?
              </h4>
              <ol className="mt-2 text-sm text-blue-800 space-y-1 list-decimal list-inside">
                <li>Téléchargez NFC Tools (iOS/Android)</li>
                <li>Sélectionnez "Écrire" puis "URL"</li>
                <li>Collez l'URL ci-dessus</li>
                <li>Approchez le tag et écrivez</li>
              </ol>
            </div>
          </CardContent>
        </Card>

        {/* Info */}
        <Card>
          <CardHeader>
            <CardTitle>Informations</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex items-center gap-3">
              <MapPin className="w-5 h-5 text-gray-400" />
              <div>
                <p className="text-sm text-gray-500">Lieu</p>
                <p className="font-medium">{event.locationName}</p>
                {event.locationAddress && (
                  <p className="text-sm text-gray-500">{event.locationAddress}</p>
                )}
              </div>
            </div>

            <div className="flex items-center gap-3">
              <Calendar className="w-5 h-5 text-gray-400" />
              <div>
                <p className="text-sm text-gray-500">Date et heure</p>
                <p className="font-medium">{formatDate(event.startAt)}</p>
                <p className="text-sm text-gray-500">
                  → {formatDate(event.endAt)}
                </p>
              </div>
            </div>

            <div className="flex items-center gap-3">
              <Users className="w-5 h-5 text-gray-400" />
              <div>
                <p className="text-sm text-gray-500">Participants</p>
                <p className="font-medium">
                  {event.participantCount || 0}
                  {event.maxParticipants && ` / ${event.maxParticipants}`}
                </p>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Stats preview */}
        <Card>
          <CardHeader>
            <CardTitle>Statistiques rapides</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-2 gap-4">
              <div className="text-center p-4 bg-gray-50 rounded-lg">
                <p className="text-2xl font-bold">
                  {event.participantCount || 0}
                </p>
                <p className="text-sm text-gray-500">Participants</p>
              </div>
              <div className="text-center p-4 bg-gray-50 rounded-lg">
                <p className="text-2xl font-bold">0</p>
                <p className="text-sm text-gray-500">Matchs</p>
              </div>
            </div>
            {event.status === 'live' && (
              <Link href={`/events/${eventId}/live`}>
                <Button variant="outline" className="w-full mt-4">
                  Voir les stats en temps réel
                </Button>
              </Link>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
