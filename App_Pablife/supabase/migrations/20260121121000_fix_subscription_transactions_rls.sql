-- Fix: allow users to read their own subscription transactions (admin override)
DROP POLICY IF EXISTS "View subscription transactions" ON public.tb_subscription_transactions;
CREATE POLICY "View subscription transactions"
ON public.tb_subscription_transactions
FOR SELECT
TO authenticated
USING (
  public.is_admin()
  OR EXISTS (
    SELECT 1
    FROM public.tb_user_subscriptions
    WHERE
      public.tb_user_subscriptions.id
      = public.tb_subscription_transactions.user_subscription_id
      AND public.tb_user_subscriptions.user_id = auth.uid()
  )
);
