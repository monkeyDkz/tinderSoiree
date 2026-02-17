import { Metadata } from 'next';

interface Props {
  params: { eventId: string };
  searchParams: { token?: string };
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  return {
    title: 'Rejoindre la soirée - Tinder Soirée',
    description: 'Téléchargez l\'app pour rejoindre cette soirée',
  };
}

export default function JoinEventPage({ params, searchParams }: Props) {
  const { eventId } = params;
  const { token } = searchParams;

  const appStoreUrl = 'https://apps.apple.com/app/tindersoiree'; // À remplacer
  const deepLinkUrl = `tindersoiree://join?eventId=${eventId}&token=${token || ''}`;

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary-500 to-pink-500 flex items-center justify-center p-4">
      <div className="max-w-md w-full bg-white rounded-2xl shadow-xl p-8 text-center">
        <div className="w-20 h-20 bg-primary-100 rounded-full flex items-center justify-center mx-auto mb-6">
          <span className="text-4xl">🎉</span>
        </div>

        <h1 className="text-2xl font-bold text-gray-900 mb-2">
          Rejoindre la soirée
        </h1>

        <p className="text-gray-600 mb-8">
          Téléchargez l'application Tinder Soirée pour rejoindre cet événement et
          rencontrer les autres participants.
        </p>

        <div className="space-y-4">
          <a
            href={deepLinkUrl}
            className="block w-full py-3 px-4 bg-primary-600 text-white font-medium rounded-lg hover:bg-primary-700 transition-colors"
          >
            Ouvrir l'application
          </a>

          <a
            href={appStoreUrl}
            className="block w-full py-3 px-4 bg-gray-900 text-white font-medium rounded-lg hover:bg-gray-800 transition-colors"
          >
            <span className="flex items-center justify-center gap-2">
              <svg className="w-5 h-5" viewBox="0 0 24 24" fill="currentColor">
                <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z" />
              </svg>
              Télécharger sur l'App Store
            </span>
          </a>
        </div>

        <p className="mt-8 text-sm text-gray-500">
          En rejoignant, vous acceptez nos{' '}
          <a href="#" className="text-primary-600 hover:underline">
            Conditions d'utilisation
          </a>{' '}
          et notre{' '}
          <a href="#" className="text-primary-600 hover:underline">
            Politique de confidentialité
          </a>
        </p>
      </div>
    </div>
  );
}
