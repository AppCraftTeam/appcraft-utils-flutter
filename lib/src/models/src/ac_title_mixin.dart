/// Mixin for objects that have a title [title].
mixin ACTitleMixin {
  /// The title of the object.
  String get title;
}

/// Wrapper class for storing a title.
///
/// Uses the [ACTitleMixin] mixin for compatibility with the extensions.
class ACTitle with ACTitleMixin {
  /// Creates a wrapper with the required title [title].
  const ACTitle({required this.title});

  /// The title field.
  final String title;
}

/// Extension for a list of objects with the [ACTitleMixin] mixin.
///
/// Allows performing title-related operations.
extension TitleMixinListExt<T extends ACTitleMixin> on List<T> {
  /// Returns a new list sorted alphabetically by title.
  ///
  /// The original list is not modified.
  List<T> sortedByTitle() =>
      List.of(this)..sort((a, b) => a.title.compareTo(b.title));
}
