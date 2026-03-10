import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:daef/models/evaluation.dart';
import 'package:daef/providers/evaluation_provider.dart';
import 'package:daef/utils/date_formatter.dart';
import 'package:daef/utils/helpers.dart';
import 'package:daef/widgets/loading_indicator.dart';

class EvaluationVersionsScreen extends StatefulWidget {
  final String evalId;
  const EvaluationVersionsScreen({required this.evalId, super.key});

  @override
  State<EvaluationVersionsScreen> createState() =>
      _EvaluationVersionsScreenState();
}

class _EvaluationVersionsScreenState extends State<EvaluationVersionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EvaluationProvider>().loadVersions(widget.evalId);
    });
  }

  void _showNewComparisonSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _NewComparisonSheet(baseEvalId: widget.evalId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EvaluationProvider>();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Version History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                context.read<EvaluationProvider>().loadVersions(widget.evalId),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNewComparisonSheet,
        icon: const Icon(Icons.compare_arrows),
        label: const Text('New Comparison'),
      ),
      body: _buildBody(provider, cs, tt),
    );
  }

  Widget _buildBody(EvaluationProvider provider, ColorScheme cs, TextTheme tt) {
    if (provider.loading) return const LoadingIndicator(message: 'Loading versions...');

    if (provider.versions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.compare_arrows, size: 64, color: cs.outline),
            const SizedBox(height: 16),
            Text('No comparisons yet', style: tt.titleMedium?.copyWith(color: cs.outline)),
            const SizedBox(height: 8),
            Text(
              'Tap + to compare this evaluation with another',
              style: tt.bodyMedium?.copyWith(color: cs.outline),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: provider.versions.length,
      itemBuilder: (context, index) {
        final version = provider.versions[index];
        return _VersionCard(version: version);
      },
    );
  }
}

class _VersionCard extends StatelessWidget {
  final EvaluationVersion version;
  const _VersionCard({required this.version});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final perfColor = Helpers.performanceColor(version.performanceChange, context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/comparisons/${version.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Helpers.performanceIcon(version.performanceChange),
                    color: version.isProcessing ? cs.outline : perfColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: version.isProcessing
                        ? Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: cs.primary),
                              ),
                              const SizedBox(width: 8),
                              Text('Processing comparison...',
                                  style: tt.bodyMedium?.copyWith(color: cs.outline)),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _perfLabel(version.performanceChange),
                                style: tt.titleSmall?.copyWith(
                                    color: perfColor, fontWeight: FontWeight.bold),
                              ),
                              if (version.scoreDifference != null)
                                Text(
                                  '${version.scoreDifference! > 0 ? '+' : ''}${version.scoreDifference!.toStringAsFixed(1)} pts',
                                  style: tt.bodySmall?.copyWith(color: perfColor),
                                ),
                            ],
                          ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                DateFormatter.formatted(version.createdAt),
                style: tt.bodySmall?.copyWith(color: cs.outline),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _perfLabel(String? change) => switch (change) {
        'better' => 'Improved',
        'worse' => 'Declined',
        'similar' => 'Similar',
        _ => 'Compared',
      };
}

// ── Bottom sheet for creating a new comparison ───────────────────────────────

class _NewComparisonSheet extends StatefulWidget {
  final String baseEvalId;
  const _NewComparisonSheet({required this.baseEvalId});

  @override
  State<_NewComparisonSheet> createState() => _NewComparisonSheetState();
}

class _NewComparisonSheetState extends State<_NewComparisonSheet> {
  String? _selectedNewEvalId;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EvaluationProvider>();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final candidates = provider.evaluations
        .where((e) => e.isCompleted && e.id != widget.baseEvalId)
        .toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('New Comparison',
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Select a second evaluation to compare against this one.',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          if (candidates.isEmpty)
            Text(
              'No other completed evaluations available.',
              style: tt.bodyMedium?.copyWith(color: cs.outline),
            )
          else
            DropdownButtonFormField<String>(
              initialValue: _selectedNewEvalId,
              hint: const Text('Select evaluation'),
              decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              items: candidates.map((e) {
                return DropdownMenuItem(
                  value: e.id,
                  child: Row(
                    children: [
                      Expanded(
                          child: Text(e.domain,
                              overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 8),
                      Text(
                        Helpers.formatScore(e.overallScore),
                        style: TextStyle(
                          color: Helpers.scoreColor(e.overallScore, context),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedNewEvalId = v),
            ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: provider.loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.compare_arrows),
              label: const Text('Compare'),
              onPressed: (_selectedNewEvalId == null || provider.loading)
                  ? null
                  : () => _runComparison(context, provider),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runComparison(
      BuildContext context, EvaluationProvider provider) async {
    final nav = GoRouter.of(context);
    final version = await provider.compare(
      baseId: widget.baseEvalId,
      newId: _selectedNewEvalId!,
    );
    if (!context.mounted) return;
    Navigator.pop(context); // close sheet
    if (version != null) {
      nav.push('/comparisons/${version.id}');
    } else if (provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error!),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}
