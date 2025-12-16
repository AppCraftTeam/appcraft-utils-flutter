mixin ACIdMixin {
  String get id;
}

extension ACIdMixinListExt<T extends ACIdMixin> on List<T> {

  void setElementByID(T newElement) {
    final indexOfElement = indexWhere((e) => e.id == newElement.id);

    if (indexOfElement >= 0) {
      this[indexOfElement] = newElement;
    } else {
      add(newElement);
    }
  }

  List<T> settedElementByID(T newElement) =>
    List.of(this)
      ..setElementByID(newElement);

  void removeElementByIDs(Set<String> ids) =>
    removeWhere((e) => ids.contains(e.id));

  List<T> removedElementByIDs(Set<String> ids) =>
    List.of(this)
      ..removeElementByIDs(ids);

}
