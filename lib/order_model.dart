class OrderData {
  String category;
  String shipmentType;
  String truckType;
  String truckModel;
  String bodyType;
  String weight;
  String length;
  String width;

  String pickup;
  String delivery;
  Map<String, double>? pickupCoords;
  Map<String, double>? deliveryCoords;
  String? distance;
  bool isNow;
  String manualDate;
  String manualTime;

  String commodity;
  int helpers;
  String phoneNumber;
  String confirmationMethod;
  String estimatedPrice;

  /// Set by the estimate/confirm API calls in OrderConfirmationScreen.
  String? quoteId;
  int? backendMissionId;
  String? priceRange;
  bool negotiable = false;

  OrderData({
    this.category = '',
    this.shipmentType = '',
    this.truckType = '',
    this.truckModel = '',
    this.bodyType = '',
    this.weight = '',
    this.length = '',
    this.width = '',
    this.pickup = '',
    this.delivery = '',
    this.pickupCoords,
    this.deliveryCoords,
    this.distance,
    this.isNow = true,
    this.manualDate = '',
    this.manualTime = '',
    this.commodity = '',
    this.helpers = 0,
    this.phoneNumber = '',
    this.confirmationMethod = '',
    this.estimatedPrice = '',
    this.negotiable = false,
  });
}
