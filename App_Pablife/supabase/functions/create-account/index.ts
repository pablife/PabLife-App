import { serve } from "https://deno.land/std@0.203.0/http/server.ts";
import { createClient, PostgrestError } from "@supabase/supabase-js";

type UserRole = "user" | "admin" | "professional";
type ProfessionalType = "nutritionist" | "psychologist";

type CreateAccountPayload = {
  fullName: string;
  email: string;
  password: string;
  phone: string;
  cpfDocument: string;
  termsAccepted: boolean;
  imageUrl: string | null;
  role?: UserRole;
  professionalType?: ProfessionalType;
  validationDocumentBase64?: string | null;
  validationDocumentFileName?: string | null;
  profileImageBase64?: string | null;
  profileImageFileName?: string | null;
  description?: string | null;
};

type CreateUserWithProfileResult = {
  user: JsonRecord;
  professional: JsonRecord | null;
};

type JsonRecord = Record<string, unknown>;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const REQUIRED_ENV_VARS = [
  "SUPABASE_URL",
  "SUPABASE_SERVICE_ROLE_KEY",
] as const;

const missingEnvVars = REQUIRED_ENV_VARS.filter(
  (envVar) => !Deno.env.get(envVar)
);

if (missingEnvVars.length > 0) {
  throw new Error(
    `Missing required environment variables: ${missingEnvVars.join(", ")}`
  );
}

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  }
);

const EMAIL_REGEX =
  // deno-lint-ignore no-control-regex
  /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const VALID_ROLES: ReadonlySet<UserRole> = new Set([
  "user",
  "admin",
  "professional",
] as const);
const VALID_PROFESSIONAL_TYPES: ReadonlySet<ProfessionalType> = new Set([
  "nutritionist",
  "psychologist",
] as const);

const jsonResponse = (
  body: JsonRecord,
  status = 200,
  additionalHeaders: Record<string, string> = {}
) =>
  new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      ...corsHeaders,
      ...additionalHeaders,
    },
  });

const isValidCpf = (cpf: string): boolean => {
  if (!/^\d{11}$/.test(cpf)) return false;
  if (/^(\d)\1{10}$/.test(cpf)) return false;

  const calcVerifier = (length: number) => {
    const digits = cpf.substring(0, length).split("").map(Number);
    const weightStart = length + 1;
    const total = digits.reduce(
      (acc, digit, index) => acc + digit * (weightStart - index),
      0
    );
    const remainder = total % 11;
    return remainder < 2 ? 0 : 11 - remainder;
  };

  const firstVerifier = calcVerifier(9);
  if (firstVerifier !== Number(cpf[9])) return false;

  const secondVerifier = calcVerifier(10);
  return secondVerifier === Number(cpf[10]);
};

