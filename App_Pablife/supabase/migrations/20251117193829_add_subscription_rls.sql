-- Políticas RLS para tb_subscription_plans
DROP POLICY IF EXISTS "View subscription plans" ON public.tb_subscription_plans;
CREATE POLICY "View subscription plans"
ON public.tb_subscription_plans
FOR SELECT
TO authenticated
USING (deleted_at IS NULL);

DROP POLICY IF EXISTS "Create subscription plans" ON public.tb_subscription_plans;
CREATE POLICY "Create subscription plans"
ON public.tb_subscription_plans
FOR INSERT
TO authenticated
WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "Update subscription plans" ON public.tb_subscription_plans;
CREATE POLICY "Update subscription plans"
ON public.tb_subscription_plans
FOR UPDATE
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "Delete subscription plans" ON public.tb_subscription_plans;
CREATE POLICY "Delete subscription plans"
ON public.tb_subscription_plans
FOR DELETE
TO authenticated
USING (public.is_admin());

-- Políticas RLS para tb_subscription_transactions
DROP POLICY IF EXISTS "View subscription transactions" ON public.tb_subscription_transactions;
CREATE POLICY "View subscription transactions"
ON public.tb_subscription_transactions
FOR SELECT
TO authenticated
USING (public.is_admin());

DROP POLICY IF EXISTS "Create subscription transactions" ON public.tb_subscription_transactions;
CREATE POLICY "Create subscription transactions"
ON public.tb_subscription_transactions
FOR INSERT
TO authenticated
WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "Update subscription transactions" ON public.tb_subscription_transactions;
CREATE POLICY "Update subscription transactions"
ON public.tb_subscription_transactions
FOR UPDATE
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "Delete subscription transactions" ON public.tb_subscription_transactions;
CREATE POLICY "Delete subscription transactions"
ON public.tb_subscription_transactions
FOR DELETE
TO authenticated
USING (public.is_admin());

-- Políticas RLS para tb_user_subscriptions
DROP POLICY IF EXISTS "View user subscriptions" ON public.tb_user_subscriptions;
CREATE POLICY "View user subscriptions"
ON public.tb_user_subscriptions
FOR SELECT
TO authenticated
USING (user_id = auth.uid() AND public.is_admin());

DROP POLICY IF EXISTS "Create user subscriptions" ON public.tb_user_subscriptions;
CREATE POLICY "Create user subscriptions"
ON public.tb_user_subscriptions
FOR INSERT
TO authenticated
WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "Update user subscriptions" ON public.tb_user_subscriptions;
CREATE POLICY "Update user subscriptions"
ON public.tb_user_subscriptions
FOR UPDATE
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "Delete user subscriptions" ON public.tb_user_subscriptions;
CREATE POLICY "Delete user subscriptions"
ON public.tb_user_subscriptions
FOR DELETE
TO authenticated
USING (public.is_admin());
