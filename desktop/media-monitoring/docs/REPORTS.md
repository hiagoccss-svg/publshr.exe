# Publshr Reports — Enterprise media intelligence

**Reports** is the enterprise face of the Media Monitoring desktop app (`desktop/media-monitoring`). It is modeled after PR/coverage platforms such as [The Media Eye](https://www.themediaeye.com/what-we-do), eMediaEye, and 24ieye: a single workspace for **mentions**, **sentiment**, **publication mix**, and **clipping detail**.

## Product map vs Media Eye

| Media Eye / PR platform | Publshr Reports |
|-------------------------|-----------------|
| Dashboard snapshot | Reports → KPI row (mentions, reach, PR/media value) |
| Real-time mentions | Monitoring → live feed |
| Organized list / filters | Reports → clippings list + period & sentiment filters |
| Detail on selection | Right **Details** panel + full-screen article view |
| Custom / bespoke reports | **Export summary** (Markdown executive brief) |
| Saved shortlists | **Saved coverage** + “Saved only” report scope |
| Publication database | **Publications** section |

## Layout (three columns)

1. **Activity bar** — Reports (default), Dashboard, Monitoring, Coverage, Publications, Settings  
2. **Submenu** — Section title + context copy  
3. **Workspace** — Report analytics + clipping list  
4. **Details panel** — Source, metrics, keywords, preview, notes/tags, save, open URL  

## Working features

- Period: 7 / 30 / 90 days or all time  
- Scope: all coverage or saved only  
- Sentiment breakdown (bar chart)  
- Top publications and media types  
- Workspace-wide clipping list (not limited to one monitor)  
- Select clipping → detail panel updates (Media Eye–style drill-down)  
- Export executive Markdown summary  
- Local SQLite + optional Supabase sync (unchanged)  

## Run locally

```bash
cd desktop/media-monitoring
npm install
npm run dev
```

Open **Reports** in the activity bar (first icon). Run **Monitoring** to collect articles, then return to Reports to analyze.

## API (IPC)

- `getReportAnalytics({ days, savedOnly })`  
- `getWorkspaceClippings({ days, savedOnly, sentiment, search, sort, limit })`  
- `getActivity(resultId)` — detail panel timeline  
