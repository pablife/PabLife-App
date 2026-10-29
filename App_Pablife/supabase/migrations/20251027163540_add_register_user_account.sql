CREATE OR REPLACE FUNCTION public.create_user_account (
p_user_id UUID,
p_full_name public.tb_users.full_name % TYPE,
p_email public.tb_users.email % TYPE,
p_phone public.tb_users.phone % TYPE,
p_cpf_document public.tb_users.cpf_document % TYPE,
p_terms_accepted public.tb_users.terms_accepted % TYPE,
p_role public.tb_users.role % TYPE DEFAULT 'user',
p_image_url public.tb_users.image_url % TYPE DEFAULT NULL,
p_professional_type public.tb_professionals.type % TYPE DEFAULT NULL,
p_validation_document_url public.tb_professionals.validation_document_url
% TYPE DEFAULT NULL,
p_description public.tb_professionals.description % TYPE DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_inserted_user public.tb_users%ROWTYPE;
  v_inserted_professional public.tb_professionals%ROWTYPE;
  v_role public.tb_users.role%TYPE := COALESCE(p_role, 'user');
BEGIN
  IF p_user_id IS NULL THEN
    RAISE EXCEPTION 'User id cannot be null';
  END IF;

  IF p_full_name IS NULL OR trim(p_full_name) = '' THEN
    RAISE EXCEPTION 'Full name is required';
  END IF;

  IF p_email IS NULL OR trim(p_email::text) = '' THEN
    RAISE EXCEPTION 'Email is required';
  END IF;

  IF p_phone IS NULL OR trim(p_phone) = '' THEN
    RAISE EXCEPTION 'Phone is required';
  END IF;

  IF p_cpf_document IS NULL OR trim(p_cpf_document) = '' THEN
    RAISE EXCEPTION 'CPF document is required';
  END IF;

  IF p_terms_accepted IS DISTINCT FROM TRUE THEN
    RAISE EXCEPTION 'Terms must be accepted';
  END IF;

  INSERT INTO public.tb_users (
    id,
    full_name,
    email,
    phone,
    cpf_document,
    image_url,
    terms_accepted,
    role
  )
  VALUES (
    p_user_id,
    trim(p_full_name),
    lower(p_email::text),
    trim(p_phone),
    trim(p_cpf_document),
    NULLIF(trim(COALESCE(p_image_url, ''))::text, ''),
    p_terms_accepted,
    v_role
  )
  RETURNING * INTO v_inserted_user;

  IF v_role = 'professional' THEN
    IF p_professional_type IS NULL OR trim(p_professional_type) = '' THEN
      RAISE EXCEPTION 'Professional type is required for professional role';
    END IF;

    IF p_professional_type NOT IN ('nutritionist', 'psychologist') THEN
      RAISE EXCEPTION 'Professional type must be nutritionist or psychologist';
    END IF;

    IF p_validation_document_url IS NULL OR trim(p_validation_document_url) = '' THEN
      RAISE EXCEPTION 'Validation document URL is required for professional role';
    END IF;

    INSERT INTO public.tb_professionals (
      user_id,
      type,
      validation_document_url,
      description
    )
    VALUES (
      v_inserted_user.id,
      p_professional_type,
      trim(p_validation_document_url),
      trim(p_description)
    )
    RETURNING * INTO v_inserted_professional;
  END IF;

  RETURN jsonb_build_object(
    'user',
    row_to_json(v_inserted_user),
    'professional',
    CASE
      WHEN v_inserted_professional IS NULL THEN NULL
      ELSE row_to_json(v_inserted_professional)
    END
  );
END;
$$ ;

REVOKE ALL ON FUNCTION public.create_user_account (
UUID,
VARCHAR,
extensions.CITEXT,
VARCHAR,
VARCHAR,
BOOLEAN,
VARCHAR,
VARCHAR,
VARCHAR,
VARCHAR,
TEXT
) FROM public ;

GRANT EXECUTE ON FUNCTION public.create_user_account (
UUID,
VARCHAR,
extensions.CITEXT,
VARCHAR,
VARCHAR,
BOOLEAN,
VARCHAR,
VARCHAR,
VARCHAR,
VARCHAR,
TEXT
) TO authenticated ;
