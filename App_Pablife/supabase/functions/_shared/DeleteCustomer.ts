import { defaultHeaders } from "./defaultHeaders.ts";
import { log } from "./Log.ts";

/**
 * Deleta um customer no Mercado Pago
 * @param customerId ID do customer
 * @returns true se deletado com sucesso, false caso contrário
 */
export async function deleteCustomer(customerId: string): Promise<boolean> {
  try {
    log("Deletando customer no Mercado Pago:", customerId);

    const response = await fetch(
      `https://api.mercadopago.com/v1/customers/${customerId}`,
      {
        method: "DELETE",
        headers: defaultHeaders,
      }
    );

    if (!response.ok) {
      const errorData = await response.json();
      log("Erro ao deletar customer:", errorData);
      return false;
    }

    log("Customer deletado com sucesso");
    return true;
  } catch (error) {
    log("Erro ao deletar customer:", error);
    return false;
  }
}


