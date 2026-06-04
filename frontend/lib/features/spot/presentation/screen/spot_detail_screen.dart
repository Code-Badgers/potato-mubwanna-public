import '../../../../shared/widgets/placeholder_screen.dart';

class SpotDetailScreen extends PlaceholderScreen {
  SpotDetailScreen({
    required String spotId,
    super.key,
  }) : super(
          title: 'Spot Detail',
          description: 'Tourist spot detail and visit verification for #$spotId.',
        );
}

