import '../../../../shared/widgets/placeholder_screen.dart';

class SpotDetailScreen extends PlaceholderScreen {
  // Runtime route parameters are rendered in the placeholder copy until the real detail UI exists.
  // ignore: prefer_const_constructors_in_immutables
  SpotDetailScreen({
    required String spotId,
    super.key,
  }) : super(
          title: 'Spot Detail',
          description:
              'Tourist spot detail and visit verification for #$spotId.',
        );
}