const parsePayload = (
  body: unknown
): { payload?: CreateAccountPayload; errors?: string[] } => {
  if (!body || typeof body !== "object") {
    return { errors: ["O corpo da requisicao deve ser um objeto JSON"] };
  }

  const record = body as JsonRecord;
  const errors: string[] = [];

  const normalizeString = (value: unknown): string | null => {
    if (typeof value !== "string") return null;
    const trimmed = value.trim();
    return trimmed.length > 0 ? trimmed : null;
  };

  const fullName = normalizeString(record.fullName);
  if (!fullName) errors.push("O campo fullName e obrigatorio");

  const email = normalizeString(record.email);
  if (!email) {
    errors.push("O campo email e obrigatorio");
  } else if (!EMAIL_REGEX.test(email.toLowerCase())) {
    errors.push("O email informado e invalido");
  }

  const password = normalizeString(record.password);
  if (!password) {
    errors.push("O campo password e obrigatorio");
  } else if (password.length < 6) {
    errors.push("A senha deve ter pelo menos 6 caracteres");
  }

  const phone = normalizeString(record.phone);
  if (!phone) errors.push("O campo phone e obrigatorio");

  const cpfRaw = normalizeString(record.cpfDocument);
  let cpfDocument: string | undefined;
  if (!cpfRaw) {
    errors.push("O campo cpfDocument e obrigatorio");
  } else {
    const digitsOnly = cpfRaw.replace(/\D/g, "");
    if (digitsOnly.length !== 11) {
      errors.push("O cpfDocument deve conter exatamente 11 digitos");
    } else {
      if (!isValidCpf(digitsOnly)) {
        errors.push("O cpfDocument informado e invalido");
      }
      cpfDocument = digitsOnly;
    }
  }

  const termsAccepted = record.termsAccepted;
  if (typeof termsAccepted !== "boolean") {
    errors.push("O campo termsAccepted deve ser booleano");
  } else if (!termsAccepted) {
    errors.push("O campo termsAccepted deve ser verdadeiro");
  }

  let imageUrl: string | null = null;
  if (record.imageUrl !== undefined && record.imageUrl !== null) {
    const normalizedImageUrl = normalizeString(record.imageUrl);
    if (normalizedImageUrl === null) {
      errors.push(
        "O campo imageUrl deve ser uma string nao vazia quando informado"
      );
    } else {
      imageUrl = normalizedImageUrl;
    }
  }

  let role: UserRole | undefined;
  if (record.role !== undefined && record.role !== null) {
    if (typeof record.role !== "string") {
      errors.push("O campo role deve ser uma string quando informado");
    } else if (!VALID_ROLES.has(record.role as UserRole)) {
      errors.push("O campo role deve ser user, admin ou professional");
    } else {
      role = record.role as UserRole;
    }
  }

  const resolvedRole: UserRole = role ?? "user";

  let professionalType: ProfessionalType | undefined;
  if (
    record.professionalType !== undefined &&
    record.professionalType !== null
  ) {
    if (typeof record.professionalType !== "string") {
      errors.push(
        "O campo professionalType deve ser uma string quando informado"
      );
    } else {
      const normalizedType = record.professionalType.trim().toLowerCase();
      if (normalizedType.length === 0) {
        if (resolvedRole === "professional") {
          errors.push(
            "O campo professionalType e obrigatorio para profissionais"
          );
        }
      } else if (
        !VALID_PROFESSIONAL_TYPES.has(normalizedType as ProfessionalType)
      ) {
        errors.push(
          "O campo professionalType deve ser nutritionist ou psychologist"
        );
      } else {
        professionalType = normalizedType as ProfessionalType;
      }
    }
  }

  let validationDocumentBase64: string | null = null;
  let validationDocumentFileName: string | null = null;

  if (
    record.validationDocumentBase64 !== undefined &&
    record.validationDocumentBase64 !== null
  ) {
    if (typeof record.validationDocumentBase64 !== "string") {
      errors.push(
        "O campo validationDocumentBase64 deve ser uma string quando informado"
      );
    } else {
      const normalizedBase64 = normalizeString(record.validationDocumentBase64);
      if (normalizedBase64 === null) {
        if (resolvedRole === "professional") {
          errors.push(
            "O campo validationDocumentBase64 nao pode ser vazio para profissionais"
          );
        }
      } else {
        validationDocumentBase64 = normalizedBase64;
      }
    }
  }

  if (
    record.validationDocumentFileName !== undefined &&
    record.validationDocumentFileName !== null
  ) {
    if (typeof record.validationDocumentFileName !== "string") {
      errors.push(
        "O campo validationDocumentFileName deve ser uma string quando informado"
      );
    } else {
      const normalizedFileName = normalizeString(
        record.validationDocumentFileName
      );
      if (normalizedFileName === null && resolvedRole === "professional") {
        errors.push(
          "O campo validationDocumentFileName nao pode ser vazio para profissionais"
        );
      } else {
        validationDocumentFileName = normalizedFileName;
      }
    }
  }

  let profileImageBase64: string | null = null;
  let profileImageFileName: string | null = null;

  if (
    record.profileImageBase64 !== undefined &&
    record.profileImageBase64 !== null
  ) {
    if (typeof record.profileImageBase64 !== "string") {
      errors.push(
        "O campo profileImageBase64 deve ser uma string quando informado"
      );
    } else {
      const normalizedBase64 = normalizeString(record.profileImageBase64);
      if (normalizedBase64 === null) {
        errors.push(
          "O campo profileImageBase64 nao pode ser vazio quando informado"
        );
      } else {
        profileImageBase64 = normalizedBase64;
      }
    }
  }

  if (
    record.profileImageFileName !== undefined &&
    record.profileImageFileName !== null
  ) {
    if (typeof record.profileImageFileName !== "string") {
      errors.push(
        "O campo profileImageFileName deve ser uma string quando informado"
      );
    } else {
      const normalizedFileName = normalizeString(record.profileImageFileName);
      if (normalizedFileName === null) {
        if (profileImageBase64) {
          errors.push(
            "O campo profileImageFileName nao pode ser vazio quando profileImageBase64 e informado"
          );
        }
      } else {
        profileImageFileName = normalizedFileName;
      }
    }
  }

  let description: string | null = null;
  if (record.description !== undefined && record.description !== null) {
    const normalizedDescription = normalizeString(record.description);
    if (normalizedDescription !== null) {
      description = normalizedDescription;
    }
  }

  if (profileImageBase64 && !profileImageFileName) {
    errors.push(
      "O campo profileImageFileName e obrigatorio quando profileImageBase64 e informado"
    );
  }

  if (profileImageFileName && !profileImageBase64) {
    errors.push(
      "O campo profileImageBase64 e obrigatorio quando profileImageFileName e informado"
    );
  }

  if (resolvedRole === "professional") {
    if (!professionalType) {
      errors.push("O campo professionalType e obrigatorio para profissionais");
    }
    if (!validationDocumentBase64) {
      errors.push(
        "O campo validationDocumentBase64 e obrigatorio para profissionais"
      );
    }
    if (!validationDocumentFileName) {
      errors.push(
        "O campo validationDocumentFileName e obrigatorio para profissionais"
      );
    }
  } else {
    professionalType = undefined;
    validationDocumentBase64 = null;
    validationDocumentFileName = null;
  }

  if (errors.length > 0) {
    return { errors };
  }

  return {
    payload: {
      fullName: fullName!,
      email: email!.toLowerCase(),
      password: password!,
      phone: phone!,
      cpfDocument: cpfDocument!,
      termsAccepted: termsAccepted as boolean,
      imageUrl,
      role,
      professionalType,
      validationDocumentBase64,
      validationDocumentFileName,
      profileImageBase64,
      profileImageFileName,
      description,
    },
  };
};

