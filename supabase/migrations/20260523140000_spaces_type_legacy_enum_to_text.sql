-- Legacy Supabase projects created `space_type` as (project, folder, list, board, channel).
-- Mac IDE + enterprise apps use ClickUp-style types (general, client, campaign, …).
-- Convert to text so all canonical values work.

ALTER TABLE public.spaces ALTER COLUMN type DROP DEFAULT;

ALTER TABLE public.spaces
  ALTER COLUMN type TYPE text
  USING (
    CASE type::text
      WHEN 'project' THEN 'initiative'
      WHEN 'folder' THEN 'operation'
      WHEN 'list' THEN 'general'
      WHEN 'board' THEN 'operation'
      WHEN 'channel' THEN 'general'
      ELSE type::text
    END
  );

ALTER TABLE public.spaces ALTER COLUMN type SET DEFAULT 'general';

COMMENT ON COLUMN public.spaces.type IS
  'ClickUp-style space kind: general, client, campaign, initiative, … (text; legacy enum migrated)';

-- Safe to drop when nothing else references it (only spaces.type used this enum).
DO $$ BEGIN
  DROP TYPE IF EXISTS public.space_type;
EXCEPTION WHEN dependent_objects_still_exist THEN
  RAISE NOTICE 'space_type enum kept (still referenced elsewhere)';
END $$;
