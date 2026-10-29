// Substituida por mercadopago-subscription-cance

// import "https://esm.sh/v135/@supabase/functions-js@2.4.2/src/edge-runtime.d.ts";
// import * as yup from "https://esm.sh/yup@1.4.0";

// import { createClient } from "jsr:@supabase/supabase-js@2";
// import { log } from "../_shared/Log.ts";
// import { ResponseType } from "../_shared/ResponseType.ts";
// import { corsHeaders } from "../_shared/cors.ts";
// import { defaultHeaders } from "../_shared/defaultHeaders.ts";
// import { sendResponse } from "../_shared/sendResponse.ts";

// // Interface para cancelamento de assinatura
// interface CancelSubscriptionType {
//   userId: string;
//   subscriptionId?: string; // ID da assinatura no banco local (opcional se passar mercadoPagoId)
//   mercadoPagoId?: string; // ID da assinatura no Mercado Pago (opcional se passar subscriptionId)
// }

// const schema = yup.object({
//   userId: yup
//     .string()
//     .uuid("userId: O id do usuário deve ser um UUID válido")
//     .required("userId: O id do usuário é requerido"),

//   subscriptionId: yup
//     .string()
//     .uuid("subscriptionId: O id da assinatura deve ser um UUID válido")
//     .optional(),

//   mercadoPagoId: yup
//     .string()
//     .optional(),
// }).test(
//   "at-least-one-id",
//   "Você deve fornecer subscriptionId ou mercadoPagoId",
//   function (value) {
//     return !!(value.subscriptionId || value.mercadoPagoId);
//   }
// );

// Deno.serve(async (req) => {
//   if (req.method === "OPTIONS") {
//     return new Response(null, {
//       headers: { ...corsHeaders },
//     });
//   }

//   const requestData = await req.json();

//   log("CANCEL SUBSCRIPTION REQUEST DATA: ", requestData);

//   const supabase = createClient(
//     Deno.env.get("SUPABASE_URL") ?? "",
//     Deno.env.get("SUPABASE_ANON_KEY") ?? "",
//     {
//       global: { headers: { Authorization: req.headers.get("Authorization")! } },
//     },
//   );

//   let response: ResponseType = {
//     statusCode: 500,
//     message: "Erro desconhecido",
//     success: false,
//   };

//   try {
//     const validData = await schema.validate(requestData, {
//       abortEarly: false,
//     }) as unknown as CancelSubscriptionType;

//     log("VALID DATA: ", validData);

//     // Buscar informações da assinatura no banco de dados
//     let mercadoPagoPaymentId = validData.mercadoPagoId;
//     let transactionId: string | undefined;

//     if (!mercadoPagoPaymentId && validData.subscriptionId) {
//       // Buscar ID do Mercado Pago usando o ID da assinatura local
//       const { data: subscriptionData, error: subscriptionError } = await supabase
//         .from("tb_user_subscriptions")
//         .select(`
//           subscription_transaction_id,
//           tb_subscription_transactions!inner(
//             id,
//             mercadopago_payment_id,
//             payment_status
//           )
//         `)
//         .eq("id", validData.subscriptionId)
//         .eq("user_id", validData.userId)
//         .single();

//       if (subscriptionError || !subscriptionData) {
//         log("Erro ao buscar assinatura: ", subscriptionError);
//         response = {
//           statusCode: 404,
//           success: false,
//           message: "Assinatura não encontrada para este usuário",
//         };
//         return sendResponse(response);
//       }

//       mercadoPagoPaymentId = subscriptionData.tb_subscription_transactions.mercadopago_payment_id;
//       transactionId = subscriptionData.tb_subscription_transactions.id;
//     } else if (mercadoPagoPaymentId) {
//       // Buscar transaction_id usando mercadoPagoId
//       const { data: transactionData, error: transactionError } = await supabase
//         .from("tb_subscription_transactions")
//         .select("id")
//         .eq("mercadopago_payment_id", mercadoPagoPaymentId)
//         .single();

//       if (transactionError || !transactionData) {
//         log("Erro ao buscar transação: ", transactionError);
//         response = {
//           statusCode: 404,
//           success: false,
//           message: "Transação não encontrada",
//         };
//         return sendResponse(response);
//       }

//       transactionId = transactionData.id;
//     }

//     if (!mercadoPagoPaymentId) {
//       response = {
//         statusCode: 400,
//         success: false,
//         message: "ID do Mercado Pago não encontrado",
//       };
//       return sendResponse(response);
//     }

//     log("Cancelando assinatura no Mercado Pago - ID: ", mercadoPagoPaymentId);

//     // Cancelar assinatura no Mercado Pago
//     // Documentação: https://www.mercadopago.com.br/developers/pt/reference/subscriptions/_preapproval_id/put
//     const cancelResponse = await fetch(
//       `https://api.mercadopago.com/preapproval/${mercadoPagoPaymentId}`,
//       {
//         method: "PUT",
//         headers: {
//           ...corsHeaders,
//           ...defaultHeaders,
//         },
//         body: JSON.stringify({
//           status: "cancelled",
//         }),
//       },
//     );

//     const cancelResponseBody = await cancelResponse.json();
//     log("Mercado Pago Cancel Response: ", cancelResponseBody);

//     if (!cancelResponse.ok) {
//       response = {
//         success: false,
//         statusCode: cancelResponse.status,
//         message: "Erro ao cancelar assinatura no Mercado Pago",
//         data: cancelResponseBody,
//       };
//       return sendResponse(response);
//     }

//     // Atualizar status da transação no banco de dados local
//     if (transactionId) {
//       const { error: updateError } = await supabase
//         .from("tb_subscription_transactions")
//         .update({
//           status: "cancelled",
//           updated_at: new Date().toISOString(),
//         })
//         .eq("id", transactionId);

//       if (updateError) {
//         log("Erro ao atualizar status da transação no banco: ", updateError);
//         // Não falhar a requisição, pois o cancelamento no Mercado Pago foi bem-sucedido
//       } else {
//         log("Status da transação atualizado com sucesso");
//       }

//       // Atualizar tb_user_subscriptions para marcar como cancelada
//       const { error: userSubError } = await supabase
//         .from("tb_user_subscriptions")
//         .update({
//           status: "cancelled",
//           cancelled_at: new Date().toISOString(),
//           updated_at: new Date().toISOString(),
//         })
//         .eq("subscription_transaction_id", transactionId);

//       if (userSubError) {
//         log("Erro ao atualizar assinatura do usuário: ", userSubError);
//       } else {
//         log("Assinatura do usuário atualizada com sucesso");
//       }
//     }

//     response = {
//       statusCode: 200,
//       success: true,
//       message: "Assinatura cancelada com sucesso",
//       data: {
//         mercadoPagoId: mercadoPagoPaymentId,
//         status: cancelResponseBody.status,
//         transactionId: transactionId,
//       },
//     };
//   } catch (error) {
//     if (error instanceof yup.ValidationError) {
//       response = {
//         statusCode: 400,
//         success: false,
//         message: "Erro de validação",
//         data: (error as yup.ValidationError).errors,
//       };
//     } else {
//       response = {
//         statusCode: 500,
//         success: false,
//         message: `Erro ao cancelar assinatura: ${
//           error instanceof Error ? error.message : "Erro desconhecido"
//         }`,
//       };
//     }
//     log("ERROR: ", error);
//   }

//   return sendResponse(response);
// });
