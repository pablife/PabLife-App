
export function getDocumentType(document: string): string | null {
    const isCPF = document.length === 11;
    const isCNPJ = document.length === 14;
  
    if (isCPF) {
      return "CPF";
    } else if (isCNPJ) {
      return "CNPJ";
    } 
  
    return null;
  }
  