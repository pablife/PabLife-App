export function getDocumentType(document: string): string | null {
  const normalized = document?.trim() ?? "";
  if (normalized.length === 11) return "CPF";
  if (normalized.length === 14) return "CNPJ";
  return null;
}
