// ignore_for_file: avoid_print
import 'package:appcraft_utils_flutter/appcraft_utils_flutter.dart';

enum Priority { low, medium, high }

void main() {
  print('=== ACEmail validation ===');
  const valid = ACEmail(value: 'user@example.com', isPure: false);
  const invalid = ACEmail(value: 'not-an-email', isPure: false);
  print('valid email "${valid.value}": isValid=${valid.isValid}, error=${valid.displayError?.runtimeType ?? 'none'}');
  print('invalid email "${invalid.value}": isValid=${invalid.isValid}, error=${invalid.displayError?.runtimeType ?? 'none'}');

  print('');
  print('=== ACText (min length 3) ===');
  const tooShort = ACText(value: 'hi', isPure: false, minLength: 3);
  const longEnough = ACText(value: 'hello', isPure: false, minLength: 3);
  print('"${tooShort.value}": isValid=${tooShort.isValid}, error=${tooShort.displayError?.runtimeType ?? 'none'}');
  print('"${longEnough.value}": isValid=${longEnough.isValid}, error=${longEnough.displayError?.runtimeType ?? 'none'}');

  print('');
  print('=== ACEnumByNameOrNull ===');
  final found = Priority.values.byNameOrNull('high');
  final missing = Priority.values.byNameOrNull('unknown');
  print('byNameOrNull("high")    = $found');
  print('byNameOrNull("unknown") = $missing');
}
