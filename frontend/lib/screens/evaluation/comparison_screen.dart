import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:daef/models/evaluation.dart';
import 'package:daef/providers/evaluation_provider.dart';
import 'package:daef/utils/date_formatter.dart';
import 'package:daef/utils/helpers.dart';

class ComparisonScreen extends StatefulWidget {
  final String versionId;
  const ComparisonScreen({required this.versionId, super.key});

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  String? _baseId;
  String? _newId;

  @override
  void initState() {
    super.initState();
    // versionId may be 'new' for creating a new comparison,
    // or an existing version ID for viewing
    if (widget.versionId != 'new') {
      _loadVersion();
    }
  }

  Future<void> _loadVersion() async {
    // Not directly supported by provider — load versions for the current eval
    // The version data will come from the provider
  }

  Future<void> _compare() async {
    if (_baseId == null || _newId == null) return;
    final version = await context.read<EvaluationProvider>().compare(
          baseId: _baseId!,
          newId: _newId!,
        );
    if (!mounted) return;
    if (version != null) {
      context.pushReplacement('/comparisons/${version.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EvaluationProvider>();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Find version in provider if available
    final version = widget.versionId != 'new'
        ? provider.versions.where((v) => v.id == widget.versionId).firstOrNull
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Version Comparison'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: version != null
          ? _VersionDetail(version: version, cs: cs, tt: tt)
          : _NewComparison(
              evaluations: provider.evaluations,
              baseId: _baseId,
              newId: _newId,
              loading: provider.loading,
              onBaseChanged: (id) => setState(() => _baseId = id),
              onNewChanged: (id) => setState(() => _newId = id),
              onCompare: _compare,
              cs: cs,
              tt: tt,
            ),
    );
  }
}

class _VersionDetail extends StatelessWidget {
  final EvaluationVersion version;
  final ColorScheme cs;
  final TextTheme tt;
  const _VersionDetail({required this.version, required this.cs, required this.tt});

  @override
  Widget build(BuildContext context) {
    if (version.isProcessing) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Comparison in progress...'),
          ],
        ),
      );
    }

    final perfColor = Helpers.performanceColor(version.performanceChange, context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 56),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Performance summary card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Helpers.performanceIcon(version.performanceChange),
                          color: perfColor, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _perfLabel(version.performanceChange),
                              style: tt.titleLarge?.copyWith(
                                  color: perfColor, fontWeight: FontWeight.bold),
                            ),
                            if (version.scoreDifference != null)
                              Text(
                                '${version.scoreDifference! > 0 ? '+' : ''}${version.scoreDifference!.toStringAsFixed(1)} points',
                                style: tt.bodyLarge?.copyWith(color: perfColor),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Compared on ${DateFormatter.formatted(version.createdAt)}',
                    style: tt.bodySmall?.copyWith(color: cs.outline),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Comparison report
          if (version.comparisonReport != null) ...[
            Text('Comparison Report',
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...version.comparisonReport!.entries.map((e) {
              if (e.value is String) {
                return _ReportSection(title: _formatKey(e.key), content: e.value as String);
              }
              return const SizedBox.shrink();
            }),
          ],
        ],
      ),
    );
  }

  String _perfLabel(String? change) => switch (change) {
        'better' => 'Improved',
        'worse' => 'Declined',
        _ => 'Similar Performance',
      };

  String _formatKey(String key) =>
      key.replaceAll('_', ' ').split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
}

class _ReportSection extends StatelessWidget {
  final String title;
  final String content;
  const _ReportSection({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: tt.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(content, style: tt.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _NewComparison extends StatelessWidget {
  final List<Evaluation> evaluations;
  final String? baseId;
  final String? newId;
  final bool loading;
  final ValueChanged<String?> onBaseChanged;
  final ValueChanged<String?> onNewChanged;
  final VoidCallback onCompare;
  final ColorScheme cs;
  final TextTheme tt;

  const _NewComparison({
    required this.evaluations,
    required this.baseId,
    required this.newId,
    required this.loading,
    required this.onBaseChanged,
    required this.onNewChanged,
    required this.onCompare,
    required this.cs,
    required this.tt,
  });

  @override
  Widget build(BuildContext context) {
    final completed = evaluations.where((e) => e.isCompleted).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Compare two evaluations to see how your model improved.',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 24),
          Text('Base Evaluation', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _EvalDropdown(
            evaluations: completed,
            value: baseId,
            hint: 'Select base evaluation',
            onChanged: onBaseChanged,
          ),
          const SizedBox(height: 16),
          Text('New Evaluation', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _EvalDropdown(
            evaluations: completed.where((e) => e.id != baseId).toList(),
            value: newId,
            hint: 'Select new evaluation',
            onChanged: onNewChanged,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.compare_arrows),
              label: const Text('Compare'),
              onPressed: (baseId != null && newId != null && !loading) ? onCompare : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _EvalDropdown extends StatelessWidget {
  final List<Evaluation> evaluations;
  final String? value;
  final String hint;
  final ValueChanged<String?> onChanged;

  const _EvalDropdown({
    required this.evaluations,
    required this.value,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      hint: Text(hint),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: evaluations.map((e) {
        return DropdownMenuItem(
          value: e.id,
          child: Row(
            children: [
              Expanded(child: Text(e.domain, overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              Text(
                Helpers.formatScore(e.overallScore),
                style: TextStyle(
                    color: Helpers.scoreColor(e.overallScore, context),
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
