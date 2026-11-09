import type { SupabaseClient } from "../../deps.ts";

/** Desconto de estudante: 10% em todos os planos, para quem tem o comprovante
 * aprovado pela equipe. */
export const STUDENT_DISCOUNT = 0.1;

/** Conferido no servidor (cliente admin), nunca pelo que o app manda. */
export async function isApprovedStudent(
  adminClient: SupabaseClient,
  userId: string,
): Promise<boolean> {
  const { data, error } = await adminClient
    .from("tb_student_verifications")
    .select("id")
    .eq("user_id", userId)
    .eq("status", "approved")
    .limit(1);
  // Na dúvida, cobra o valor cheio do plano (nunca bloqueia a compra).
  if (error) return false;
  return (data ?? []).length > 0;
}

/** Valor com desconto, em centavos inteiros (ex.: 325,00 → 292,50). */
export function discountedAmount(amount: number): number {
  return Math.round(amount * (1 - STUDENT_DISCOUNT) * 100) / 100;
}
