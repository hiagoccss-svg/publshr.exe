import type Database from 'better-sqlite3'
import { v4 as uuidv4 } from 'uuid'

export interface PublicationSeed {
  name: string
  website: string
  region: string
  country: string
  language: string
  category: string
  publication_type: string
  authority_score: number
  estimated_traffic: number
}

export const PUBLICATION_SEEDS: PublicationSeed[] = [
  { name: 'Reuters', website: 'reuters.com', region: 'Global', country: 'US', language: 'en', category: 'Wire', publication_type: 'news', authority_score: 98, estimated_traffic: 120000000 },
  { name: 'BBC News', website: 'bbc.com/news', region: 'Europe', country: 'UK', language: 'en', category: 'Broadcast', publication_type: 'news', authority_score: 96, estimated_traffic: 95000000 },
  { name: 'The Guardian', website: 'theguardian.com', region: 'Europe', country: 'UK', language: 'en', category: 'National', publication_type: 'news', authority_score: 92, estimated_traffic: 110000000 },
  { name: 'Financial Times', website: 'ft.com', region: 'Europe', country: 'UK', language: 'en', category: 'Business', publication_type: 'news', authority_score: 94, estimated_traffic: 45000000 },
  { name: 'TechCrunch', website: 'techcrunch.com', region: 'Americas', country: 'US', language: 'en', category: 'Technology', publication_type: 'trade', authority_score: 88, estimated_traffic: 28000000 },
  { name: 'Wired', website: 'wired.com', region: 'Americas', country: 'US', language: 'en', category: 'Technology', publication_type: 'magazine', authority_score: 86, estimated_traffic: 32000000 },
  { name: 'The National', website: 'thenationalnews.com', region: 'Middle East', country: 'AE', language: 'en', category: 'National', publication_type: 'news', authority_score: 82, estimated_traffic: 12000000 },
  { name: 'Arab News', website: 'arabnews.com', region: 'Middle East', country: 'SA', language: 'en', category: 'National', publication_type: 'news', authority_score: 80, estimated_traffic: 8500000 },
  { name: 'Gulf News', website: 'gulfnews.com', region: 'Middle East', country: 'AE', language: 'en', category: 'Regional', publication_type: 'news', authority_score: 78, estimated_traffic: 6200000 },
  { name: 'Campaign Middle East', website: 'campaignme.com', region: 'Middle East', country: 'AE', language: 'en', category: 'Marketing', publication_type: 'trade', authority_score: 75, estimated_traffic: 450000 },
  { name: 'PR Week', website: 'prweek.com', region: 'Global', country: 'US', language: 'en', category: 'PR', publication_type: 'trade', authority_score: 84, estimated_traffic: 2100000 },
  { name: 'Adweek', website: 'adweek.com', region: 'Americas', country: 'US', language: 'en', category: 'Marketing', publication_type: 'trade', authority_score: 83, estimated_traffic: 5500000 },
  { name: 'Marketing Week', website: 'marketingweek.com', region: 'Europe', country: 'UK', language: 'en', category: 'Marketing', publication_type: 'trade', authority_score: 81, estimated_traffic: 1800000 },
  { name: 'VentureBeat', website: 'venturebeat.com', region: 'Americas', country: 'US', language: 'en', category: 'Technology', publication_type: 'trade', authority_score: 79, estimated_traffic: 4200000 },
  { name: 'The Verge', website: 'theverge.com', region: 'Americas', country: 'US', language: 'en', category: 'Technology', publication_type: 'news', authority_score: 87, estimated_traffic: 48000000 }
]

export function seedPublications(db: Database.Database): number {
  const count = db.prepare('SELECT COUNT(*) as c FROM publication_sources').get() as { c: number }
  if (count.c > 0) return count.c

  const insert = db.prepare(`
    INSERT INTO publication_sources (
      id, name, website, region, country, language, category, publication_type,
      authority_score, estimated_traffic, verified
    ) VALUES (
      @id, @name, @website, @region, @country, @language, @category, @publication_type,
      @authority_score, @estimated_traffic, 1
    )
  `)

  const tx = db.transaction(() => {
    for (const pub of PUBLICATION_SEEDS) {
      insert.run({
        id: uuidv4(),
        ...pub
      })
    }
  })
  tx()
  return PUBLICATION_SEEDS.length
}
