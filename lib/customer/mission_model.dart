import '../order_model.dart';

/// Status of a customer mission.
///
/// The naming follows the status conventions already used on the driver side
/// (`Accepted`, `In Progress`, `Completed`) and adds the customer-side states
/// (`Pending`, `Searching for driver`, `Cancelled`).
enum MissionStatus {
  pending,
  searching,
  accepted,
  inProgress,
  completed,
  cancelled,
}

/// Information about the driver assigned to a mission.
///
/// This is intentionally optional: the project has no driver data layer yet,
/// so a mission only carries driver information once one has been assigned.
/// The UI renders this section whenever it is present.
class DriverInfo {
  final String id;
  final String name;
  final String phone;
  final double? rating;
  final String? vehicle;
  final String? image;

  const DriverInfo({
    this.id = '',
    required this.name,
    required this.phone,
    this.rating,
    this.vehicle,
    this.image,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'rating': rating,
    'vehicle': vehicle,
    'image': image,
  };

  factory DriverInfo.fromJson(Map<String, dynamic> j) => DriverInfo(
    id: j['id'] as String? ?? '',
    name: j['name'] as String? ?? '',
    phone: j['phone'] as String? ?? '',
    rating: (j['rating'] as num?)?.toDouble(),
    vehicle: j['vehicle'] as String?,
    image: j['image'] as String?,
  );
}

/// A mission created by the customer.
///
/// Wraps the existing [OrderData] model (reusing every field it already has)
/// and adds the customer-side status, creation timestamp and optional driver.
class CustomerMission {
  final String id;
  final OrderData order;
  final MissionStatus status;
  final DateTime createdAt;
  final DriverInfo? driver;
  final bool negotiable;

  const CustomerMission({
    required this.id,
    required this.order,
    required this.status,
    required this.createdAt,
    this.driver,
    this.negotiable = false,
  });

  /// Builds a mission from a freshly confirmed order.
  ///
  /// The initial status is [MissionStatus.pending] — the mission has been
  /// created and is waiting for a driver.
  factory CustomerMission.fromOrder(
    OrderData order, {
    String? id,
    DateTime? createdAt,
  }) {
    return CustomerMission(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      order: order,
      status: MissionStatus.pending,
      createdAt: createdAt ?? DateTime.now(),
      negotiable: order.negotiable,
    );
  }

  CustomerMission copyWith({
    MissionStatus? status,
    DriverInfo? driver,
    bool? negotiable,
  }) {
    return CustomerMission(
      id: id,
      order: order,
      status: status ?? this.status,
      createdAt: createdAt,
      driver: driver ?? this.driver,
      negotiable: negotiable ?? this.negotiable,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'status': status.index,
    'createdAt': createdAt.toIso8601String(),
    'driver': driver?.toJson(),
    'negotiable': negotiable,
    'order': _orderToJson(order),
  };

  factory CustomerMission.fromJson(Map<String, dynamic> j) {
    return CustomerMission(
      id: j['id'] as String,
      order: _orderFromJson(j['order'] as Map<String, dynamic>),
      status: MissionStatus.values[j['status'] as int],
      createdAt: DateTime.parse(j['createdAt'] as String),
      driver: j['driver'] != null
          ? DriverInfo.fromJson(j['driver'] as Map<String, dynamic>)
          : null,
      negotiable: j['negotiable'] as bool? ?? false,
    );
  }

  static Map<String, dynamic> _orderToJson(OrderData o) => {
    'category': o.category,
    'shipmentType': o.shipmentType,
    'truckType': o.truckType,
    'truckModel': o.truckModel,
    'bodyType': o.bodyType,
    'weight': o.weight,
    'length': o.length,
    'width': o.width,
    'pickup': o.pickup,
    'delivery': o.delivery,
    'pickupCoords': o.pickupCoords,
    'deliveryCoords': o.deliveryCoords,
    'distance': o.distance,
    'isNow': o.isNow,
    'manualDate': o.manualDate,
    'manualTime': o.manualTime,
    'commodity': o.commodity,
    'helpers': o.helpers,
    'phoneNumber': o.phoneNumber,
    'confirmationMethod': o.confirmationMethod,
    'estimatedPrice': o.estimatedPrice,
  };

  static OrderData _orderFromJson(Map<String, dynamic> j) {
    return OrderData(
      category: j['category'] as String? ?? '',
      shipmentType: j['shipmentType'] as String? ?? '',
      truckType: j['truckType'] as String? ?? '',
      truckModel: j['truckModel'] as String? ?? '',
      bodyType: j['bodyType'] as String? ?? '',
      weight: j['weight'] as String? ?? '',
      length: j['length'] as String? ?? '',
      width: j['width'] as String? ?? '',
      pickup: j['pickup'] as String? ?? '',
      delivery: j['delivery'] as String? ?? '',
      pickupCoords: j['pickupCoords'] is Map
          ? (j['pickupCoords'] as Map).map(
              (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
            )
          : null,
      deliveryCoords: j['deliveryCoords'] is Map
          ? (j['deliveryCoords'] as Map).map(
              (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
            )
          : null,
      distance: j['distance'] as String?,
      isNow: j['isNow'] as bool? ?? true,
      manualDate: j['manualDate'] as String? ?? '',
      manualTime: j['manualTime'] as String? ?? '',
      commodity: j['commodity'] as String? ?? '',
      helpers: j['helpers'] as int? ?? 0,
      phoneNumber: j['phoneNumber'] as String? ?? '',
      confirmationMethod: j['confirmationMethod'] as String? ?? '',
      estimatedPrice: j['estimatedPrice'] as String? ?? '',
    );
  }
}
