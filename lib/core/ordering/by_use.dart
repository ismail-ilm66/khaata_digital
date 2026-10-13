/// [items] with the most-used first, by their place in [usedIds] (most
/// used first). Items never used keep their current order, after the rest.
List<T> sortByUse<T>(
  List<T> items,
  String Function(T) id,
  List<String> usedIds,
) {
  final rank = {for (final (i, x) in usedIds.indexed) x: i};
  final unused = usedIds.length;
  // List.sort isn't stable; break ties on the original position.
  final indexed = [...items.indexed]
    ..sort((a, b) {
      final byRank = (rank[id(a.$2)] ?? unused).compareTo(
        rank[id(b.$2)] ?? unused,
      );
      return byRank != 0 ? byRank : a.$1.compareTo(b.$1);
    });
  return [for (final (_, item) in indexed) item];
}
