class Worker {
  final String id;
  final String name;
  final String category;

  final double rating;
  final int ratingCount;
  final int completedJobsCount;

  final double distanceKm;
  final int travelMinutes;
  final double travelFee;

  final bool hasOffer;
  final String offerType;
  final String offerDetails;

  final bool isFeatured;
  final String featuredWeekKey;

  final bool isFavorite;

  final String profilePhotoUrl;
  final String address;

  final double? lat;
  final double? lng;

  const Worker({
    required this.id,
    required this.name,
    required this.category,
    required this.rating,
    required this.ratingCount,
    required this.completedJobsCount,
    required this.distanceKm,
    required this.travelMinutes,
    required this.travelFee,
    required this.hasOffer,
    required this.offerType,
    required this.isFeatured,
    required this.featuredWeekKey,
    required this.isFavorite,
    required this.profilePhotoUrl,
    required this.address,
    required this.offerDetails,
    this.lat,
    this.lng,
  });
}