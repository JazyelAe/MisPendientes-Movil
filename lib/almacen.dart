// almacen.dart — Guarda las tareas y las preferencias en el teléfono con shared_preferences.
// En Android se guarda en las preferencias de la app; en la demo web, en el localStorage del navegador.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'modelo.dart';

class Almacen {
  static const _claveTareas = 'tareas';
  static const _claveTema = 'tema';
  static const _claveOrden = 'orden';

  Future<List<Tarea>> cargarTareas() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload(); // lee de nuevo el disco (útil al "jalar para actualizar")
    final texto = prefs.getString(_claveTareas);
    if (texto == null) return [];
    final lista = jsonDecode(texto) as List<dynamic>;
    return lista.map((e) => Tarea.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> guardarTareas(List<Tarea> tareas) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_claveTareas, jsonEncode(tareas.map((t) => t.toJson()).toList()));
  }

  Future<ThemeMode> cargarTema() async {
    final prefs = await SharedPreferences.getInstance();
    return ThemeMode.values.byName(prefs.getString(_claveTema) ?? ThemeMode.system.name);
  }

  Future<void> guardarTema(ThemeMode modo) async =>
      (await SharedPreferences.getInstance()).setString(_claveTema, modo.name);

  Future<Orden> cargarOrden() async {
    final prefs = await SharedPreferences.getInstance();
    return Orden.values.byName(prefs.getString(_claveOrden) ?? Orden.fecha.name);
  }

  Future<void> guardarOrden(Orden orden) async =>
      (await SharedPreferences.getInstance()).setString(_claveOrden, orden.name);
}
