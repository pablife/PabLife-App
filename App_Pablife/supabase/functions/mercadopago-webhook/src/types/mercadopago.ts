export type JsonPrimitive = string | number | boolean | null;
export type JsonValue = JsonPrimitive | JsonValue[] | JsonObject;
export type JsonObject = { [key: string]: JsonValue };

export type PaymentResponseType = MercadoPagoPaymentResponse;
export type MerchantOrderResponseType = MercadoPagoMerchantOrderResponse;
export type OrderResponseType = JsonObject;
export type PreapprovalResponseType = JsonObject;

export type MercadoPagoPaymentResponse = {
  payer?: PaymentPayerResponse;
  forward_data?: PaymentForwardDataResponse;
  additional_info?: PaymentAdditionalInfoResponse;
  order?: PaymentOrderResponse;
  transaction_details?: PaymentTransactionDetailsResponse;
  card?: PaymentCardResponse;
  point_of_interaction?: PaymentPointOfInteractionResponse;
  payment_method?: PaymentPaymentMethodResponse;
  three_ds_info?: PaymentThreeDSInfoResponse;
  back_urls?: PaymentBackURLsResponse;
  expanded?: PaymentExpandedResponse;
  date_created?: string;
  date_approved?: string | null;
  date_last_updated?: string;
  date_of_expiration?: string;
  money_release_date?: string | null;
  fee_details?: PaymentFeeDetailResponse[];
  taxes?: PaymentTaxResponse[];
  refunds?: PaymentRefundResponse[];
  amounts?: PaymentAmountsResponse;
  counter_currency?: PaymentCounterCurrencyResponse;
  differential_pricing_id?: number;
  money_release_schema?: string;
  operation_type?: string;
  issuer_id?: string;
  payment_method_id?: string;
  payment_type_id?: string;
  status?: string;
  status_detail?: string;
  currency_id?: string;
  description?: string | null;
  authorization_code?: string;
  integrator_id?: string;
  platform_id?: string;
  corporation_id?: string;
  notification_url?: string;
  callback_url?: string;
  processing_mode?: string;
  merchant_account_id?: string;
  merchant_number?: string;
  coupon_code?: string;
  external_reference?: string;
  payment_method_option_id?: string;
  pos_id?: string;
  store_id?: string;
  deduction_schema?: string;
  call_for_authorize_id?: string;
  statement_descriptor?: string;
  money_release_status?: string;
  transaction_amount?: number;
  transaction_amount_refunded?: number;
  coupon_amount?: number;
  taxes_amount?: number;
  shipping_amount?: number;
  net_amount?: number;
  installments?: number;
  id?: number;
  sponsor_id?: number;
  collector_id?: number;
  live_mode?: boolean;
  captured?: boolean;
  binary_mode?: boolean;
  metadata?: JsonObject;
  internal_metadata?: JsonObject;
  device_identifier?: string;
  device_id?: string;
};

export type PaymentPayerResponse = {
  type?: string;
  id?: string;
  email?: string;
  first_name?: string;
  last_name?: string;
  phone?: PaymentPhoneResponse;
  identification?: PaymentIdentificationResponse;
  address?: PaymentAddressResponse;
  registration_date?: string;
};

export type PaymentForwardDataResponse = {
  sub_merchant?: PaymentSubMerchantResponse;
};

export type PaymentSubMerchantResponse = {
  sub_merchant_id?: string;
  mcc?: string;
  country?: string;
  zip?: string;
  document_number?: string;
  city?: string;
  address_street?: string;
  legal_name?: string;
  region_code_iso?: string;
  region_code?: string;
  document_type?: string;
  phone?: string;
  url?: string;
  address_door_number?: string;
};

export type PaymentAdditionalInfoResponse = {
  payer?: PaymentAdditionalInfoPayerResponse;
  shipments?: PaymentShipmentsResponse;
  items?: PaymentItemResponse[];
  ip_address?: string;
};

export type PaymentAdditionalInfoPayerResponse = {
  phone?: PaymentPhoneResponse;
  address?: PaymentAddressResponse;
  registration_date?: string;
  first_name?: string;
  last_name?: string;
};

export type PaymentShipmentsResponse = {
  receiver_address?: PaymentReceiverAddressResponse;
};

export type PaymentReceiverAddressResponse = {
  address?: PaymentAddressResponse;
  zip_code?: string;
  state_name?: string;
  city_name?: string;
  street_name?: string;
  street_number?: number;
  country_name?: string;
  floor?: string;
  apartment?: string;
  local_pic_url?: string;
  express_shipment_id?: string;
};

