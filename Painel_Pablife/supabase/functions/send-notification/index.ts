import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

interface OneSignalNotificationRequest {
  title: string;
  message: string;
  userId?: string;
  appointmentId?: string;
  professionalId?: string;
  customerId?: string;
  data?: Record<string, any>;
}

interface OneSignalResponse {
  id: string;
  recipients: number;
  external_id?: string;
}

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req) => {
  console.log("🚀 OneSignal function called with method:", req.method);

  if (req.method === "OPTIONS") {
    console.log("📡 Handling CORS preflight request");
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    console.log("🔧 Creating Supabase client");
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      {
        global: {
          headers: { Authorization: req.headers.get("Authorization")! },
        },
      }
    );

    const {
      title,
      message,
      userId,
      appointmentId,
      professionalId,
      customerId,
      data,
    }: OneSignalNotificationRequest = await req.json();

    console.log("📝 Request data:", {
      title,
      message,
      userId,
      appointmentId,
      professionalId,
      customerId,
      data,
    });

    if (!title || !message) {
      console.log("❌ Missing title or message");
      return new Response(
        JSON.stringify({ error: "Título e mensagem são obrigatórios" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Validação específica para notificações de agendamento
    if (appointmentId && !professionalId && !customerId) {
      console.log("❌ Appointment notification missing professionalId or customerId");
      return new Response(
        JSON.stringify({
          error:
            "Notificações de agendamento requerem professionalId ou customerId",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    console.log("🔑 Getting OneSignal credentials");
    const oneSignalAppId = Deno.env.get("ONESIGNAL_APP_ID");
    const oneSignalApiKey = Deno.env.get("ONESIGNAL_REST_API_KEY");
    console.log("🔑 OneSignal App ID exists:", !!oneSignalAppId);
    console.log("🔑 OneSignal API Key exists:", !!oneSignalApiKey);

    if (!oneSignalAppId || !oneSignalApiKey) {
      console.log("❌ OneSignal credentials missing");
      return new Response(
        JSON.stringify({ error: "Configuração do OneSignal não encontrada" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    let playerIds: string[] = [];

    if (userId) {
      console.log("👤 Looking up user:", userId);
      const { data: user, error: userError } = await supabaseClient
        .from("users")
        .select("onesignal_player_id")
        .eq("id", userId)
        .single();

      if (userError) {
        console.log("❌ User not found:", userError);
        return new Response(
          JSON.stringify({ error: "Usuário não encontrado" }),
          {
            status: 404,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      console.log("👤 User found, player ID:", user.onesignal_player_id);

      if (user.onesignal_player_id) {
        playerIds = [user.onesignal_player_id];
        console.log("✅ Player ID added to notification list");
      } else {
        console.log("❌ User has no OneSignal player ID");
        return new Response(
          JSON.stringify({ error: "Usuário não possui token de notificação" }),
          {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }
    } else {
      console.log("📢 Sending notification to all users");
    }

    const oneSignalPayload = {
      app_id: oneSignalAppId,
      contents: { en: message, pt: message },
      headings: { en: title, pt: title },
      target_channel: "push",
      priority: 10,
      ios_interruption_level: "active",
      ios_badgeType: "None",
      ttl: 259200, // 3 days
      huawei_category: "MARKETING",
      huawei_msg_type: "message",
      ...(userId
        ? { include_player_ids: playerIds }
        : { included_segments: ["All"] }),
      ...(data && { data }),
    };

    console.log(
      "📤 OneSignal payload:",
      JSON.stringify(oneSignalPayload, null, 2)
    );
    console.log("🌐 Calling OneSignal API...");

    const oneSignalResponse = await fetch(
      "https://api.onesignal.com/notifications?c=push",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Basic ${oneSignalApiKey}`,
        },
        body: JSON.stringify(oneSignalPayload),
      }
    );

    console.log("📡 OneSignal response status:", oneSignalResponse.status);

    if (!oneSignalResponse.ok) {
      const errorText = await oneSignalResponse.text();
      console.error("❌ OneSignal API Error:", errorText);
      return new Response(
        JSON.stringify({ error: "Erro ao enviar notificação via OneSignal" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const oneSignalResult: OneSignalResponse = await oneSignalResponse.json();
    console.log(
      "📡 OneSignal response body:",
      JSON.stringify(oneSignalResult, null, 2),
    );

    if (!userId) {
      console.log("💾 Saving broadcast notification to database");
      const { error: insertError } = await supabaseClient
        .from("tb_notifications")
        .insert({
          title: title,
          message: message,
          ...(appointmentId && { appointment_id: appointmentId }),
          ...(professionalId && { professional_id: professionalId }),
          ...(customerId && { customer_id: customerId }),
        });

      if (insertError) {
        console.error("❌ Error saving notification to database:", insertError);
      } else {
        console.log("✅ Notification saved successfully");
      }
    }

    // Check if there are any errors in the response
    if (
      oneSignalResult.errors &&
      Object.keys(oneSignalResult.errors).length > 0
    ) {
      console.log("❌ OneSignal returned errors:", oneSignalResult.errors);

      // Handle invalid player IDs
      if (
        oneSignalResult.errors.invalid_player_ids &&
        oneSignalResult.errors.invalid_player_ids.length > 0
      ) {
        console.log(
          "❌ Invalid player IDs found:",
          oneSignalResult.errors.invalid_player_ids
        );

        // Clean up invalid player IDs from database
        for (const invalidPlayerId of oneSignalResult.errors
          .invalid_player_ids) {
          console.log(`🧹 Cleaning up invalid player ID: ${invalidPlayerId}`);
          await supabaseClient
            .from("users")
            .update({ onesignal_player_id: null })
            .eq("onesignal_player_id", invalidPlayerId);
        }

        return new Response(
          JSON.stringify({
            error:
              "Player ID inválido. O usuário precisa abrir o app novamente para registrar um novo token de notificação.",
            invalidPlayerIds: oneSignalResult.errors.invalid_player_ids,
          }),
          {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      return new Response(
        JSON.stringify({
          error: "Erro do OneSignal: " + JSON.stringify(oneSignalResult.errors),
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const response = {
      success: true,
      notificationId: oneSignalResult.id,
      recipients: oneSignalResult.recipients,
      message: userId
        ? `Notificação enviada para o usuário ${userId}`
        : "Notificação enviada para todos os usuários",
    };

    console.log("🎉 Function completed successfully:", response);
    return new Response(JSON.stringify(response), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("💥 Unexpected error in OneSignal function:", error);
    return new Response(JSON.stringify({ error: "Erro interno do servidor" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
