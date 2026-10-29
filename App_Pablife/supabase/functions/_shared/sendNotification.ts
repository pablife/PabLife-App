import { corsHeaders } from "./cors.ts";
import { defaultHeaders } from "./defaultHeaders.ts";
import { generateIdempotencyKey } from "./GenerateIdempotencyKey.ts";

export const sendNotification = async (
  customerId: number | null,
  professionalId: number | null,
  title: string,
  message: string,
  appointmentId: number,
) => {
  console.log("Sending notification to customer: ", customerId);
  console.log("Sending notification to professional: ", professionalId);
  console.log("Sending notification to appointment: ", appointmentId);
  console.log("Sending notification to title: ", title);
  console.log("Sending notification to message: ", message);

  return await fetch(
    "https://nvdqqakigeebsfyfabgw.supabase.co/functions/v1/send-notification",
    {
      method: "POST",
      headers: {
        ...corsHeaders,
        ...defaultHeaders,
        "X-Idempotency-Key": generateIdempotencyKey(),
        "Authorization": `Bearer ${Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")}`,
      },
      body: JSON.stringify({
        customerId: customerId,
        professionalId: professionalId,
        title: title,
        message: message,
        appointmentId: appointmentId,
      }),
    },
  ).then((response) => response.json()).then((data) => {
    console.log("Notification sent successfully: ", data);
  }).catch((error) => {
    console.error("Error sending notification: ", error);
  });
};
