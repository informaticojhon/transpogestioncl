// Edge Function: eliminar-empleado
//
// Borra por completo la cuenta (Supabase Auth) de un empleado.
// Solo puede ejecutarla un admin, sobre un miembro de su MISMA
// empresa, y nunca sobre sí mismo.
//
// La service_role key vive únicamente aquí (variable de entorno del
// servidor, inyectada automáticamente por Supabase) — nunca llega a
// la app Flutter. Por eso esta operación no se puede hacer desde el
// cliente directamente.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'No autenticado' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const { targetUserId } = await req.json();
    if (!targetUserId) {
      return new Response(JSON.stringify({ error: 'Falta targetUserId' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Cliente "como el usuario que llama" (respeta RLS) para verificar identidad y permisos.
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!;
    const callerClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: { user: caller }, error: authError } = await callerClient.auth.getUser();
    if (authError || !caller) {
      return new Response(JSON.stringify({ error: 'Sesión inválida' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (caller.id === targetUserId) {
      return new Response(JSON.stringify({ error: 'No puedes eliminar tu propia cuenta desde aquí' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const { data: callerPerfil, error: callerError } = await callerClient
      .from('usuarios')
      .select('rol, empresa_id')
      .eq('id', caller.id)
      .single();

    if (callerError || !callerPerfil || callerPerfil.rol !== 'admin') {
      return new Response(JSON.stringify({ error: 'Solo un administrador puede eliminar miembros' }), {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const { data: targetPerfil, error: targetError } = await callerClient
      .from('usuarios')
      .select('empresa_id')
      .eq('id', targetUserId)
      .single();

    if (targetError || !targetPerfil || targetPerfil.empresa_id !== callerPerfil.empresa_id) {
      return new Response(JSON.stringify({ error: 'Ese usuario no pertenece a tu empresa' }), {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Recién aquí se usa la service_role, para las operaciones que
    // realmente la necesitan: borrar el perfil y la cuenta de Auth.
    //
    // usuarios.id NO tiene una foreign key hacia auth.users(id) (solo
    // coinciden por convención), así que borrar el usuario de Auth no
    // elimina en cascada su fila en "usuarios" — hay que hacerlo a mano,
    // y antes de borrar la cuenta de Auth (si esto fallara, el usuario
    // queda al menos sin acceso a la empresa, en vez de seguir apareciendo
    // en el equipo con una cuenta ya inexistente).
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const adminClient = createClient(supabaseUrl, serviceRoleKey);

    const { error: perfilError } = await adminClient
      .from('usuarios')
      .delete()
      .eq('id', targetUserId);

    if (perfilError) {
      console.error('eliminar-empleado: error al borrar perfil', perfilError);
      return new Response(JSON.stringify({ error: 'No se pudo eliminar la cuenta' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const { error: deleteError } = await adminClient.auth.admin.deleteUser(targetUserId);
    if (deleteError) {
      console.error('eliminar-empleado: error al borrar cuenta de Auth', deleteError);
      return new Response(JSON.stringify({ error: 'No se pudo eliminar la cuenta' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    return new Response(JSON.stringify({ success: true }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