export type PaymentItemResponse = {
  id?: string;
  title?: string;
  description?: string;
  picture_url?: string;
  category_id?: string;
  quantity?: number;
  unit_price?: number;
  event_date?: string;
  warranty?: boolean;
  category_descriptor?: PaymentCategoryDescriptorResponse;
  type?: string;
};

export type PaymentCategoryDescriptorResponse = {
  passenger?: PaymentPassengerResponse;
  route?: PaymentRouteResponse;
  event_date?: string;
  type?: string;
};

export type PaymentPassengerResponse = {
  first_name?: string;
  last_name?: string;
  identification?: PaymentIdentificationResponse;
  type?: string;
};

export type PaymentRouteResponse = {
  departure?: string;
  destination?: string;
  departure_date_time?: string;
  arrival_date_time?: string;
  company?: string;
};

export type PaymentOrderResponse = {
  id?: string;
  type?: string;
};

export type PaymentTransactionDetailsResponse = {
  barcode?: PaymentBarcodeResponse;
  financial_institution?: string;
  external_resource_url?: string;
  payment_method_reference_id?: string;
  acquirer_reference?: string;
  transaction_id?: string;
  digitable_line?: string;
  verification_code?: string;
  payable_deferral_period?: string;
  net_received_amount?: number;
  total_paid_amount?: number;
  installment_amount?: number;
  overpaid_amount?: number;
  bank_transfer_id?: number;
};

export type PaymentBarcodeResponse = {
  content?: string;
};

export type PaymentCardResponse = {
  cardholder?: PaymentCardholderResponse;
  date_created?: string;
  date_last_updated?: string;
  id?: string;
  last_four_digits?: string;
  first_six_digits?: string;
  expiration_year?: number;
  expiration_month?: number;
};

export type PaymentCardholderResponse = {
  identification?: PaymentIdentificationResponse;
  name?: string;
};

export type PaymentPaymentMethodResponse = {
  data?: PaymentDataResponse;
  id?: string;
  type?: string;
  issuer_id?: string;
};

export type PaymentDataResponse = {
  rules?: PaymentRulesResponse;
  reference_id?: string;
  external_reference_id?: string;
  external_resource_url?: string;
};

export type PaymentRulesResponse = {
  fine?: PaymentFeeResponse;
  interest?: PaymentFeeResponse;
  discounts?: PaymentDiscountResponse[];
};

export type PaymentFeeResponse = {
  type?: string;
  value?: number;
};

export type PaymentDiscountResponse = {
  limit_date?: string;
  type?: string;
  value?: number;
};

export type PaymentFeeDetailResponse = {
  type?: string;
  fee_payer?: string;
  amount?: number;
};

export type PaymentPointOfInteractionResponse = {
  application_data?: PaymentApplicationDataResponse;
  transaction_data?: PaymentTransactionDataResponse;
  type?: string;
  sub_type?: string;
  linked_to?: string;
};

export type PaymentApplicationDataResponse = {
  name?: string;
  version?: string;
};

export type PaymentTransactionDataResponse = {
  bank_info?: PaymentBankInfoResponse;
  subscription_sequence?: PaymentSubscriptionSequenceResponse;
  invoice_period?: PaymentInvoicePeriodResponse;
  payment_reference?: PaymentPaymentReferenceResponse;
  qr_code?: string;
  qr_code_base64?: string;
  transaction_id?: string;
  ticket_url?: string;
  subscription_id?: string;
  billing_date?: string;
  bank_transfer_id?: number;
  financial_institution?: string;
  first_time_use?: boolean;
};

export type PaymentBankInfoResponse = {
  payer?: PaymentBankInfoPayerResponse;
  collector?: PaymentBankInfoCollectorResponse;
  is_same_bank_account_owner?: boolean;
};

export type PaymentBankInfoPayerResponse = {
  email?: string;
  long_name?: string;
  account_id?: string;
};

export type PaymentBankInfoCollectorResponse = {
  long_name?: string;
  account_id?: string;
};

export type PaymentSubscriptionSequenceResponse = {
  number?: number;
  total?: number;
};

export type PaymentInvoicePeriodResponse = {
  type?: string;
  period?: number;
};

export type PaymentPaymentReferenceResponse = {
  id?: string;
};

export type PaymentThreeDSInfoResponse = {
  external_resource_url?: string;
  creq?: string;
};

export type PaymentBackURLsResponse = {
  success?: string;
  pending?: string;
  failure?: string;
};

export type PaymentExpandedResponse = {
  gateway?: PaymentGatewayResponse;
};

export type PaymentGatewayResponse = {
  reference?: PaymentGatewayReferenceResponse;
};

export type PaymentGatewayReferenceResponse = {
  network_transaction_id?: string;
};

