mixin ACTitleMixin {
  String get title;
}

class ACTitle with ACTitleMixin {
  const ACTitle({
    required this.title
  });

  final String title;
}

extension TitleMixinListExt<T extends ACTitleMixin> on List<T> {

  List<T> sortedByTitle() =>
    List
      .of(this)
      ..sort((a, b) => a.title.compareTo(b.title));

}