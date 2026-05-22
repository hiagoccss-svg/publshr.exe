/** @type {import('tailwindcss').Config} */
export default {
  content: ['./src/renderer/index.html', './src/**/*.{js,ts,jsx,tsx}'],
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
          DEFAULT: '#1a1a18',
          secondary: '#5c5a56',
          muted: '#8a8782'
        },
        accent: {
          DEFAULT: '#3d5a80',
          soft: '#e8eef4'
        },
        status: {
          idea: '#8a8782',
          drafting: '#6b7fd7',
          review: '#c9a227',
          approval: '#b86e00',
          scheduled: '#3d7a6a',
          published: '#2d6a4f',
          overdue: '#b42318'
        }
      },
      fontFamily: {
        sans: [
          'Inter',
          'ui-sans-serif',
          'system-ui',
          '-apple-system',
          'Segoe UI',
          'sans-serif'
        ],
        display: ['"SF Pro Display"', 'Inter', 'system-ui', 'sans-serif']
      },
      boxShadow: {
        soft: '0 1px 2px rgba(26, 26, 24, 0.04), 0 4px 12px rgba(26, 26, 24, 0.06)',
        panel: '0 0 0 1px rgba(26, 26, 24, 0.06)'
      },
      borderRadius: {
        card: '18px',
        pill: '9999px',
        xl: '18px',
        '2xl': '18px'
      },
      spacing: {
        'lib-gutter': '18px',
        'lib-margin': '24px'
      }
    }
  },
  plugins: []
}
