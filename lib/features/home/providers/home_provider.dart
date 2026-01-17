import 'package:flutter/material.dart';
import '../../../core/models/property_model.dart';
import '../../../core/services/properties_service.dart';

class HomeProvider extends ChangeNotifier {
  final PropertiesService _propertiesService = PropertiesService();

  Stream<List<Property>> get propertiesStream =>
      _propertiesService.getPropertiesStream();

  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;

  int _selectedCategoryIndex = 0;
  int get selectedCategoryIndex => _selectedCategoryIndex;

  void setIndex(int index) {
    if (_selectedIndex != index) {
      _selectedIndex = index;
      notifyListeners();
    }
  }

  void setCategoryIndex(int index) {
    if (_selectedCategoryIndex != index) {
      _selectedCategoryIndex = index;
      notifyListeners();
    }
  }
}
