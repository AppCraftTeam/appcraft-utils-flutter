/// Mixin for objects that have a unique identifier [id].
mixin ACIdMixin {
  /// The unique identifier of the object.
  String get id;
}

/// Extension for a list of objects with the [ACIdMixin] mixin.
///
/// Makes it convenient to work with elements by their identifier.
extension ACIdMixinListExt<T extends ACIdMixin> on List<T> {
  /// Replaces the element in the list if an element with the same id already
  /// exists.
  ///
  /// If there is no element with that id, adds the new element to the list.
  void setElementByID(T newElement) {
    final indexOfElement = indexWhere((e) => e.id == newElement.id);

    if (indexOfElement >= 0) {
      this[indexOfElement] = newElement;
    } else {
      add(newElement);
    }
  }

  /// Returns a new list with the element replaced or added by id.
  ///
  /// The original list is not modified.
  List<T> settedElementByID(T newElement) =>
      List.of(this)..setElementByID(newElement);

  /// Removes the elements whose id is contained in the given set [ids].
  void removeElementByIDs(Set<String> ids) =>
      removeWhere((e) => ids.contains(e.id));

  /// Returns a new list with the elements removed by id.
  ///
  /// The original list is not modified.
  List<T> removedElementByIDs(Set<String> ids) =>
      List.of(this)..removeElementByIDs(ids);
}
