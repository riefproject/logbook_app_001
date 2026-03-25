import 'package:flutter/material.dart';
import 'dart:async';

import '../onboarding/onboarding_view.dart';
import 'log_controller.dart';
import 'log_editor_page.dart';
import 'models/log_model.dart';
import 'widgets/add_log_fab.dart';
import 'widgets/log_detail_sheet.dart';
import 'widgets/log_list.dart';
import 'widgets/log_search_bar.dart';
import 'widgets/online_status_indicator.dart';
import 'widgets/user_info_header.dart';

class LogView extends StatefulWidget {
  const LogView({super.key, required this.currentUser});

  final Map<String, dynamic> currentUser;

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  final LogController _controller = LogController();
  final TextEditingController _searchController = TextEditingController();
  late final Map<String, dynamic> _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = {
      'uid': (widget.currentUser['uid'] ?? 'unknown').toString(),
      'username': (widget.currentUser['username'] ?? 'guest').toString(),
      'role': (widget.currentUser['role'] ?? 'Anggota').toString(),
      'teamId': (widget.currentUser['teamId'] ?? 'unknown').toString(),
    };

    _controller.setSession(
      userId: _currentUser['uid'],
      userRole: _currentUser['role'],
      teamId: _currentUser['teamId'],
    );
    unawaited(_controller.loadLogs(_currentUser['teamId']));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  // --- Navigation & Dialogs ---
  void _openEditor({LogModel? log, int? index}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LogEditorPage(
          log: log,
          index: index,
          controller: _controller,
          currentUser: _currentUser,
        ),
      ),
    );
    if (mounted) _controller.refreshLogs();
  }

  void _showLogDetails(LogModel log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LogDetailSheet(log: log),
    );
  }

  Future<void> _logout() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Yakin ingin logout sekarang?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingView()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String role = _currentUser['role'];
    final String userId = _currentUser['uid'];
    final String teamId = _currentUser['teamId'];

    return Scaffold(
      appBar: AppBar(
        title: Text('Logbook - ${_currentUser['username']}'),
        actions: [
          OnlineStatusIndicator(controller: _controller),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Column(
            children: [
              LogSearchBar(
                controller: _controller,
                searchController: _searchController,
              ),
              const SizedBox(height: 8),
              UserInfoHeader(role: role, teamId: teamId),
              const SizedBox(height: 12),
              Expanded(
                child: LogList(
                  controller: _controller,
                  role: role,
                  userId: userId,
                  teamId: teamId,
                  onOpenEditor: _openEditor,
                  onShowDetails: _showLogDetails,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: AddLogFAB(role: role, onOpenEditor: _openEditor),
    );
  }
}
