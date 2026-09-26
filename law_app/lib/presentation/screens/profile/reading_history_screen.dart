import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/bookmark_repository.dart';
import '../../common_widgets/empty_view.dart';
import '../../common_widgets/loading_indicator.dart';
import '../cases/case_detail_screen.dart';

class ReadingHistoryScreen extends StatefulWidget {
  const ReadingHistoryScreen({super.key});

  @override
  State<ReadingHistoryScreen> createState() => _ReadingHistoryScreenState();
}

class _ReadingHistoryScreenState extends State<ReadingHistoryScreen> {
  late BookmarkRepository _repo;
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    StorageService.init().then((storage) {
      _repo = BookmarkRepository(ApiClient(storage));
      _loadHistory();
    });
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);
    try {
      final list = await _repo.getReadingHistory();
      setState(() {
        _history = list;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading History'),
      ),
      body: _loading
          ? const LoadingIndicator(message: 'Loading reading history...')
          : _history.isEmpty
              ? const EmptyView(
                  icon: Icons.history_rounded,
                  title: 'No Reading History',
                  subtitle: 'Cases and statutes you read will be recorded here.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _history.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = _history[index];
                    final title = item['title']?.toString() ?? 'Law Document';
                    final refId = item['refId']?.toString() ?? '';

                    return ListTile(
                      tileColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: AppColors.borderLight),
                      ),
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.cardNavy,
                        child: Icon(Icons.gavel, color: AppColors.accentGold, size: 20),
                      ),
                      title: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.textMuted),
                      onTap: () {
                        if (refId.isNotEmpty) {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => CaseDetailScreen(caseId: refId)),
                          );
                        }
                      },
                    );
                  },
                ),
    );
  }
}
