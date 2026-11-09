import { z } from "../deps.ts";

export const InputSchema = z
  .object({
    plan_id: z.string().min(1),
    card: z
      .object({
        name: z.string().min(1, "card.name: O nome do títular do cartão é requerido"),
        cpfOrCnpj: z
          .string()
          .min(1, "card.cpfOrCnpj: CPF ou CNPJ do títular do cartão é requerido"),
        cardNumber: z
          .string()
          .min(1, "card.cardNumber: O número do cartão é requerido"),
        expirationMonth: z
          .number()
          .int()
          .min(1, "card.expirationMonth: O mês de expiração é requerido")
          .max(12, "card.expirationMonth: O mês de expiração é requerido"),
        expirationYear: z
          .number()
          .int()
          .min(
            new Date().getFullYear(),
            "card.expirationYear: O ano de expiração é requerido.",
          ),
        securityCode: z
          .string()
          .min(3, "card.securityCode: O código de segurança é requerido")
          .max(4, "card.securityCode: O código de segurança é requerido"),
      })
      .required(),
  })
  .strict();

export type Input = z.infer<typeof InputSchema>;
