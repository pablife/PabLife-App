-- Fix: allow users to read their own subscriptions (admin override)
DROP POLICY IF EXISTS "View user subscriptions" ON public.tb_user_subscriptions;
CREATE POLICY "View user subscriptions"
ON public.tb_user_subscriptions
FOR SELECT
TO authenticated
USING (public.is_admin() OR user_id = auth.uid());
