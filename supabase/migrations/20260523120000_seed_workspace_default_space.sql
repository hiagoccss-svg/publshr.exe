-- Default ClickUp-style space per workspace (General → Projects → List).

CREATE OR REPLACE FUNCTION public.seed_workspace_default_space()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_space_id uuid;
  v_folder_id uuid;
  v_owner uuid;
BEGIN
  v_owner := COALESCE(NEW.owner_id, auth.uid());
  IF v_owner IS NULL THEN
    RETURN NEW;
  END IF;

  IF EXISTS (SELECT 1 FROM public.spaces s WHERE s.workspace_id = NEW.id LIMIT 1) THEN
    RETURN NEW;
  END IF;

  INSERT INTO public.spaces (
    workspace_id, name, description, type, owner_id, color
  ) VALUES (
    NEW.id, 'General', 'Default space for tasks and projects', 'general', v_owner, '#3d5a80'
  )
  RETURNING id INTO v_space_id;

  INSERT INTO public.space_folders (space_id, name, sort_order)
  VALUES (v_space_id, 'Projects', 0)
  RETURNING id INTO v_folder_id;

  INSERT INTO public.space_lists (space_id, folder_id, name, sort_order)
  VALUES (v_space_id, v_folder_id, 'List', 0);

  INSERT INTO public.space_members (space_id, user_id, role)
  VALUES (v_space_id, v_owner, 'owner')
  ON CONFLICT DO NOTHING;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_workspace_seed_default_space ON public.workspaces;
CREATE TRIGGER on_workspace_seed_default_space
  AFTER INSERT ON public.workspaces
  FOR EACH ROW
  EXECUTE FUNCTION public.seed_workspace_default_space();

-- Backfill workspaces that only have chat (#general) but no space yet.
DO $$
DECLARE
  w record;
  v_space_id uuid;
  v_folder_id uuid;
BEGIN
  FOR w IN
    SELECT id, owner_id FROM public.workspaces
    WHERE owner_id IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM public.spaces s WHERE s.workspace_id = workspaces.id)
  LOOP
    INSERT INTO public.spaces (workspace_id, name, description, type, owner_id, color)
    VALUES (w.id, 'General', 'Default space for tasks and projects', 'project', w.owner_id, '#3d5a80')
    RETURNING id INTO v_space_id;

    INSERT INTO public.space_folders (space_id, name, sort_order)
    VALUES (v_space_id, 'Projects', 0)
    RETURNING id INTO v_folder_id;

    INSERT INTO public.space_lists (space_id, folder_id, name, sort_order)
    VALUES (v_space_id, v_folder_id, 'List', 0);

    INSERT INTO public.space_members (space_id, user_id, role)
    VALUES (v_space_id, w.owner_id, 'owner')
    ON CONFLICT DO NOTHING;
  END LOOP;
END;
$$;
