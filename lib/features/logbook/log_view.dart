import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

import '../../services/access_control_service.dart';
import '../onboarding/onboarding_view.dart';
import 'log_controller.dart';
import 'log_editor_page.dart';
import 'models/log_model.dart';

class LogView extends StatefulWidget {
  const LogView({super.key, required this.currentUser});

  final Map<String, dynamic> currentUser;

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  static final RegExp _objectIdPattern = RegExp(r'^[a-fA-F0-9]{24}$');
  static const List<String> _indonesianMonthNames = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  final LogController _controller = LogController();
  final TextEditingController _searchController = TextEditingController();
  late final Map<String, dynamic> _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = <String, dynamic>{
      'uid': (widget.currentUser['uid'] ?? 'unknown').toString(),
      'username': (widget.currentUser['username'] ?? 'guest').toString(),
      'role': (widget.currentUser['role'] ?? 'Anggota').toString(),
      'teamId': (widget.currentUser['teamId'] ?? 'unknown').toString(),
    };

    _controller.setSession(
      userId: _currentUser['uid'].toString(),
      userRole: _currentUser['role'].toString(),
      teamId: _currentUser['teamId'].toString(),
    );
    _controller.loadLogs(_currentUser['teamId'].toString());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatTimestamp(String timestamp) {
    final DateTime? parsedTime = DateTime.tryParse(timestamp);
    if (parsedTime == null) {
      return timestamp;
    }

    final DateTime localTime = parsedTime.toLocal();
    final Duration difference = DateTime.now().difference(localTime);

    if (!difference.isNegative) {
      if (difference.inMinutes < 1) {
        return 'Baru saja';
      }

      if (difference.inHours < 1) {
        return '${difference.inMinutes} menit yang lalu';
      }
    }

    try {
      return DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(localTime);
    } catch (_) {
      final String hour = localTime.hour.toString().padLeft(2, '0');
      final String minute = localTime.minute.toString().padLeft(2, '0');
      final String month = _indonesianMonthNames[localTime.month - 1];

      return '${localTime.day} $month ${localTime.year}, $hour:$minute';
    }
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'Akademik':
        return Colors.indigo;
      case 'Proyek':
        return Colors.teal;
      case 'Pribadi':
        return Colors.deepOrange;
      default:
        return Colors.blueGrey;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Akademik':
        return Icons.school;
      case 'Proyek':
        return Icons.build_circle_outlined;
      case 'Pribadi':
        return Icons.favorite_border;
      default:
        return Icons.label_outline;
    }
  }

  Future<void> _openEditor({LogModel? log, int? index}) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return LogEditorPage(
            log: log,
            index: index,
            controller: _controller,
            currentUser: _currentUser,
          );
        },
      ),
    );

    if (!mounted) {
      return;
    }
    _controller.loadLogs(_currentUser['teamId'].toString());
  }

  Future<void> _refreshLogs() async {
    _controller.loadLogs(_currentUser['teamId'].toString());
  }

  Future<void> _logout() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi Logout'),
          content: const Text('Yakin ingin logout sekarang?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute<OnboardingView>(
        builder: (BuildContext context) => const OnboardingView(),
      ),
      (Route<dynamic> route) => false,
    );
  }

  bool _hasCloudId(LogModel log) {
    final String? rawId = log.id?.trim();
    if (rawId == null || rawId.isEmpty) {
      return false;
    }
    return _objectIdPattern.hasMatch(rawId);
  }

  bool _isSynced(LogModel log) {
    return _hasCloudId(log) && !log.needsSync;
  }

  Widget _buildEmptyState({required bool isSearching}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'assets/animations/empty.json',
              height: 120,
              errorBuilder: (context, error, stackTrace) {
              //  debugPrint("Lottie Error Detail: $error");
          
                return Icon(
                  Icons.inbox_outlined,
                  size: 88,
                  color: Colors.blueGrey.shade300,
                );
              },
            ),
            const SizedBox(height: 14),
            Text(
              isSearching ? 'Tidak ada hasil pencarian' : 'Data Kosong',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? 'Coba kata kunci lain atau kosongkan pencarian.'
                  : 'Tambahkan log pertamamu untuk mulai menyimpan data.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.blueGrey.shade600),
              textAlign: TextAlign.center,
            ),
            if (!isSearching) ...<Widget>[
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: () {
                  _openEditor();
                },
                icon: const Icon(Icons.add),
                label: const Text('Tambah Log Pertama'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String role = _currentUser['role'].toString();
    final String userId = _currentUser['uid'].toString();
    final String username = _currentUser['username'].toString();
    final String teamId = _currentUser['teamId'].toString();

    return Scaffold(
      appBar: AppBar(
        title: Text('Logbook - $username'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ValueListenableBuilder<bool>(
                valueListenable: _controller.isOnlineNotifier,
                builder: (BuildContext context, bool isOnline, Widget? child) {
                  return Tooltip(
                    message: isOnline ? 'Online' : 'Offline',
                    child: Icon(
                      isOnline ? Icons.wifi : Icons.wifi_off,
                      color: isOnline ? Colors.green : Colors.orange,
                    ),
                  );
                },
              ),
            ),
          ),
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
              TextField(
                controller: _searchController,
                onChanged: (String query) {
                  _controller.searchLog(query);
                },
                decoration: InputDecoration(
                  labelText: 'Cari catatan',
                  hintText: 'Cari judul, deskripsi, atau kategori',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.blueGrey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.blueGrey.shade50,
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Role: $role • Team: $teamId',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.blueGrey),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ValueListenableBuilder<List<LogModel>>(
                  valueListenable: _controller.filteredLogs,
                  builder:
                      (
                        BuildContext context,
                        List<LogModel> logs,
                        Widget? child,
                      ) {
                        if (logs.isEmpty) {
                          return _buildEmptyState(
                            isSearching: _searchController.text
                                .trim()
                                .isNotEmpty,
                          );
                        }

                        return RefreshIndicator(
                          onRefresh: _refreshLogs,
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: logs.length,
                            padding: const EdgeInsets.only(bottom: 12),
                            itemBuilder: (BuildContext context, int index) {
                              final LogModel log = logs[index];
                              final int originalIndex = _controller.indexOfLog(
                                log,
                              );
                              if (originalIndex < 0) {
                                return const SizedBox.shrink();
                              }

                              final bool isOwner = log.authorId == userId;
                              final bool canUpdate =
                                  AccessControlService.canPerform(
                                    role,
                                    AccessControlService.actionUpdate,
                                    isOwner: isOwner,
                                  );
                              final bool canDelete =
                                  AccessControlService.canPerform(
                                    role,
                                    AccessControlService.actionDelete,
                                    isOwner: isOwner,
                                  );
                              final Color accentColor = _categoryColor(
                                log.category,
                              );

                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: accentColor.withValues(alpha: 0.26),
                                  ),
                                ),
                                color: accentColor.withValues(alpha: 0.08),
                                child: ListTile(
                                  title: Text(
                                    log.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 6),
                                      Text(log.description),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 6,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(99),
                                              color: log.visibility == 'public' ? Colors.green.withValues(alpha: 0.16,)
                                                  : Colors.blueGrey.withValues(
                                                      alpha: 0.16,
                                                    ),
                                            ),
                                            child: Icon(
                                              log.visibility == 'public' ? Icons.public : Icons.lock,
                                              size: 12,
                                              color: log.visibility == 'public' ? Colors.green : Colors.blueGrey,
                                            ),
                                            
                                          ),
                                          // Icon(
                                          //     log.visibility == 'public' ? Icons.public : Icons.lock,
                                          //     size: 12,
                                          //     color: log.visibility == 'public' ? Colors.green : Colors.blueGrey,
                                          //   ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(99),
                                              color: accentColor.withValues(
                                                alpha: 0.16,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  _categoryIcon(log.category),
                                                  size: 12,
                                                  color: accentColor,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  log.category,
                                                  style: TextStyle(
                                                    color: accentColor,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 12,
                                                    height: 1.1,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(
                                            _isSynced(log) ? Icons.cloud_outlined : Icons.cloud_off,
                                            size: 12,
                                            color: _isSynced(log)
                                                      ? Colors.green.shade700
                                                      : Colors.orange.shade700,
                                          ),
                                          const SizedBox(width: 10),
                                          Icon(
                                            Icons.schedule_outlined,
                                            size: 12,
                                            color: Colors.blueGrey.shade500,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              _formatTimestamp(log.timestamp),
                                              textAlign: TextAlign.left,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: Colors
                                                        .blueGrey
                                                        .shade600,
                                                    fontSize: 11,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: (canUpdate || canDelete)
                                      ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (canUpdate)
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.edit_outlined,
                                                ),
                                                tooltip: 'Edit',
                                                onPressed: () {
                                                  _openEditor(
                                                    log: log,
                                                    index: originalIndex,
                                                  );
                                                },
                                              ),
                                            if (canDelete)
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.delete_outline,
                                                ),
                                                tooltip: 'Hapus',
                                                onPressed: () {
                                                  _controller.removeLog(
                                                    originalIndex,
                                                  );
                                                  _showMessage(
                                                    'Catatan berhasil dihapus',
                                                  );
                                                },
                                              ),
                                          ],
                                        )
                                      : null,
                                ),
                              );
                            },
                          ),
                        );
                      },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton:
          AccessControlService.canPerform(
            role,
            AccessControlService.actionCreate,
          )
          ? FloatingActionButton(
              onPressed: () {
                _openEditor();
              },
              tooltip: 'Tambah Catatan',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
