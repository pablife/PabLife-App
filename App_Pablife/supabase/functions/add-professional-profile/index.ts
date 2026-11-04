// Usuário já cadastrado completa o cadastro de profissional com a mesma conta
// (mesmo e-mail, CPF e senha). O cadastro fica aguardando aprovação.
import { serve } from "https://deno.land/std@0.203.0/http/server.ts";
import { createClient } from "@supabase/supabase-js";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const MAX_DOCUMENT_BYTES = 10 * 1024 * 1024;
const PROFESSIONAL_TYPES = new Set(["nutritionist", "psychologist"]);
const DOCUMENT_TYPES: Record<string, string> = {
  pdf: "application/pdf",
  jpg: "image/jpeg",
  jpeg: "image/jpeg",
  png: "image/png",
  doc: "application/msword",
  docx:
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
};

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  { auth: { autoRefreshToken: false, persistSession: false } },
);

const jsonResponse = (body: Record<string, unknown>, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...corsHeaders },
  });

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "Metodo nao permitido" }, 405);
  }

  // A conta vem sempre do login, nunca do corpo da requisição.
  const token = (req.headers.get("Authorization") ?? "").replace(
    /^Bearer\s+/i,
    "",
  );
  const { data: authData, error: authError } = await supabase.auth.getUser(
    token,
  );
  const userId = authData?.user?.id;
  if (authError || !userId) {
    return jsonResponse({ error: "Sessao invalida" }, 401);
  }

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "JSON invalido" }, 400);
  }

  const professionalType = String(body.professionalType ?? "").toLowerCase();
  const documentBase64 = String(body.validationDocumentBase64 ?? "");
  const fileName = String(body.validationDocumentFileName ?? "");
  const description = typeof body.description === "string"
    ? body.description.trim() || null
    : null;
  const extension = fileName.toLowerCase().split(".").pop() ?? "";

  if (!PROFESSIONAL_TYPES.has(professionalType)) {
    return jsonResponse({ error: "Tipo de profissional invalido" }, 400);
  }
  if (!documentBase64 || !DOCUMENT_TYPES[extension]) {
    return jsonResponse({ error: "Documento invalido" }, 400);
  }

  const { data: user, error: userError } = await supabase
    .from("tb_users")
    .select("id, role, status, deleted_at")
    .eq("id", userId)
    .maybeSingle();
  if (userError || !user) {
    return jsonResponse({ error: "Conta nao encontrada" }, 404);
  }
  if (user.role !== "user" || user.status !== "active" || user.deleted_at) {
    return jsonResponse({ error: "Esta conta nao pode ser alterada" }, 409);
  }

  const { data: existing } = await supabase
    .from("tb_professionals")
    .select("id")
    .eq("user_id", userId)
    .maybeSingle();
  if (existing) {
    return jsonResponse({ error: "Cadastro de profissional ja existe" }, 409);
  }

  let fileBytes: Uint8Array;
  try {
    const content = documentBase64.includes(",")
      ? documentBase64.split(",")[1]
      : documentBase64;
    fileBytes = Uint8Array.from(atob(content), (c) => c.charCodeAt(0));
  } catch {
    return jsonResponse({ error: "Documento invalido" }, 400);
  }
  if (fileBytes.length === 0 || fileBytes.length > MAX_DOCUMENT_BYTES) {
    return jsonResponse({ error: "Documento acima do limite de 10 MB" }, 400);
  }

  const filePath = `${userId}/${fileName.replace(/[^a-zA-Z0-9.-]/g, "_")}`;
  const { data: upload, error: uploadError } = await supabase.storage
    .from("professional-documents")
    .upload(filePath, fileBytes, {
      contentType: DOCUMENT_TYPES[extension],
      upsert: false,
    });
  if (uploadError) {
    console.error("Falha ao enviar documento", uploadError);
    return jsonResponse({ error: "Falha ao enviar o documento" }, 500);
  }
  const { data: { publicUrl } } = supabase.storage
    .from("professional-documents")
    .getPublicUrl(upload.path);

  const { data: professional, error: insertError } = await supabase
    .from("tb_professionals")
    .insert({
      user_id: userId,
      type: professionalType,
      validation_document_url: publicUrl,
      description,
    })
    .select("id")
    .single();
  if (insertError) {
    console.error("Falha ao criar profissional", insertError);
    await supabase.storage.from("professional-documents").remove([filePath]);
    return jsonResponse({ error: "Falha ao criar o cadastro" }, 500);
  }

  const { error: roleError } = await supabase
    .from("tb_users")
    .update({ role: "professional" })
    .eq("id", userId);
  if (roleError) {
    console.error("Falha ao atualizar a conta", roleError);
    await supabase.from("tb_professionals").delete().eq("id", professional.id);
    await supabase.storage.from("professional-documents").remove([filePath]);
    return jsonResponse({ error: "Falha ao atualizar a conta" }, 500);
  }

  return jsonResponse({ message: "Cadastro enviado para aprovacao" }, 201);
});