const sanitizeDatabaseError = (error: PostgrestError | null) => {
  if (!error) return null;
  const { message, details, hint } = error;
  return {
    message,
    details,
    hint,
  };
};

const getContentType = (fileName: string): string => {
  const extension = fileName.toLowerCase().split(".").pop() || "";
  const mimeTypes: Record<string, string> = {
    pdf: "application/pdf",
    jpg: "image/jpeg",
    jpeg: "image/jpeg",
    png: "image/png",
    doc: "application/msword",
    docx: "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    webp: "image/webp",
    gif: "image/gif",
  };
  return mimeTypes[extension] || "application/pdf";
};

const getImageContentType = (fileName: string): string => {
  const extension = fileName.toLowerCase().split(".").pop() || "";
  const mimeTypes: Record<string, string> = {
    jpg: "image/jpeg",
    jpeg: "image/jpeg",
    png: "image/png",
    webp: "image/webp",
    gif: "image/gif",
  };
  return mimeTypes[extension] || "image/jpeg";
};

const uploadBase64Document = async (
  base64Data: string,
  fileName: string,
  userId: string
): Promise<string | null> => {
  try {
    const base64Content = base64Data.includes(",")
      ? base64Data.split(",")[1]
      : base64Data;
    const fileBytes = Uint8Array.from(atob(base64Content), (c) =>
      c.charCodeAt(0)
    );

    const sanitizedFileName = fileName.replace(/[^a-zA-Z0-9.-]/g, "_");
    const filePath = `${userId}/${sanitizedFileName}`;
    const contentType = getContentType(fileName);

    const { data, error } = await supabase.storage
      .from("professional-documents")
      .upload(filePath, fileBytes, {
        contentType: contentType,
        upsert: false,
      });

    if (error) {
      console.error("Erro ao fazer upload do documento:", error);
      return null;
    }

    const {
      data: { publicUrl },
    } = supabase.storage.from("professional-documents").getPublicUrl(data.path);

    return publicUrl;
  } catch (error) {
    console.error("Erro inesperado ao processar documento:", error);
    return null;
  }
};

