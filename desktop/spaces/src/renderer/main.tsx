import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import App from './App'
import { initSpacesPlatform } from './lib/api'
import './index.css'

initSpacesPlatform()

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>
)
