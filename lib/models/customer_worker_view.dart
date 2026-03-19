class CustomerWorkerView {
  final String id;
  final String name;
  final String category;
  final double rating;
  final int price;
  final bool hasOffer;
  final bool isFeatured;
  final bool isFavorite;
  final double distanceKm;
  final int travelMinutes;
  final double travelFee;

  CustomerWorkerView({
    required this.id,
    required this.name,
    required this.category,
    required this.rating,
    required this.price,
    required this.hasOffer,
    required this.isFeatured,
    required this.isFavorite,
    required this.distanceKm,
    required this.travelMinutes,
    required this.travelFee,
  });
}
