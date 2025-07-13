import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'paginated_response.g.dart';

/// Paginated response model for handling large datasets
/// with pagination metadata and type-safe data handling.
@JsonSerializable(genericArgumentFactories: true)
class PaginatedResponse<T> extends Equatable {
  /// List of items for current page
  final List<T> items;

  /// Current page number
  final int page;

  /// Number of items per page
  final int limit;

  /// Total number of items
  final int total;

  /// Total number of pages
  final int totalPages;

  /// Whether there are more pages
  final bool hasMore;

  /// Creates paginated response
  const PaginatedResponse({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasMore,
  });

  /// Factory constructor from JSON
  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) =>
      _$PaginatedResponseFromJson(json, fromJsonT);

  /// Converts to JSON
  Map<String, dynamic> toJson(Object Function(T value) toJsonT) =>
      _$PaginatedResponseToJson(this, toJsonT);

  @override
  List<Object?> get props => [items, page, limit, total, totalPages, hasMore];
}
