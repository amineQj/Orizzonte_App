import '../models/api_models.dart' as api_models;
import 'api_service.dart';

/// Local view model kept for the existing boss pricing screen.
class PricingConfig {
  final int version;
  final bool calibrated;
  final Map<String, dynamic> parameters;

  const PricingConfig({
    required this.version,
    required this.calibrated,
    required this.parameters,
  });

  factory PricingConfig.fromApi(api_models.PricingConfig config) => PricingConfig(
        version: config.version,
        calibrated: config.calibrated,
        parameters: config.parameters,
      );
}

class PricingServiceException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;

  const PricingServiceException(this.message, {this.statusCode, this.code});

  @override
  String toString() => message;
}

/// Thin adapter over [ApiService].
///
/// Previously this service opened its own `http.Client` and repeated the base
/// URL/token logic. Routing through [ApiService] gives it the same base URL,
/// 401 refresh handler and error contract as every other backend call.
class PricingService {
  PricingService({ApiService? api})
      : _api = api ?? ApiService();

  final ApiService _api;

  Future<PricingConfig> getPricingConfig() async {
    try {
      return PricingConfig.fromApi(await _api.getPricingConfig());
    } on api_models.ApiException catch (e) {
      throw PricingServiceException(e.message,
          statusCode: e.statusCode, code: e.code);
    }
  }

  Future<PricingConfig> updatePricingConfig({
    required Map<String, dynamic> parameters,
    required String password,
  }) async {
    try {
      return PricingConfig.fromApi(
        await _api.updatePricingConfig(parameters, password),
      );
    } on api_models.ApiException catch (e) {
      throw PricingServiceException(e.message,
          statusCode: e.statusCode, code: e.code);
    }
  }

  void dispose() => _api.dispose();
}
