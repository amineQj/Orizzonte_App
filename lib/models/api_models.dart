// Typed models for the ORIZZONTE backend API.
//
// DRF `DecimalField` values arrive as JSON strings (e.g. "67500.00"), while
// engine amounts (estimate.amount, offer.amount, commission_amount, ...)
// arrive as JSON integers. Every parser below tolerates both forms.

num? _asNum(dynamic v) {
  if (v == null) return null;
  if (v is num) return v;
  if (v is String) return num.tryParse(v);
  return null;
}

double _d(dynamic v) => _asNum(v)?.toDouble() ?? 0.0;
int _i(dynamic v) => _asNum(v)?.toInt() ?? 0;
int? _iOrNull(dynamic v) => _asNum(v)?.toInt();

String _s(dynamic v) => v?.toString() ?? '';

/// Human-readable addresses are optional backend fields. Older payloads only
/// carry coordinates, so callers fall back to neutral labels.
String _firstAddress(dynamic json, List<String> keys) {
  for (final key in keys) {
    final value = _s(json[key]).trim();
    if (value.isNotEmpty) return value;
  }
  return '';
}

class ApiUser {
  final int id;
  final String username;
  final String email;
  final String role;
  final bool emailVerified;

  const ApiUser({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.emailVerified = false,
  });

  factory ApiUser.fromJson(Map<String, dynamic> json) => ApiUser(
        id: _i(json['id']),
        username: _s(json['username']),
        email: _s(json['email']),
        role: _s(json['role']).isEmpty ? 'client' : _s(json['role']),
        emailVerified: json['email_verified'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'role': role,
        'email_verified': emailVerified,
      };
}

class AuthResponse {
  final ApiUser user;
  final String accessToken;
  final String refreshToken;

  const AuthResponse({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] is Map
        ? (json['user'] as Map).cast<String, dynamic>()
        : json;
    return AuthResponse(
      user: ApiUser.fromJson(userJson),
      accessToken: _s(json['access']),
      refreshToken: _s(json['refresh']),
    );
  }
}

/// A mission as returned by the backend (client / driver / boss serializers).
/// Numeric fields are stored as doubles/ints regardless of their wire format.
class Mission {
  final int id;
  final String shipmentType;
  final String phoneNumber;
  final String truckType;
  final String category;
  final int capacity;
  final String size;
  final double departureLat;
  final double departureLon;
  final double arrivalLat;
  final double arrivalLon;
  final String pickupAddress;
  final String dropoffAddress;
  final double distance;
  final String date;
  final String time;
  final int workers;
  final double price;
  final bool negotiable;
  final String status;
  final DateTime? createdAt;

  // Driver-list fields (available/ & my/)
  final String displayStatus;
  final bool isTaken;
  final String? takenBy;
  final int? driverNet;
  final String? commissionRate;

  // Boss-list fields (all/)
  final Map<String, dynamic>? client;
  final Map<String, dynamic>? assignedEmployee;

  const Mission({
    required this.id,
    required this.shipmentType,
    required this.phoneNumber,
    required this.truckType,
    required this.category,
    required this.capacity,
    required this.size,
    required this.departureLat,
    required this.departureLon,
    required this.arrivalLat,
    required this.arrivalLon,
    this.pickupAddress = '',
    this.dropoffAddress = '',
    required this.distance,
    required this.date,
    required this.time,
    required this.workers,
    required this.price,
    this.negotiable = false,
    this.status = 'pending',
    this.createdAt,
    this.displayStatus = '',
    this.isTaken = false,
    this.takenBy,
    this.driverNet,
    this.commissionRate,
    this.client,
    this.assignedEmployee,
  });

