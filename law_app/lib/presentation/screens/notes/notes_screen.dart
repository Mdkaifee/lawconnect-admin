import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/note_model.dart';
import '../../../logic/blocs/note/note_bloc.dart';
import '../../../logic/blocs/note/note_event.dart';
import '../../../logic/blocs/note/note_state.dart';
import '../../common_widgets/empty_view.dart';
import '../../common_widgets/error_view.dart';
import '../../common_widgets/loading_indicator.dart';
import 'add_edit_note_dialog.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['All Notes', 'By Case'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadNotes();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    _loadNotes();
  }

  void _loadNotes() {
    final refType = _tabController.index == 1 ? 'case' : null;
    context.read<NoteBloc>().add(FetchNotesEvent(refType: refType));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Notes'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primaryNavy,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.primaryNavy,
              indicatorWeight: 2.5,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              tabs: _tabs.map((t) => Tab(text: t)).toList(),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          AddEditNoteDialog.show(context);
        },
        backgroundColor: AppColors.primaryNavy,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: BlocBuilder<NoteBloc, NoteState>(
        builder: (context, state) {
          if (state is NoteLoading) {
            return const LoadingIndicator(message: 'Loading personal study notes...');
          }

          if (state is NoteError) {
            return ErrorView(
              message: state.message,
              onRetry: _loadNotes,
            );
          }

          if (state is NotesLoaded) {
            final notes = state.notes;

            if (notes.isEmpty) {
              return EmptyView(
                icon: Icons.note_alt_outlined,
                title: 'No Notes Found',
                subtitle: 'Tap the + button to write your first legal note or case summary.',
              );
            }

            return RefreshIndicator(
              onRefresh: () async => _loadNotes(),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: notes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final note = notes[index];
                  return _buildNoteCard(context, note);
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildNoteCard(BuildContext context, NoteModel note) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  note.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textMuted),
                onSelected: (value) {
                  if (value == 'edit') {
                    AddEditNoteDialog.show(context, note: note);
                  } else if (value == 'delete') {
                    context.read<NoteBloc>().add(DeleteNoteEvent(note.id));
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Edit Note'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete Note', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (note.refTitle != null && note.refTitle!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.accentGold.withAlpha(20),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Linked: ${note.refTitle}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.catCriminal,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            note.content,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Updated on ${note.updatedAt.day}/${note.updatedAt.month}/${note.updatedAt.year}',
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
