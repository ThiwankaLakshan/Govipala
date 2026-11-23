class ReviewModel {
  final String id;
  final String bookingId;
  final String reviewerId;
  final String? reviewerName;
  final String revieweeId;
  final String? machineId;
  final int rating; // 1 to 5
  final String? comment;
  final bool isHidden;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.bookingId,
    required this.reviewerId,
    this.reviewerName,
    required this.revieweeId,
    this.machineId,
    required this.rating,
    this.comment,
    this.isHidden = false,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as String? ?? '',
      bookingId: json['booking_id'] as String? ?? '',
      reviewerId: json['reviewer_id'] as String? ?? '',
      reviewerName: json['reviewer_name'] as String?,
      revieweeId: json['reviewee_id'] as String? ?? '',
      machineId: json['machine_id'] as String?,
      rating: json['rating'] as int? ?? 5,
      comment: json['comment'] as String?,
      isHidden: json['is_hidden'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'reviewer_id': reviewerId,
      'reviewer_name': reviewerName,
      'reviewee_id': revieweeId,
      'machine_id': machineId,
      'rating': rating,
      'comment': comment,
      'is_hidden': isHidden,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class ReviewsListResponse {
  final double averageRating;
  final int reviewCount;
  final List<ReviewModel> reviews;

  const ReviewsListResponse({
    required this.averageRating,
    required this.reviewCount,
    required this.reviews,
  });

  factory ReviewsListResponse.fromJson(Map<String, dynamic> json) {
    final rawReviews = json['reviews'] as List<dynamic>? ?? [];
    return ReviewsListResponse(
      averageRating: json['average_rating'] != null ? (json['average_rating'] as num).toDouble() : 0.0,
      reviewCount: json['review_count'] as int? ?? rawReviews.length,
      reviews: rawReviews.map((r) => ReviewModel.fromJson(r as Map<String, dynamic>)).toList(),
    );
  }
}