  factory Mission.fromJson(Map<String, dynamic> json) {
    final client = json['client'] is Map
        ? (json['client'] as Map).cast<String, dynamic>()
        : null;
    final employee = json['assigned_employee'] is Map
        ? (json['assigned_employee'] as Map).cast<String, dynamic>()
        : null;
    return Mission(
      id: _i(json['id']),
      shipmentType: _s(json['shipment_type']),
      phoneNumber: _s(json['phone_number']),
      truckType: _s(json['truck_type']),
      category: _s(json['category']),
      capacity: _i(json['capacity']),
      size: _s(json['size']),
      departureLat: _d(json['departure_latitude']),
      departureLon: _d(json['departure_longitude']),
      arrivalLat: _d(json['arrival_latitude']),
      arrivalLon: _d(json['arrival_longitude']),
      pickupAddress: _firstAddress(json, const [
        'pickup_address',
        'departure_address',
        'origin_address',
        'pickup_location',
      ]),
      dropoffAddress: _firstAddress(json, const [
        'dropoff_address',
        'arrival_address',
        'destination_address',
        'dropoff_location',
      ]),
      distance: _d(json['distance']),
      date: _s(json['date']),
      time: _s(json['time']),
      workers: _i(json['workers']),
      price: _d(json['price']),
      negotiable: json['negotiable'] as bool? ?? false,
      status: _s(json['status']).isEmpty ? 'pending' : _s(json['status']),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(_s(json['created_at']))
          : null,
      displayStatus: _s(json['display_status']),
      isTaken: json['is_taken'] as bool? ?? false,
      takenBy: json['taken_by'] != null ? _s(json['taken_by']) : null,
      driverNet: _iOrNull(json['driver_net']),
      commissionRate: json['commission_rate'] != null
          ? _s(json['commission_rate'])
          : null,
      client: client,
      assignedEmployee: employee,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'shipment_type': shipmentType,
        'phone_number': phoneNumber,
        'truck_type': truckType,
        'category': category,
        'capacity': capacity,
        'size': size,
        'departure_latitude': departureLat,
        'departure_longitude': departureLon,
        'arrival_latitude': arrivalLat,
        'arrival_longitude': arrivalLon,
        if (pickupAddress.isNotEmpty) 'pickup_address': pickupAddress,
        if (dropoffAddress.isNotEmpty) 'dropoff_address': dropoffAddress,
        'distance': distance,
        'date': date,
        'time': time,
        'workers': workers,
        'price': price,
        'negotiable': negotiable,
        'status': status,
      };
}

class Estimate {
  final int amount;
  final int low;
  final int high;
  final String currency;
  final String confidence;
  final bool calibrated;
  final int configVersion;
  final String? quoteId;
  final String? expiresAt;
  final Map<String, dynamic> components;
  final String? multiplier;
  final String? band;

  const Estimate({
    required this.amount,
    required this.low,
    required this.high,
    this.currency = 'DZD',
    this.confidence = 'normal',
    this.calibrated = false,
    this.configVersion = 1,
    this.quoteId,
    this.expiresAt,
    this.components = const {},
    this.multiplier,
    this.band,
  });

  factory Estimate.fromJson(Map<String, dynamic> json) => Estimate(
        amount: _i(json['amount']),
        low: _i(json['low']),
        high: _i(json['high']),
        currency: _s(json['currency']).isEmpty ? 'DZD' : _s(json['currency']),
        confidence: _s(json['confidence']).isEmpty ? 'normal' : _s(json['confidence']),
        calibrated: json['calibrated'] as bool? ?? false,
        configVersion: _i(json['config_version']),
        quoteId: json['quote_id'] != null ? _s(json['quote_id']) : null,
        expiresAt: json['expires_at'] != null ? _s(json['expires_at']) : null,
        components: (json['components'] as Map?)?.cast<String, dynamic>() ?? const {},
        multiplier: json['multiplier'] != null ? _s(json['multiplier']) : null,
        band: json['band'] != null ? _s(json['band']) : null,
      );

  bool get isLowConfidence => confidence == 'low';
}

/// Full response of POST /api/missions/estimate/.
class EstimateResult {
  final double estimatedPrice;
  final Map<String, dynamic> breakdown;
  final Estimate? estimate;

  const EstimateResult({
    required this.estimatedPrice,
    required this.breakdown,
    this.estimate,
  });

  factory EstimateResult.fromJson(Map<String, dynamic> json) => EstimateResult(
        estimatedPrice: _d(json['estimated_price']),
        breakdown: (json['breakdown'] as Map?)?.cast<String, dynamic>() ?? const {},
        estimate: json['estimate'] is Map
            ? Estimate.fromJson((json['estimate'] as Map).cast<String, dynamic>())
            : null,
      );

