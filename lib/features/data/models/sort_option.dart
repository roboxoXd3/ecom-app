enum SortOption {
  priceLowToHigh,
  priceHighToLow,
  newest,
  popularity,
  rating,
  bestSelling,
}

extension SortOptionExtension on SortOption {
  String get displayName {
    switch (this) {
      case SortOption.priceLowToHigh:
        return 'Price: Low to High';
      case SortOption.priceHighToLow:
        return 'Price: High to Low';
      case SortOption.newest:
        return 'Newest First';
      case SortOption.popularity:
        return 'Most Popular';
      case SortOption.rating:
        return 'Highest Rated';
      case SortOption.bestSelling:
        return 'Best Selling';
    }
  }
}
