
class ApiConfig {
ApiConfig._();

static const String baseUrl =
'https://jaiwer-backend.onrender.com';

static const String goldRates = '/market-rates/gold';
static const String silverRates = '/market-rates/silver';
static const String addCustomer = '/add-customer';
static const String existingCustomer = '/existing-customer';

static String get goldRatesUrl => '$baseUrl$goldRates';
static String get silverRatesUrl => '$baseUrl$silverRates';
static String get addCustomerUrl => '$baseUrl$addCustomer';
static String get existingCustomerUrl =>
'$baseUrl$existingCustomer';
}
