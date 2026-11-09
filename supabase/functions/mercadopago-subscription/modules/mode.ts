// Modo de teste: a função "mercadopago-subscription-test" é publicada com
// TEST_MODE = true e usa as credenciais de TESTE do Mercado Pago (nada é
// cobrado de verdade). A função oficial é publicada com false.
export const TEST_MODE = false;

export const MP_ACCESS_TOKEN_ENV = TEST_MODE
  ? "MERCADOPAGO_TEST_ACCESS_TOKEN"
  : "MERCADOPAGO_ACCESS_TOKEN";

export const MP_PUBLIC_KEY_ENV = TEST_MODE
  ? "MERCADOPAGO_TEST_PUBLIC_KEY"
  : "MERCADOPAGO_PUBLIC_KEY";
