DROP POLICY IF EXISTS "View Mercado Pago webhook events"
ON public.tb_mercadopago_webhook_events;
CREATE POLICY "View Mercado Pago webhook events"
ON public.tb_mercadopago_webhook_events FOR SELECT
USING (
  public.is_admin()
);

DROP POLICY IF EXISTS "Update Mercado Pago webhook events"
ON public.tb_mercadopago_webhook_events;
CREATE POLICY "Update Mercado Pago webhook events"
ON public.tb_mercadopago_webhook_events FOR UPDATE
USING (
  public.is_admin()
)
WITH CHECK (
  public.is_admin()
);

DROP POLICY IF EXISTS "Create Mercado Pago webhook events"
ON public.tb_mercadopago_webhook_events;
CREATE POLICY "Create Mercado Pago webhook events"
ON public.tb_mercadopago_webhook_events FOR INSERT
WITH CHECK (
  public.is_admin()
);

DROP POLICY IF EXISTS "Delete Mercado Pago webhook events"
ON public.tb_mercadopago_webhook_events;
CREATE POLICY "Delete Mercado Pago webhook events"
ON public.tb_mercadopago_webhook_events FOR DELETE
USING (
  public.is_admin()
);
