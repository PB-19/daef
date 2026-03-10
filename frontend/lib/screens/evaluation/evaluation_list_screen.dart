import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:daef/config/constants.dart';
import 'package:daef/providers/evaluation_provider.dart';
import 'package:daef/widgets/evaluation_card.dart';
import 'package:daef/widgets/loading_indicator.dart';

class EvaluationListScreen extends StatefulWidget {
  const EvaluationListScreen({super.key});

  @override
  State<EvaluationListScreen> createState() => _EvaluationListScreenState();
}

class _EvaluationListScreenState extends State<EvaluationListScreen> {
  final _scrollCtrl = ScrollController();
  String? _selectedStatus;

  static const _statusFilters = [
    (label: 'All', value: null),
    (label: 'Pending', value: EvalStatus.pending),
    (label: 'Processing', value: EvalStatus.processing),
    (label: 'Completed', value: EvalStatus.completed),
    (label: 'Failed', value: EvalStatus.failed),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EvaluationProvider>().loadEvaluations();
    });
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      context.read<EvaluationProvider>().loadMore(status: _selectedStatus);
    }
  }

  void _applyFilter(String? status) {
    setState(() => _selectedStatus = status);
    context.read<EvaluationProvider>().loadEvaluations(status: status);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EvaluationProvider>();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Evaluations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<EvaluationProvider>().loadEvaluations(
                  status: _selectedStatus,
                ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _statusFilters.map((f) {
                  final isSelected = _selectedStatus == f.value;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(f.label),
                      selected: isSelected,
                      onSelected: (_) => _applyFilter(f.value),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/evaluations/create'),
        icon: const Icon(Icons.add),
        label: const Text('New Evaluation'),
      ),
      body: _buildBody(provider, cs, tt),
    );
  }

  Widget _buildBody(EvaluationProvider provider, ColorScheme cs, TextTheme tt) {
    if (provider.loading) {
      return const LoadingIndicator(message: 'Loading evaluations...');
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: cs.error),
            const SizedBox(height: 12),
            Text(provider.error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () =>
                  context.read<EvaluationProvider>().loadEvaluations(status: _selectedStatus),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (provider.evaluations.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assessment_outlined, size: 64, color: cs.outline),
            const SizedBox(height: 16),
            Text('No evaluations yet', style: tt.titleMedium?.copyWith(color: cs.outline)),
            const SizedBox(height: 8),
            Text(
              'Tap + to create your first evaluation',
              style: tt.bodyMedium?.copyWith(color: cs.outline),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          context.read<EvaluationProvider>().loadEvaluations(status: _selectedStatus),
      child: ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
        itemCount: provider.evaluations.length + (provider.loadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= provider.evaluations.length) return const InlineLoader();
          final eval = provider.evaluations[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: EvaluationCard(
              evaluation: eval,
              onTap: () => context.push('/evaluations/${eval.id}'),
            ),
          );
        },
      ),
    );
  }
}