  /// Human-readable price range to show in the UI.
  String get rangeLabel {
    final e = estimate;
    if (e == null) {
      return estimatedPrice.round().toString();
    }
    return '${e.low} – ${e.high} DZD';
  }
}

class NegotiationOffer {
  final int id;
  final int sequence;
  final int amount;
  final String authorRole;
  final bool isFinal;
  final int? commissionAmount;
  final int? driverNet;
  final DateTime? createdAt;

  const NegotiationOffer({
    required this.id,
    required this.sequence,
    required this.amount,
    required this.authorRole,
    this.isFinal = false,
    this.commissionAmount,
    this.driverNet,
    this.createdAt,
  });

  factory NegotiationOffer.fromJson(Map<String, dynamic> json) =>
      NegotiationOffer(
        id: _i(json['id']),
        sequence: _i(json['sequence']),
        amount: _i(json['amount']),
        authorRole: _s(json['author_role']),
        isFinal: json['is_final'] as bool? ?? false,
        commissionAmount: _iOrNull(json['commission_amount']),
        driverNet: _iOrNull(json['driver_net']),
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(_s(json['created_at']))
            : null,
      );
}

class Negotiation {
  final int id;
  final int missionId;
  final String status;
  final String currency;
  final int initialPrice;
  final int? currentAmount;
  final int minAmount;
  final int maxAmount;
  final int minFare;
  final int maxOffers;
  final int minStep;
  final int offerCount;
  final bool isFinal;
  final bool yourTurn;
  final List<NegotiationOffer> offers;
  final bool calibrated;
  final int configVersion;
  final DateTime? expiresAt;
  final DateTime? holdExpiresAt;
  final int? acceptedAmount;
  final String? commissionRate;
  final int? commissionAmount;
  final int? driverNet;
  final DateTime? createdAt;
  final DateTime? acceptedAt;
  final DateTime? closedAt;

  const Negotiation({
    required this.id,
    required this.missionId,
    required this.status,
    this.currency = 'DZD',
    required this.initialPrice,
    this.currentAmount,
    required this.minAmount,
    required this.maxAmount,
    required this.minFare,
    required this.maxOffers,
    required this.minStep,
    this.offerCount = 0,
    this.isFinal = false,
    this.yourTurn = false,
    this.offers = const [],
    this.calibrated = false,
    this.configVersion = 1,
    this.expiresAt,
    this.holdExpiresAt,
    this.acceptedAmount,
    this.commissionRate,
    this.commissionAmount,
    this.driverNet,
    this.createdAt,
    this.acceptedAt,
    this.closedAt,
  });

  factory Negotiation.fromJson(Map<String, dynamic> json) => Negotiation(
        id: _i(json['id']),
        missionId: _i(json['mission_id']),
        status: _s(json['status']).isEmpty ? 'open' : _s(json['status']),
        currency: _s(json['currency']).isEmpty ? 'DZD' : _s(json['currency']),
        initialPrice: _i(json['initial_price']),
        currentAmount: _iOrNull(json['current_amount']),
        minAmount: _i(json['min_amount']),
        maxAmount: _i(json['max_amount']),
        minFare: _i(json['min_fare']),
        maxOffers: _i(json['max_offers']),
        minStep: _i(json['min_step']),
        offerCount: _i(json['offer_count']),
        isFinal: json['is_final'] as bool? ?? false,
        yourTurn: json['your_turn'] as bool? ?? false,
        offers: (json['offers'] as List?)
                ?.map((e) => NegotiationOffer.fromJson((e as Map).cast<String, dynamic>()))
                .toList() ??
            const [],
        calibrated: json['calibrated'] as bool? ?? false,
        configVersion: _i(json['config_version']),
        expiresAt: json['expires_at'] != null
            ? DateTime.tryParse(_s(json['expires_at']))
            : null,
        holdExpiresAt: json['hold_expires_at'] != null
            ? DateTime.tryParse(_s(json['hold_expires_at']))
            : null,
        acceptedAmount: _iOrNull(json['accepted_amount']),
        commissionRate: json['commission_rate'] != null
            ? _s(json['commission_rate'])
            : null,
        commissionAmount: _iOrNull(json['commission_amount']),
        driverNet: _iOrNull(json['driver_net']),
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(_s(json['created_at']))
            : null,
        acceptedAt: json['accepted_at'] != null
            ? DateTime.tryParse(_s(json['accepted_at']))
            : null,
        closedAt: json['closed_at'] != null
            ? DateTime.tryParse(_s(json['closed_at']))
            : null,
      );

