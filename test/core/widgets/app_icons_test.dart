import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/core/widgets/app_icons.dart';
import 'package:khaata_digital/features/categories/domain/category_kind.dart';
import 'package:khaata_digital/features/categories/domain/category_seeds.dart';

void main() {
  test('every seeded category icon key resolves to a real icon', () {
    for (final seed in CategorySeeds.all) {
      expect(AppIcons.byKey, contains(seed.icon), reason: seed.name);
    }
  });

  test('categories of the same kind never share an icon', () {
    for (final kind in CategoryKind.values) {
      final icons = [
        for (final s in CategorySeeds.all.where((s) => s.kind == kind))
          AppIcons.of(s.icon).regular,
      ];
      expect(icons.toSet(), hasLength(icons.length), reason: kind.name);
    }
  });

  test('unknown keys fall back instead of crashing', () {
    expect(AppIcons.of('nope'), AppIcons.fallback);
    expect(AppIcons.of(null), AppIcons.fallback);
  });
}
