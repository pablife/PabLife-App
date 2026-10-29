import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from 'jsr:@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

interface NotificationRequest {
  title: string;
  message: string;
  appointmentId: number;
  professionalId?: number;
  customerId?: number;
}

Deno.serve(async (req: Request) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // Get environment variables
    const oneSignalAppId = Deno.env.get('ONESIGNAL_APP_ID');
    const oneSignalRestApiKey = Deno.env.get('ONESIGNAL_REST_API_KEY');
    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

    if (!oneSignalAppId || !oneSignalRestApiKey || !supabaseUrl || !supabaseServiceKey) {
      throw new Error('Missing required environment variables');
    }

    // Initialize Supabase client
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Parse request body
    const { title, message, appointmentId, professionalId, customerId }: NotificationRequest = await req.json();

    if (!title || !message || !appointmentId || (!professionalId && !customerId)) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: title, message, appointmentId, and either professionalId or customerId' }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      );
    }

    // Prepare OneSignal request
    const oneSignalUrl = 'https://onesignal.com/api/v1/notifications';
    const headers = {
      'Content-Type': 'application/json; charset=utf-8',
      'Authorization': `Basic ${oneSignalRestApiKey}`,
    };

    // Check for dual accounts
    const targetUserIds: string[] = [];
    
    if (professionalId) {
      // Buscar o email do profissional
      const { data: professionalData, error: profError } = await supabase
        .from('users')
        .select('email, role')
        .eq('id', professionalId)
        .single();

      if (!profError && professionalData) {
        targetUserIds.push(professionalId.toString());
        
        // Buscar se existe conta de cliente com o mesmo email
        const { data: dualAccountData, error: dualError } = await supabase
          .from('users')
          .select('id, role')
          .eq('email', professionalData.email)
          .eq('role', 'customer')
          .neq('id', professionalId);

        if (!dualError && dualAccountData && dualAccountData.length > 0) {
          // Usuário tem conta dupla - adicionar ambos IDs
          targetUserIds.push(dualAccountData[0].id.toString());
          console.log(`Found dual account for professional ${professionalId}: customer ${dualAccountData[0].id}`);
        }
      } else {
        targetUserIds.push(professionalId.toString());
      }
    } else if (customerId) {
      // Buscar o email do cliente
      const { data: customerData, error: custError } = await supabase
        .from('users')
        .select('email, role')
        .eq('id', customerId)
        .single();

      if (!custError && customerData) {
        targetUserIds.push(customerId.toString());
        
        // Buscar se existe conta de profissional com o mesmo email
        const { data: dualAccountData, error: dualError } = await supabase
          .from('users')
          .select('id, role')
          .eq('email', customerData.email)
          .eq('role', 'professional')
          .neq('id', customerId);

        if (!dualError && dualAccountData && dualAccountData.length > 0) {
          // Usuário tem conta dupla - adicionar ambos IDs
          targetUserIds.push(dualAccountData[0].id.toString());
          console.log(`Found dual account for customer ${customerId}: professional ${dualAccountData[0].id}`);
        }
      } else {
        targetUserIds.push(customerId.toString());
      }
    } else {
      return new Response(
        JSON.stringify({ error: 'Must specify either professionalId or customerId' }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      );
    }

    // Determinar IDs de cliente e profissional para verificação e salvamento
    let finalCustomerId: number | null = customerId || null;
    let finalProfessionalId: number | null = professionalId || null;
    
    // Se enviamos para múltiplos IDs (conta dupla), precisamos descobrir qual é cliente e qual é profissional
    if (targetUserIds.length > 1) {
      // Já temos os IDs de contas duplas que encontramos acima
      // Precisamos verificar qual é qual para salvar corretamente
      for (const userId of targetUserIds) {
        const { data: userData, error: userError } = await supabase
          .from('users')
          .select('id, role')
          .eq('id', parseInt(userId))
          .single();
          
        if (!userError && userData) {
          if (userData.role === 'customer' && finalCustomerId === null) {
            finalCustomerId = userData.id;
          } else if (userData.role === 'professional' && finalProfessionalId === null) {
            finalProfessionalId = userData.id;
          }
        }
      }
    }

    // Verificar se já existe notificação duplicada
    const { data: existingNotification, error: checkError } = await supabase
      .from('notifications')
      .select('id')
      .eq('title', title)
      .eq('message', message)
      .eq('appointmentId', appointmentId)
      .eq('professionalId', finalProfessionalId)
      .eq('customerId', finalCustomerId)
      .limit(1)
      .single();

    if (!checkError && existingNotification) {
      // Notificação já existe, retornar sem enviar
      return new Response(
        JSON.stringify({ 
          success: false, 
          message: 'Notification already exists',
          appointmentId: appointmentId
        }),
        { 
          status: 200, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      );
    }

    // Build OneSignal payload
    interface OneSignalPayload {
      app_id: string;
      headings: { en: string };
      contents: { en: string };
      priority: number;
      small_icon: string;
      large_icon: string;
      android_accent_color: string;
      android_led_color: string;
      data: {
        appointmentId: number;
      };
      include_external_user_ids: string[];
    }
    
    const oneSignalPayload: OneSignalPayload = {
      app_id: oneSignalAppId, // App ID do OneSignal (variável de ambiente)
      headings: { en: title },
      contents: { en: message },
      priority: 10,
      small_icon: 'ic_stat_onesignal_default', 
      large_icon: 'ic_launcher',
      android_accent_color: 'FFC843A4', 
      android_led_color: 'FFC843A4', 
      data: {
        appointmentId: appointmentId
      },
      include_external_user_ids: targetUserIds
    };

    // Send notification via OneSignal
    const oneSignalResponse = await fetch(oneSignalUrl, {
      method: 'POST',
      headers: headers,
      body: JSON.stringify(oneSignalPayload),
    });

    if (!oneSignalResponse.ok) {
      const errorText = await oneSignalResponse.text();
      console.error('OneSignal API error:', errorText);
      return new Response(
        JSON.stringify({ error: 'Failed to send notification via OneSignal', details: errorText }),
        { 
          status: oneSignalResponse.status, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      );
    }

      await oneSignalResponse.json();

    // Save notification to database
    // Inserir uma notificação combinando ambos os perfis
    const { error: dbError } = await supabase
      .from('notifications')
      .insert({
        title: title,
        message: message,
        appointmentId: appointmentId,
        professionalId: finalProfessionalId,
        customerId: finalCustomerId,
        createdAt: new Date().toISOString()
      });

    if (dbError) {
      console.error('Database error:', dbError);
      return new Response(
        JSON.stringify({ error: 'Notification sent but failed to save to database', details: dbError.message }),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      );
    }

    return new Response(
      JSON.stringify({ 
        success: true, 
        message: 'Notification sent successfully',
        appointmentId: appointmentId
      }),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    );

  } catch (error) {
    console.error('Error in send-notification function:', error);
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    return new Response(
      JSON.stringify({ error: 'Internal server error', details: errorMessage }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    );
  }
});
