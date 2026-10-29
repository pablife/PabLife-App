export enum CardType {debit, credit};

export function getCardBrand(cardNumber: string, type: CardType): string | null {
    const cardNumberStr = cardNumber.replace(/\D/g, '');
    const regex = {
      visa: /^4[0-9]{12}(?:[0-9]{3})?$/,
      mastercard: /^(5[1-5][0-9]{14}|22[2-9][0-9]{12}|2[3-7][0-9]{13}|50[0-9]{14})$/,
      amex: /^3[47][0-9]{13}$/,
      discover: /^6(?:011|5[0-9]{2})[0-9]{12}$/,
      diners: /^3(?:0[0-5]|[68][0-9])[0-9]{11}$/,
      jcb: /^(?:2131|1800|35\d{3})\d{11}$/,
    };
  
    let brand: string | null = null;

    if (regex.visa.test(cardNumberStr)) brand = 'visa';
    else if (regex.mastercard.test(cardNumberStr)) brand= 'master';
    else if (regex.amex.test(cardNumberStr)) brand= 'amex';
    else if (regex.discover.test(cardNumberStr)) brand= 'discover';

    if (type == CardType.debit) {
      return `deb${brand}`;
    }
  
    return brand;
  }