/**
 * Gera uma chave de idempotência aleatória.
 * @return {string} Uma chave de idempotência de 16 caracteres.
 */
export function generateIdempotencyKey(): string {
    const chars = "abcdefghijklmnopqrstuvwxyz0123456789";
    const keyLength = 16;
    let result = "";
  
    for (let i = 0; i < keyLength; i++) {
      const randomIndex = Math.floor(Math.random() * chars.length);
      result += chars[randomIndex];
    }
  
    return result;
  }