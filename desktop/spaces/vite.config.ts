import { resolve } from 'path'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

/** Vite config for Tauri (and browser-only preview of the renderer). */
export default defineConfig({
  root: resolve(__dirname, 'src/renderer'),
  publicDir: resolve(__dirname, 'public'),
  build: {
    outDir: resolve(__dirname, 'dist'),
    emptyOutDir: true
  },
  resolve: {
    alias: {
      '@renderer': resolve(__dirname, 'src/renderer'),
      '@shared': resolve(__dirname, 'src/shared'),
      '@desktop': resolve(__dirname, '../../shared/desktop')
    }
  },
  plugins: [react()],
  clearScreen: false,
  server: {
    port: 5173,
    strictPort: true
  }
})
