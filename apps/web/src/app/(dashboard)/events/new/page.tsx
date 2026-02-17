'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/hooks/useAuth';
import { api } from '@/lib/api';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { ArrowLeft } from 'lucide-react';
import Link from 'next/link';

export default function NewEventPage() {
  const router = useRouter();
  const { token } = useAuth();
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');

  const [formData, setFormData] = useState({
    name: '',
    description: '',
    locationName: '',
    locationAddress: '',
    startAt: '',
    endAt: '',
    maxParticipants: '',
  });

  const handleChange = (
    e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>,
  ) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setError('');

    try {
      const payload = {
        ...formData,
        maxParticipants: formData.maxParticipants
          ? parseInt(formData.maxParticipants)
          : undefined,
      };

      const data = await api.post<{ event: { id: string } }>(
        '/admin/events',
        payload,
        token!,
      );

      router.push(`/events/${data.event.id}`);
    } catch (err: any) {
      setError(err.message || 'Erreur lors de la création');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="max-w-2xl mx-auto space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <Link
          href="/events"
          className="p-2 rounded-lg hover:bg-gray-100 transition-colors"
        >
          <ArrowLeft className="w-5 h-5" />
        </Link>
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Nouvel événement</h1>
          <p className="text-gray-600">Créez un nouvel événement</p>
        </div>
      </div>

      {/* Form */}
      <Card>
        <CardContent className="pt-6">
          <form onSubmit={handleSubmit} className="space-y-6">
            <Input
              id="name"
              name="name"
              label="Nom de l'événement *"
              value={formData.name}
              onChange={handleChange}
              placeholder="Soirée Rooftop"
              required
            />

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Description
              </label>
              <textarea
                name="description"
                value={formData.description}
                onChange={handleChange}
                rows={3}
                className="block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent"
                placeholder="Description de l'événement..."
              />
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <Input
                id="locationName"
                name="locationName"
                label="Lieu *"
                value={formData.locationName}
                onChange={handleChange}
                placeholder="Le Perchoir"
                required
              />
              <Input
                id="locationAddress"
                name="locationAddress"
                label="Adresse"
                value={formData.locationAddress}
                onChange={handleChange}
                placeholder="14 Rue Crespin du Gast, Paris"
              />
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <Input
                id="startAt"
                name="startAt"
                type="datetime-local"
                label="Date et heure de début *"
                value={formData.startAt}
                onChange={handleChange}
                required
              />
              <Input
                id="endAt"
                name="endAt"
                type="datetime-local"
                label="Date et heure de fin *"
                value={formData.endAt}
                onChange={handleChange}
                required
              />
            </div>

            <Input
              id="maxParticipants"
              name="maxParticipants"
              type="number"
              label="Capacité maximale (optionnel)"
              value={formData.maxParticipants}
              onChange={handleChange}
              placeholder="100"
              min="1"
            />

            {error && (
              <div className="p-3 rounded-lg bg-red-50 text-red-600 text-sm">
                {error}
              </div>
            )}

            <div className="flex gap-4">
              <Button type="submit" isLoading={isLoading}>
                Créer l'événement
              </Button>
              <Link href="/events">
                <Button type="button" variant="outline">
                  Annuler
                </Button>
              </Link>
            </div>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}
