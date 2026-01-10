class Shipment {
  final String? id;
  final String trackingNumber;
  final String origin;
  final String destination;
  final String status;
  final DateTime? eta;
  final String? driverName;
  final String? driverId;
  final double? weight;
  final Map<String, double>? dimensions;
  final double? price;
  final String? customerId;
  final String? category;
  final String? priority;
  final double? progress;
  final String? notes;

  Shipment({
    this.id,
    required this.trackingNumber,
    required this.origin,
    required this.destination,
    this.status = 'Pending',
    this.eta,
    this.driverName,
    this.driverId,
    this.weight,
    this.dimensions,
    this.price,
    this.customerId,
    this.category,
    this.priority,
    this.progress,
    this.notes,
  });

  factory Shipment.fromJson(Map<String, dynamic> json) {
    return Shipment(
      id: json['_id']?.toString(),
      trackingNumber: json['trackingNumber'] ?? '',
      origin: json['origin'] ?? '',
      destination: json['destination'] ?? '',
      status: json['status'] ?? 'Pending',
      eta: json['eta'] != null ? DateTime.parse(json['eta']) : null,
      driverName: json['driverName'],
      driverId: json['driverId']?.toString(),
      weight: json['weight']?.toDouble(),
      dimensions: json['dimensions'] != null 
          ? Map<String, double>.from(json['dimensions'])
          : null,
      price: json['price']?.toDouble(),
      customerId: json['customerId']?.toString(),
      category: json['category'],
      priority: json['priority'],
      progress: json['progress']?.toDouble(),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'trackingNumber': trackingNumber,
      'origin': origin,
      'destination': destination,
      'status': status,
      'eta': eta?.toIso8601String(),
      'driverName': driverName,
      'driverId': driverId,
      'weight': weight,
      'dimensions': dimensions,
      'price': price,
      'customerId': customerId,
      'category': category,
      'priority': priority,
      'progress': progress,
      'notes': notes,
    };
  }
}