export type PaymentRefundResponse = {
  source?: PaymentSourceResponse;
  date_created?: string;
  status?: string;
  refund_mode?: string;
  reason?: string;
  unique_sequence_number?: string;
  amount?: number;
  adjustment_amount?: number;
  id?: number;
  payment_id?: number;
};

export type PaymentSourceResponse = {
  id?: string;
  name?: string;
  type?: string;
};

export type PaymentTaxResponse = {
  type?: string;
  amount?: number;
};

export type PaymentAmountsResponse = {
  collector?: PaymentCollectorAmountResponse;
  payer?: PaymentPayerAmountResponse;
};

export type PaymentCollectorAmountResponse = {
  currency_id?: string;
  transaction?: number;
  net_received?: number;
};

export type PaymentPayerAmountResponse = {
  currency_id?: string;
  transaction?: number;
  total_paid?: number;
};

export type PaymentCounterCurrencyResponse = {
  currency_id?: string;
  rate?: number;
  amount?: number;
  amount_refunded?: number;
};

export type PaymentPhoneResponse = {
  area_code?: string;
  number?: string;
};

export type PaymentIdentificationResponse = {
  type?: string;
  number?: string;
};

export type PaymentAddressResponse = {
  zip_code?: string;
  street_name?: string;
  street_number?: number;
};

export type MercadoPagoMerchantOrderResponse = {
  payer?: MerchantOrderPayerResponse;
  collector?: MerchantOrderCollectorResponse;
  date_created?: string;
  last_updated?: string;
  items?: MerchantOrderItemResponse[];
  shipments?: MerchantOrderShipmentResponse[];
  payments?: MerchantOrderPaymentResponse[];
  preference_id?: string;
  application_id?: string;
  status?: string;
  site_id?: string;
  notification_url?: string;
  additional_info?: string;
  external_reference?: string;
  marketplace?: string;
  sponsor_id?: string | number;
  order_status?: string;
  paid_amount?: number;
  refunded_amount?: number;
  shipping_cost?: number;
  total_amount?: number;
  id?: number;
  cancelled?: boolean;
};

export type MerchantOrderPayerResponse = {
  nickname?: string;
  id?: number;
};

export type MerchantOrderCollectorResponse = {
  nickname?: string;
  id?: number;
};

export type MerchantOrderItemResponse = {
  id?: string;
  title?: string;
  description?: string;
  picture_url?: string;
  currency_id?: string;
  category_id?: string;
  unit_price?: number;
  quantity?: number;
};

export type MerchantOrderPaymentResponse = {
  date_approved?: string;
  date_created?: string;
  last_modified?: string;
  status?: string;
  operation_type?: string;
  currency_id?: string;
  transaction_amount?: number;
  total_paid_amount?: number;
  shipping_cost?: number;
  amount_refunded?: number;
  id?: number;
};

export type MerchantOrderShipmentResponse = {
  receiver_address?: MerchantOrderReceiverAddressResponse;
  shipping_option?: MerchantOrderShippingOptionResponse;
  date_created?: string;
  last_modified?: string;
  date_first_printed?: string;
  shipping_type?: string;
  shipping_mode?: string;
  picking_type?: string;
  status?: string;
  shipping_substatus?: string;
  service_id?: string;
  id?: number;
  sender_id?: number;
  receiver_id?: number;
  items?: JsonObject[];
};

export type MerchantOrderReceiverAddressResponse = {
  city?: MerchantOrderCityResponse;
  state?: MerchantOrderStateResponse;
  country?: MerchantOrderCountryResponse;
  address_line?: string;
  apartment?: string;
  comment?: string;
  contact?: string;
  zip_code?: string;
  street_name?: string;
  street_number?: string;
  floor?: string;
  phone?: string;
  latitude?: string;
  longitude?: string;
  id?: number;
};

export type MerchantOrderCityResponse = {
  id?: string;
  name?: string;
};

export type MerchantOrderStateResponse = {
  id?: string;
  name?: string;
};

export type MerchantOrderCountryResponse = {
  id?: string;
  name?: string;
};

export type MerchantOrderShippingOptionResponse = {
  speed?: MerchantOrderSpeedResponse;
  estimated_delivery?: MerchantOrderEstimatedDeliveryResponse;
  name?: string;
  currency_id?: string;
  cost?: number;
  list_cost?: number;
  id?: number;
  shipping_method_id?: number;
};

export type MerchantOrderSpeedResponse = {
  handling?: number;
  shipping?: number;
};

export type MerchantOrderEstimatedDeliveryResponse = {
  date?: string;
  time_from?: number;
  time_to?: number;
};
