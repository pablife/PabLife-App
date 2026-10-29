/*
It is the payment's current state. It can be of the following types.
pending: The user has not yet completed the payment process (e.g., after generating a boleto, the payment will be completed when the user pays at the selected location).
approved: The payment has been successfully approved and credited.
authorized: The payment has been authorized but is not yet captured.
in_process: The payment is currently under review.
in_mediation: The user has initiated a dispute.
rejected: The payment was rejected (the user may attempt to pay again).
cancelled: The payment was either canceled by a party or expired.
refunded: The payment was refunded to the user.
charged_back: A chargeback was issued on the buyer's credit card.
*/
export enum PaymentStatus {
    pending = "pending",
    approved = "approved",
    authorized = "authorized",
    in_process = "in_process",
    in_mediation = "in_mediation",
    cancelled = "cancelled",
    rejected = "rejected",
    refunded = "refunded",
    charged_back = "charged_back"
}