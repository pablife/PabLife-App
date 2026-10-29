-- Manage continuity and exclusivity of rules for professional transfers
DROP TRIGGER IF EXISTS rules_professional_transfer_bi
ON public.tb_rules_professional_transfers;
DROP TRIGGER IF EXISTS rules_professional_transfer_bu
ON public.tb_rules_professional_transfers;
DROP FUNCTION IF EXISTS public.handle_rules_professional_transfer_insert();
DROP FUNCTION IF EXISTS public.prevent_rules_professional_transfer_update();

-- Prevent direct updates (only new inserts are allowed to change rules)
CREATE OR REPLACE FUNCTION public.prevent_rules_professional_transfer_update()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  -- Allow internal updates performed by the insert handler
  IF current_setting('app.rules_professional_transfer_allow_update', true) = 'on' THEN
    RETURN NEW;
  END IF;

  RAISE EXCEPTION 'Atualizações não são permitidas; crie um novo registro.';
END;
$$;

CREATE TRIGGER rules_professional_transfer_bu
BEFORE UPDATE ON public.tb_rules_professional_transfers
FOR EACH ROW
EXECUTE FUNCTION public.prevent_rules_professional_transfer_update();

-- Ensure only one active record, contiguous validity, and ignore user flags
CREATE OR REPLACE FUNCTION public.handle_rules_professional_transfer_insert()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  active_rec RECORD;
BEGIN
  -- Only the trigger controls these flags
  NEW.is_active := true;
  NEW.ceases_to_be_in_force_at := NULL;

  -- Lock all active records (there should be at most one) for consistent updates
  FOR active_rec IN
    SELECT id, become_effective_at
    FROM public.tb_rules_professional_transfers
    WHERE is_active = true
    ORDER BY become_effective_at DESC
    FOR UPDATE
  LOOP
    -- New rule cannot start before the current active rule begins
    IF NEW.become_effective_at < active_rec.become_effective_at THEN
      RAISE EXCEPTION 'O novo registro deve iniciar em % ou após o início vigente (%).',
        active_rec.become_effective_at, active_rec.become_effective_at;
    END IF;

    -- Temporarily allow internal update to close the previous rule
    PERFORM set_config('app.rules_professional_transfer_allow_update', 'on', true);

    UPDATE public.tb_rules_professional_transfers
    SET is_active = false,
        ceases_to_be_in_force_at = NEW.become_effective_at
    WHERE id = active_rec.id;

    -- Reset flag for safety (remains local to the transaction)
    PERFORM set_config('app.rules_professional_transfer_allow_update', 'off', true);
  END LOOP;

  RETURN NEW;
END;
$$;

CREATE TRIGGER rules_professional_transfer_bi
BEFORE INSERT ON public.tb_rules_professional_transfers
FOR EACH ROW
EXECUTE FUNCTION public.handle_rules_professional_transfer_insert();
