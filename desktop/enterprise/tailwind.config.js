/** @type {import('tailwindcss').Config} */
export default {
  content: [
    './src/**/*.{html,tsx,ts}',
    '../spaces/src/renderer/**/*.{html,tsx,ts}'
  ],
  theme: {
    extend: {
      colors: {
        surface: {
          DEFAULT: '#f3f2ef',
          raised: '#ffffff',
          muted: '#eeedeb',
          border: '#e4e2dc'
        },
        ink: {
          DEFAULT: '#1a1917',
          secondary: '#5c5a54',
          muted: '#8a877f'
        },
        accent: {
          DEFAULT: '#3d5a80',
          soft: '#e8eef4',
          hover: '#2c435f'
        },
        status: {
          todo: '#8a877f',
          progress: '#3d5a80',
          review: '#b8860b',
          blocked: '#c45c4a',
          approved: '#4a7c59',
          done: '#4a7c59'
        }
      },
      fontFamily: {
        sans: [
          'Inter',
          'SF Pro Display',
          'Segoe UI',
          'system-ui',
          '-apple-system',
          'sans-serif'
        ]
      },
      borderRadius: {
        card: '18px',
        pill: '9999px'
      },
      spacing: {
        'lib-gutter': '18px',
        'lib-margin': '24px',
        'lib-card': '16px'
      },
      boxShadow: {
        panel: '0 1px 2px rgba(26, 25, 23, 0.04), 0 4px 16px rgba(26, 25, 23, 0.06)',
        card: '0 1px 2px rgba(26, 25, 23, 0.05), 0 8px 24px rgba(26, 25, 23, 0.06)'
      },
      animation: {
        'fade-in': 'fadeIn 0.15s ease-out'
      },
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0', transform: 'translateY(2px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' }
        }
      }
    }
  },
  plugins: []
}
