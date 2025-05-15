import 'package:shared_preferences/shared_preferences.dart';

class UserSharedPref {
  static Future<Map<String, String>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString('name') ?? '',
      'email': prefs.getString('email') ?? '',
      'classDiv': prefs.getString('classDiv') ?? '',
      'rollNo': prefs.getString('rollNo') ?? '',
    };
  }
}