  bool get isOpen => status == 'open';
  int get displayedAmount => currentAmount ?? initialPrice;
  int get offersLeft => (maxOffers - offerCount).clamp(0, maxOffers);
}

class PricingConfig {
  final int version;
  final bool calibrated;
  final Map<String, dynamic> parameters;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PricingConfig({
    required this.version,
    required this.calibrated,
    required this.parameters,
    this.createdAt,
    this.updatedAt,
  });

  factory PricingConfig.fromJson(Map<String, dynamic> json) => PricingConfig(
        version: _i(json['version']),
        calibrated: json['calibrated'] as bool? ?? false,
        parameters:
            (json['parameters'] as Map?)?.cast<String, dynamic>() ?? const {},
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(_s(json['created_at']))
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(_s(json['updated_at']))
            : null,
      );
}

/// Normalized driver profile used by the driver profile screen.
class DriverProfile {
  final Map<String, dynamic> raw;
  final int userId;
  final String fullName;
  final String phone;
  final String status;
  final String? rejectionReason;
  final Map<String, dynamic> documents;
  final Map<String, dynamic> missing;
  final int documentsVersion;
  final Map<String, dynamic> verificationResults;

  const DriverProfile({
    required this.raw,
    required this.userId,
    required this.fullName,
    required this.phone,
    required this.status,
    this.rejectionReason,
    this.documents = const {},
    this.missing = const {},
    this.documentsVersion = 0,
    this.verificationResults = const {},
  });

  factory DriverProfile.fromJson(Map<String, dynamic> json) => DriverProfile(
        raw: json,
        userId: _i(json['user_id']),
        fullName: _s(json['full_name']),
        phone: _s(json['phone']),
        status: _s(json['status']).isEmpty ? 'incomplete' : _s(json['status']),
        rejectionReason: json['rejection_reason'] != null
            ? _s(json['rejection_reason'])
            : null,
        documents: (json['documents'] as Map?)?.cast<String, dynamic>() ?? const {},
        missing: (json['missing'] as Map?)?.cast<String, dynamic>() ?? const {},
        documentsVersion: _i(json['documents_version']),
        verificationResults:
            (json['verification_results'] as Map?)?.cast<String, dynamic>() ??
                const {},
      );
}

/// A pending-driver row from GET /api/drivers/pending/.
class PendingDriver {
  final int userId;
  final String fullName;
  final String phone;
  final String profileStatus;
  final String vehiclePlate;
  final int documentsVersion;

  const PendingDriver({
    required this.userId,
    required this.fullName,
    required this.phone,
    required this.profileStatus,
    required this.vehiclePlate,
    required this.documentsVersion,
  });

  factory PendingDriver.fromJson(Map<String, dynamic> json) => PendingDriver(
        userId: _i(json['user_id']),
        fullName: _s(json['full_name']),
        phone: _s(json['phone']),
        profileStatus: _s(json['profile_status']),
        vehiclePlate: _s(json['vehicle_plate']),
        documentsVersion: _i(json['documents_version']),
      );
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;
  final Map<String, dynamic>? fieldErrors;

  const ApiException(this.message, {this.statusCode, this.code, this.fieldErrors});

  @override
  String toString() => message;
}

/// Pulls the most useful human message out of a backend error body / exception.
///
/// The backend's machine-readable `code` (for example `driver_not_approved`)
/// is appended so the user sees the exact reason, not a generic sentence.
String apiErrorMessage(dynamic error) {
  if (error is ApiException) {
    String message;
    final fe = error.fieldErrors;
    if (fe != null && fe.isNotEmpty) {
      final first = fe.values.first;
      if (first is List && first.isNotEmpty) {
        message = first.first.toString();
      } else {
        message = first.toString();
      }
    } else {
      message = error.message;
    }
    final code = error.code;
    if (code != null && code.isNotEmpty && !message.contains(code)) {
      message = '$message ($code)';
    }
    return message;
  }
  return error.toString().replaceFirst('Exception: ', '');
}
