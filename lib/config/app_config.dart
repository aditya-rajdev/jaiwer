class ApiConfig {
  ApiConfig._();

  static const String baseUrl = 'https://jaiwer-backend.onrender.com';

  static const String goldRates = '/market-rates/gold';
  static const String silverRates = '/market-rates/silver';
  static const String addCustomer = '/add-customer';
  static const String existingCustomer = '/existing-customer';
  static const String refreshAuth = '/auth/refresh';

  // Live Backend Supplier Endpoints (/api base)
  static const String suppliers = '/api';
  static const String supplierExisting = '/api/existing';
  static const String supplierPayment = '/api/payment';
  static const String supplierTransactions = '/api/supplier-transactions';

  static String get goldRatesUrl => '$baseUrl$goldRates';
  static String get silverRatesUrl => '$baseUrl$silverRates';
  static String get addCustomerUrl => '$baseUrl$addCustomer';
  static String get existingCustomerUrl => '$baseUrl$existingCustomer';
  static String get refreshAuthUrl => '$baseUrl$refreshAuth';

  static String get suppliersUrl => '$baseUrl$suppliers';
  static String get supplierExistingUrl => '$baseUrl$supplierExisting';
  static String get supplierPaymentUrl => '$baseUrl$supplierPayment';
  static String get supplierTransactionsUrl => '$baseUrl$supplierTransactions';
  static String get ownerWorkersUrl => '$baseUrl/owner/workers';
}
