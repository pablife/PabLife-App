import 'package:flutter/material.dart';
import '../../../widgets/design_system/app_text_form_field.dart';
import '../users_controller.dart';

class SearchField extends StatefulWidget {
  final UsersController controller;

  const SearchField({super.key, required this.controller});

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppTextFormField(
      controller: _searchController,
      hintText: 'Pesquisar por nome ou email',
      suffixIcon: const Icon(Icons.search),
    );
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      widget.controller.filterUsers(_searchController.text);
    });
  }
}
