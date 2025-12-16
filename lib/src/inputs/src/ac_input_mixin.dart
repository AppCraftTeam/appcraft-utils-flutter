mixin ACInputMixin {
  bool get isValid;
  bool get isNotValid => !isValid;
}

extension ACInputMixinListExt on List<ACInputMixin> {

  bool get isValid => every((e) => e.isValid);

  bool get isNotValid => !isValid;

}