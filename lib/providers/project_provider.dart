import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/planka_project.dart';
import 'auth_provider.dart';

class ProjectProvider with ChangeNotifier {
  List<PlankaProject> _projects = [];
  final AuthProvider authProvider;

  ProjectProvider(this.authProvider);

  List<PlankaProject> get projects => _projects;

  Future<void> fetchProjects() async {
    final url = Uri.parse('https://${authProvider.domain}/api/projects');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer ${authProvider.token}'},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final projectsJson = responseData['items'] as List<dynamic>;
        final includedData = responseData['included'];

        _projects = projectsJson.map((projectJson) => PlankaProject.fromJson(projectJson, includedData)).toList();
        notifyListeners();
      } else {
        debugPrint('Failed to load projects: ${response.statusCode}');
        throw Exception('Failed to load projects');
      }
    } catch (error) {
      debugPrint('Error: $error');
      throw Exception('Failed to load projects');
    }
  }

  Future<void> createProject(String newProjectName) async {
    final url = Uri.parse('https://${authProvider.domain}/api/projects/?name=$newProjectName');

    try {
      final response = await http.post(
        url,
        headers: {'Authorization': 'Bearer ${authProvider.token}'},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final projectsJson = responseData['items'] as List<dynamic>;
        final includedData = responseData['included'];

        _projects = projectsJson.map((projectJson) => PlankaProject.fromJson(projectJson, includedData)).toList();

        notifyListeners();
      } else {
        debugPrint('Failed to load projects: ${response.statusCode}');
        throw Exception('Failed to load projects');
      }
    } catch (error) {
      debugPrint('Error: $error');
      throw Exception('Failed to load projects');
    }
  }

  Future<void> deleteProject(String newProjectName) async {
    final url = Uri.parse('https://${authProvider.domain}/api/projects/?name=$newProjectName');

    try {
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer ${authProvider.token}'},
      );

      if (response.statusCode == 200) {
        // final responseData = json.decode(response.body);
        // final projectsJson = responseData['items'] as List<dynamic>;
        // final includedData = responseData['included'];
        //
        // _projects = projectsJson.map((projectJson) => PlankaProject.fromJson(projectJson, includedData)).toList();
        // notifyListeners();
      } else {
        debugPrint('Failed to load projects: ${response.statusCode}');
        throw Exception('Failed to load projects');
      }
    } catch (error) {
      debugPrint('Error: $error');
      throw Exception('Failed to load projects');
    }
  }
}