-- Seed a #general channel for every new workspace (real users land in Chat immediately).

CREATE OR REPLACE FUNCTION public.seed_workspace_default_channels()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.chat_channels c
    WHERE c.workspace_id = NEW.id AND c.name = 'general' AND c.kind = 'channel'
  ) THEN
    INSERT INTO public.chat_channels (
      workspace_id, name, description, kind, visibility, created_by
    ) VALUES (
      NEW.id, 'general', 'General discussion', 'channel', 'public', NEW.owner_id
    );
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_workspace_seed_channels ON public.workspaces;
CREATE TRIGGER on_workspace_seed_channels
  AFTER INSERT ON public.workspaces
  FOR EACH ROW
  EXECUTE FUNCTION public.seed_workspace_default_channels();

INSERT INTO public.chat_channels (workspace_id, name, description, kind, visibility, created_by)
SELECT w.id, 'general', 'General discussion', 'channel', 'public', w.owner_id
FROM public.workspaces w
WHERE NOT EXISTS (
  SELECT 1 FROM public.chat_channels c
  WHERE c.workspace_id = w.id AND c.kind = 'channel' AND c.name = 'general'
);
