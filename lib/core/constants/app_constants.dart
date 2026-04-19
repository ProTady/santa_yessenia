import 'package:flutter/material.dart';

class AppConstants {
  // Hive boxes
  static const String settingsBox = 'settings';
  static const String personalBox = 'personal';
  static const String ingredientesBox = 'ingredientes';
  static const String suministrosBox = 'suministros';
  static const String transporteBox = 'transporte';
  static const String ingresosBox = 'ingresos';
  static const String comensalesBox = 'comensales';
  static const String directorioBox   = 'directorio';
  static const String asistenciasBox  = 'asistencias';
  static const String usuariosBox     = 'usuarios';
  static const String ventasBox       = 'ventas';

  // Módulos disponibles para asignar permisos
  static const Map<String, String> modulosDisponibles = {
    '/personal':    'Personal',
    '/ingredientes':'Ingredientes',
    '/suministros': 'Suministros',
    '/transporte':  'Transporte',
    '/ingresos':    'Ingresos',
    '/comensales':  'Comensales',
    '/directorio':  'Directorio',
    '/asistencias': 'Asistencias',
    '/ventas':      'Ventas',
  };

  // Settings keys
  static const String pinKey = 'pin';
  static const String defaultPin = '1234';

  // Colors
  static const Color primaryGreen = Color(0xFF1B5E20);
  static const Color primaryGreenMid = Color(0xFF2E7D32);
  static const Color primaryGreenLight = Color(0xFF4CAF50);
  static const Color accentAmber = Color(0xFFFFB300);
  static const Color backgroundGray = Color(0xFFF0F4F0);
  static const Color errorRed = Color(0xFFC62828);
  static const Color incomeColor = Color(0xFF2E7D32);
  static const Color expenseColor = Color(0xFFC62828);
  static const Color asistenciaColor = Color(0xFF283593); // indigo

  // App info
  static const String appName = 'Santa Yessenia';
  static const String appSubtitle = 'Servicio de Alimentación';

  // Currency / locale
  static const String currencySymbol = 'S/.';
  static const String localeCode = 'es_PE';
}
