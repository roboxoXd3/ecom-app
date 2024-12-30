class OnboardingModel {
  final String title;
  final String description;
  final String image;

  OnboardingModel({
    required this.title,
    required this.description,
    this.image = '',
  });
}

final List<OnboardingModel> onboardingData = [
  OnboardingModel(
    title: 'Discover Latest Trends',
    description:
        'Find the perfect piece to add to your wardrobe from our vast collection of modern clothes.',
  ),
  OnboardingModel(
    title: 'Easy & Secure Checkout',
    description:
        'Multiple payment options and secure checkout process for worry-free shopping.',
  ),
  OnboardingModel(
    title: 'Fast Delivery',
    description:
        'Get your favorite items delivered right to your doorstep with our express delivery service.',
  ),
];
