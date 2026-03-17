class Worker {
  final String id;
  final String name;
  final String category;
  final double rating;
  final int price;
  final int? oldPrice;
  final double distanceKm;
  final int travelMinutes;
  final double travelFee;
  final bool hasOffer;
  final bool isFeatured;
  final bool isFavorite;
  final String profilePhotoUrl;
  final String address;

  const Worker({
    required this.id,
    required this.name,
    required this.category,
    required this.rating,
    required this.price,
    this.oldPrice,
    required this.distanceKm,
    required this.travelMinutes,
    required this.travelFee,
    required this.hasOffer,
    required this.isFeatured,
    required this.isFavorite,
    required this.profilePhotoUrl,
    required this.address,
  });
}
