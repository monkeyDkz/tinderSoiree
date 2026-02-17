'use client';

import { useAuth } from '@/hooks/useAuth';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';

export default function SettingsPage() {
  const { user, logout } = useAuth();

  return (
    <div className="max-w-2xl space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Paramètres</h1>
        <p className="text-gray-600">Gérez votre compte</p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Compte</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div>
            <label className="text-sm font-medium text-gray-500">Email</label>
            <p className="font-medium">{user?.email}</p>
          </div>
          <div>
            <label className="text-sm font-medium text-gray-500">Nom</label>
            <p className="font-medium">{user?.firstName}</p>
          </div>
          <div>
            <label className="text-sm font-medium text-gray-500">Rôle</label>
            <p className="font-medium capitalize">{user?.role}</p>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Session</CardTitle>
        </CardHeader>
        <CardContent>
          <Button variant="destructive" onClick={logout}>
            Se déconnecter
          </Button>
        </CardContent>
      </Card>
    </div>
  );
}
