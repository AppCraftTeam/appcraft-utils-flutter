import '../../exceptions/src/ac_exception.dart';

abstract class ACValidation<V, E> {
  const ACValidation();

  E? validate(V? value); 
}

extension ACValidationListExt<V, E> on List<ACValidation<V, E>> {

  E? validate(V? value) {
    E? result;

    for (final validation in this) {
      result = validation.validate(value);
      if (result != null) break;
    }

    return result;
  }

}

class ACRequiredValidation extends ACValidation<String, Exception> {
  const ACRequiredValidation();

  @override
  Exception? validate(String? value) =>
    (value ?? '').isEmpty ?
      const RequiredFieldException() :
      null;

}

class ACMinLengthValidation extends ACValidation<String, Exception> {
  const ACMinLengthValidation(this.minLength);

  final int minLength;

  @override
  Exception? validate(String? value) =>
    (value ?? '').length < minLength ?
      MinLengthException(minLength) :
      null;

}

class ACMaxLengthValidation extends ACValidation<String, Exception> {
  const ACMaxLengthValidation(this.maxLength);

  final int maxLength;

  @override
  Exception? validate(String? value) =>
    (value ?? '').length > maxLength ?
      MaxLengthException(maxLength) :
      null;

}

abstract class ACRegExpValidation<E> extends ACValidation<String, E> {
  const ACRegExpValidation();

  RegExp get regExp;

  E get error;
  
  @override
  E? validate(String? value) =>
    !regExp.hasMatch(value ?? '') ? error : null;
}

final emailValidRegExp = RegExp(r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$');

class ACEmailValidation extends ACRegExpValidation<Exception> {
  const ACEmailValidation();

  @override
  RegExp get regExp => emailValidRegExp;

  @override
  Exception get error => const WrongEmailException();

}