import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/strings.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _keyLang = 'settings_lang';
  static const String _keyBizName = 'settings_biz_name';
  static const String _keyBizGstin = 'settings_biz_gstin';
  static const String _keyBizAddress = 'settings_biz_address';
  static const String _keyBizPhone = 'settings_biz_phone';
  static const String _keyBackendUrl = 'settings_backend_url';
  static const String _keyApiKey = 'settings_api_key';

  final SharedPreferences _prefs;

  String _language = 'en';
  String _businessName = 'OM TRADERS & WHOLESALE';
  String _businessGstin = '27ABCDE1234F1Z5';
  String _businessAddress = 'Plot 42, Sector 19, APMC Wholesale Market, Navi Mumbai - 400705';
  String _businessPhone = '+91 98765 43210';
  String _backendUrl = 'https://us-central1-ledgr-ai.cloudfunctions.net/parseVoucher';
  String _geminiApiKey = '';

  SettingsProvider(this._prefs) {
    _loadSettings();
  }

  String get language => _language;
  bool get isHindi => _language == 'hi';
  String get businessName => _businessName;
  String get businessGstin => _businessGstin;
  String get businessStateCode => _businessGstin.length >= 2 ? _businessGstin.substring(0, 2) : '27';
  String get businessAddress => _businessAddress;
  String get businessPhone => _businessPhone;
  String get backendUrl => _backendUrl;
  String get geminiApiKey => _geminiApiKey;

  void _loadSettings() {
    _language = _prefs.getString(_keyLang) ?? 'en';
    AppStrings.isHindi = (_language == 'hi');
    _businessName = _prefs.getString(_keyBizName) ?? _businessName;
    _businessGstin = _prefs.getString(_keyBizGstin) ?? _businessGstin;
    _businessAddress = _prefs.getString(_keyBizAddress) ?? _businessAddress;
    _businessPhone = _prefs.getString(_keyBizPhone) ?? _businessPhone;
    _backendUrl = _prefs.getString(_keyBackendUrl) ?? _backendUrl;
    _geminiApiKey = _prefs.getString(_keyApiKey) ?? '';
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    _language = lang;
    AppStrings.isHindi = (lang == 'hi');
    await _prefs.setString(_keyLang, lang);
    notifyListeners();
  }

  Future<void> updateBusinessDetails({
    required String name,
    required String gstin,
    required String address,
    required String phone,
  }) async {
    _businessName = name;
    _businessGstin = gstin;
    _businessAddress = address;
    _businessPhone = phone;
    await _prefs.setString(_keyBizName, name);
    await _prefs.setString(_keyBizGstin, gstin);
    await _prefs.setString(_keyBizAddress, address);
    await _prefs.setString(_keyBizPhone, phone);
    notifyListeners();
  }

  Future<void> updateBackendSettings({
    required String backendUrl,
    required String apiKey,
  }) async {
    _backendUrl = backendUrl;
    _geminiApiKey = apiKey;
    await _prefs.setString(_keyBackendUrl, backendUrl);
    await _prefs.setString(_keyApiKey, apiKey);
    notifyListeners();
  }
}
