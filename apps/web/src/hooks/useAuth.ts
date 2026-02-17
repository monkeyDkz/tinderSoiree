'use client';

import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import { api } from '@/lib/api';
import type { User, AuthResponse } from '@/types';

interface AuthState {
  user: User | null;
  token: string | null;
  isLoading: boolean;
  error: string | null;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
  clearError: () => void;
}

export const useAuth = create<AuthState>()(
  persist(
    (set, get) => ({
      user: null,
      token: null,
      isLoading: false,
      error: null,

      login: async (email: string, password: string) => {
        set({ isLoading: true, error: null });

        try {
          const response = await api.post<AuthResponse>('/auth/login', {
            email,
            password,
          });

          // Verify admin role
          if (
            response.user.role !== 'admin' &&
            response.user.role !== 'super_admin'
          ) {
            throw new Error('Accès non autorisé');
          }

          set({
            user: response.user,
            token: response.tokens.accessToken,
            isLoading: false,
          });
        } catch (error: any) {
          set({
            isLoading: false,
            error: error.message || 'Erreur de connexion',
          });
          throw error;
        }
      },

      logout: () => {
        set({ user: null, token: null });
      },

      clearError: () => {
        set({ error: null });
      },
    }),
    {
      name: 'admin-auth',
      partialize: (state) => ({
        user: state.user,
        token: state.token,
      }),
    },
  ),
);
