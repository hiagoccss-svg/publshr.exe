/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        surface: {
          title: '#181818',
          sidebar: '#252526',
          workspace: '#1E1E1E',
          panel: '#181818',
          highlight: '#2A2D2E',
          tile: '#2D2D2D',
          input: '#3C3C3C'
        },
        border: {
          DEFAULT: '#2B2B2B',
          subtle: '#3C3C3C'
        },
        content: {
          DEFAULT: '#CCCCCC',
          muted: '#9D9D9D',
          dim: '#6E6E6E',
          header: '#BBBBBB'
        },
        accent: {
          DEFAULT: '#007FD4',
          hover: '#1A8AD4',
          button: '#0E639C',
          'button-hover': '#1177BB'
        },
        status: {
          bar: '#007ACC'
        },
        sentiment: {
          positive: '#89D185',
          negative: '#F14C4C',
          neutral: '#9D9D9D',
          mixed: '#CCA700'
        }
      },
      fontFamily: {
        sans: [
          '-apple-system',
          'BlinkMacSystemFont',
          'Segoe UI',
          'Roboto',
          'Helvetica Neue',
          'Arial',
          'sans-serif'
        ]
      },
      fontSize: {
        '2xs': ['10px', { lineHeight: '14px' }],
        xs: ['11px', { lineHeight: '16px' }],
        sm: ['12px', { lineHeight: '18px' }],
        base: ['13px', { lineHeight: '20px' }],
        md: ['14px', { lineHeight: '22px' }]
      },
      spacing: {
        'topbar': '38px',
        'sidebar': '240px',
        'sidebar-collapsed': '52px',
        'context': '320px'
      },
      animation: {
        'fade-in': 'fadeIn 0.25s ease-out',
        'slide-up': 'slideUp 0.3s ease-out',
        'pulse-soft': 'pulseSoft 2s ease-in-out infinite'
      },
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' }
        },
        slideUp: {
          '0%': { opacity: '0', transform: 'translateY(8px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' }
        },
        pulseSoft: {
          '0%, 100%': { opacity: '1' },
          '50%': { opacity: '0.6' }
        }
      }
    }
  },
  plugins: []
}
