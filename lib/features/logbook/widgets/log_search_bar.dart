import 'package:flutter/material.dart';
import '../log_controller.dart';

class LogSearchBar extends StatelessWidget {
  const LogSearchBar({
    super.key,
    required this.controller,
    required this.searchController,
  });

  final LogController controller;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: searchController,
      onChanged: controller.searchLog,
      decoration: InputDecoration(
        labelText: 'Cari catatan',
        hintText: 'Cari judul, deskripsi, atau kategori',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.blueGrey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