const uploadBase64ProfileImage = async (
  base64Data: string,
  fileName: string,
  userId: string
): Promise<string | null> => {
  try {
    const base64Content = base64Data.includes(",")
      ? base64Data.split(",")[1]
      : base64Data;
    const fileBytes = Uint8Array.from(atob(base64Content), (c) =>
      c.charCodeAt(0)
    );

    const sanitizedFileName = fileName.replace(/[^a-zA-Z0-9.-]/g, "_");
    const timestamp = Date.now();
    const filePath = `profile_photos/${userId}/${timestamp}_${sanitizedFileName}`;
    const contentType = getImageContentType(fileName);

    const { data, error } = await supabase.storage
      .from("profile-photos")
      .upload(filePath, fileBytes, {
        contentType: contentType,
        upsert: false,
      });

    if (error) {
      console.error("Erro ao fazer upload da imagem de perfil:", error);
      return null;
    }

    const {
      data: { publicUrl },
    } = supabase.storage.from("profile-photos").getPublicUrl(data.path);

    return publicUrl;
  } catch (error) {
    console.error("Erro inesperado ao processar imagem de perfil:", error);
    return null;
  }
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Metodo nao permitido" }, 405);
  }

  let body: unknown;
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "JSON invalido" }, 400);
  }

  const { payload, errors } = parsePayload(body);
  if (errors) {
    return jsonResponse({ error: "Falha de validacao", details: errors }, 400);
  }

  const accountPayload = payload as CreateAccountPayload;

  try {
    const { data: emailExists, error: validateEmailError } = await supabase.rpc(
      "validate_user_email",
      {
        user_email: accountPayload.email,
      }
    );

    if (validateEmailError) {
      console.error(
        "Falha ao verificar usuario existente via validate_user_email",
        validateEmailError
      );
      return jsonResponse(
        {
          error: "Erro ao validar duplicidade do usuario",
          details: sanitizeDatabaseError(validateEmailError),
        },
        500
      );
    }

    if (emailExists === true) {
      return jsonResponse(
        { error: "Ja existe um usuario com este email" },
        409
      );
    }

    const createUserResponse = await supabase.auth.admin.createUser({
      email: accountPayload.email,
      password: accountPayload.password,
      email_confirm: true,
      user_metadata: {
        full_name: accountPayload.fullName,
        phone: accountPayload.phone,
        cpf_document: accountPayload.cpfDocument,
      },
    });

    if (createUserResponse.error) {
      console.error(
        "Falha ao criar usuario de autenticacao",
        createUserResponse.error
      );
      return jsonResponse(
        {
          error: "Falha ao criar usuario de autenticacao",
          details: createUserResponse.error.message,
        },
        400
      );
    }

    const authUserId = createUserResponse.data.user?.id;
    if (!authUserId) {
      console.error(
        "Usuario de autenticacao criado sem ID",
        createUserResponse.data
      );
      return jsonResponse(
        { error: "Usuario de autenticacao criado sem identificador" },
        500
      );
    }

    const resolvedRole = accountPayload.role ?? "user";

    let profileImageUrl: string | null = null;
    if (
      accountPayload.profileImageBase64 &&
      accountPayload.profileImageFileName
    ) {
      profileImageUrl = await uploadBase64ProfileImage(
        accountPayload.profileImageBase64,
        accountPayload.profileImageFileName,
        authUserId
      );

      if (!profileImageUrl) {
        console.error("Falha ao fazer upload da imagem de perfil");
        try {
          await supabase.auth.admin.deleteUser(authUserId);
        } catch (deleteError) {
          console.error(
            "Falha ao desfazer criacao do usuario de autenticacao",
            deleteError
          );
        }
        return jsonResponse(
          {
            error: "Falha ao fazer upload da imagem de perfil",
          },
          500
        );
      }
    }

    let validationDocumentUrl: string | null = null;
    if (
      resolvedRole === "professional" &&
      accountPayload.validationDocumentBase64 &&
      accountPayload.validationDocumentFileName
    ) {
      validationDocumentUrl = await uploadBase64Document(
        accountPayload.validationDocumentBase64,
        accountPayload.validationDocumentFileName,
        authUserId
      );

      if (!validationDocumentUrl) {
        console.error("Falha ao fazer upload do documento de validacao");
        try {
          await supabase.auth.admin.deleteUser(authUserId);
        } catch (deleteError) {
          console.error(
            "Falha ao desfazer criacao do usuario de autenticacao",
            deleteError
          );
        }
        return jsonResponse(
          {
            error: "Falha ao fazer upload do documento de validacao",
          },
          500
        );
      }
    }

    const finalImageUrl = profileImageUrl ?? accountPayload.imageUrl;

    const { data: createdProfile, error: createProfileError } =
      await supabase.rpc("create_user_account", {
        p_user_id: authUserId,
        p_full_name: accountPayload.fullName,
        p_email: accountPayload.email,
        p_phone: accountPayload.phone,
        p_cpf_document: accountPayload.cpfDocument,
        p_terms_accepted: accountPayload.termsAccepted,
        p_role: resolvedRole,
        p_image_url: finalImageUrl,
        p_professional_type:
          resolvedRole === "professional"
            ? accountPayload.professionalType ?? null
            : null,
        p_validation_document_url:
          resolvedRole === "professional" ? validationDocumentUrl : null,
        p_description:
          resolvedRole === "professional" ? accountPayload.description : null,
      });

    if (createProfileError || !createdProfile) {
      console.error(
        "Falha ao criar perfil completo do usuario",
        createProfileError
      );
      const sanitizedError = sanitizeDatabaseError(createProfileError);
      try {
        await supabase.auth.admin.deleteUser(authUserId);
      } catch (deleteError) {
        console.error(
          "Falha ao desfazer criacao do usuario de autenticacao",
          deleteError
        );
      }
      return jsonResponse(
        {
          error: "Falha ao criar perfil do usuario",
          details:
            sanitizedError ??
            "Nao foi possivel obter retorno da funcao create_user_account",
        },
        500
      );
    }

    const profileResult =
      createdProfile as Partial<CreateUserWithProfileResult>;

    if (!profileResult.user || typeof profileResult.user !== "object") {
      console.error(
        "Resposta inesperada ao criar perfil do usuario",
        createdProfile
      );
      try {
        await supabase.auth.admin.deleteUser(authUserId);
      } catch (deleteError) {
        console.error(
          "Falha ao desfazer criacao do usuario de autenticacao",
          deleteError
        );
      }
      return jsonResponse(
        {
          error: "Perfil do usuario criado sem dados associados",
        },
        500
      );
    }

    return jsonResponse(
      {
        message: "Conta criada com sucesso",
        user: profileResult.user,
        professional: profileResult.professional ?? null,
      },
      201
    );
  } catch (error) {
    console.error("Erro inesperado em create-account", error);
    return jsonResponse({ error: "Erro inesperado ao criar conta" }, 500);
  }
});
