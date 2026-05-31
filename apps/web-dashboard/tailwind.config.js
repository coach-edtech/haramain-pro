/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        // Primary (Deep Emerald) - Kemewahan Tanah Suci
        primary: {
          50: '#d1fae5',   // Subtle backgrounds
          100: '#a7f3d0',
          200: '#6ee7b7',
          300: '#34d399',
          400: '#10b981',  // Interactive elements
          500: '#059669',
          600: '#047857',  // Primary base
          700: '#065f46',
          800: '#064e3b',  // Primary dark, headers
          900: '#022c22',
        },
        // Accent Gold - CTAs, highlights
        accent: {
          50: '#fffbeb',   // Warm background tints
          100: '#fef3c7',
          200: '#fde68a',
          300: '#fcd34d',
          400: '#fbbf24',  // Hover states
          500: '#f59e0b',  // Primary accent, CTAs
          600: '#d97706',  // Active states
          700: '#b45309',
          800: '#92400e',
          900: '#78350f',
        },
        // Danger (Panic Red)
        danger: {
          100: '#fee2e2',  // Alert backgrounds
          200: '#fecaca',
          300: '#fca5a5',
          400: '#f87171',
          500: '#ef4444',  // Panic button hover
          600: '#dc2626',  // Panic button
          700: '#b91c1c',
          800: '#991b1b',
          900: '#7f1d1d',
        },
        // Neutral palette
        slate: {
          50: '#f8fafc',   // Page background
          100: '#f1f5f9',
          200: '#e2e8f0',  // Borders
          300: '#cbd5e1',
          400: '#94a3b8',
          500: '#64748b',
          600: '#475569',  // Text secondary
          700: '#334155',
          800: '#1e293b',
          900: '#0f172a',  // Text primary, sidebar bg
        },
      },
      fontFamily: {
        display: ['"Playfair Display"', 'Georgia', 'serif'],
        body: ['Inter', 'system-ui', 'sans-serif'],
        arabic: ['"Amiri Quran"', '"Traditional Arabic"', 'serif'],
      },
      borderRadius: {
        'card': '12px',
        'btn': '8px',
        'pill': '24px',
        'sm': '4px',
        'input': '8px',
        'modal': '16px',
      },
      boxShadow: {
        'elevated': '0 4px 6px -1px rgba(0,0,0,0.1), 0 2px 4px -1px rgba(0,0,0,0.06)',
        'card': '0 1px 3px rgba(0,0,0,0.1), 0 1px 2px rgba(0,0,0,0.06)',
        'panic': '0 0 20px rgba(220,38,38,0.4)',
        'floating': '0 10px 25px -5px rgba(0,0,0,0.1), 0 8px 10px -5px rgba(0,0,0,0.04)',
      },
      spacing: {
        '18': '4.5rem',
        '22': '5.5rem',
      },
      screens: {
        'sm': '640px',
        'md': '768px',
        'lg': '1024px',
        'xl': '1280px',
        '2xl': '1536px',
      },
      animation: {
        'pulse-slow': 'pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite',
      },
    },
  },
  plugins: [],
}
