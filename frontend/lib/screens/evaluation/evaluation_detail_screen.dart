import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:daef/models/evaluation.dart';
import 'package:daef/providers/auth_provider.dart';
import 'package:daef/providers/evaluation_provider.dart';
import 'package:daef/providers/social_provider.dart';
import 'package:daef/utils/date_formatter.dart';
import 'package:daef/utils/helpers.dart';
import 'package:daef/widgets/loading_indicator.dart';

class EvaluationDetailScreen extends StatefulWidget {
  final String evaluationId;
  const EvaluationDetailScreen({required this.evaluationId, super.key});

  @override
  State<EvaluationDetailScreen> createState() => _EvaluationDetailScreenState();
}

class _EvaluationDetailScreenState extends State<EvaluationDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EvaluationProvider>().loadDetail(widget.evaluationId);
    });
  }

  Future<void> _deleteEvaluation(Evaluation eval) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Evaluation'),
        content: const Text('This will permanently delete this evaluation and all related data.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final success = await context.read<EvaluationProvider>().delete(eval.id);
      if (success && mounted) context.pop();
    }
  }

  Future<void> _shareEvaluation(Evaluation eval) async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Share to Feed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Title (optional)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Share'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final post = await context.read<SocialProvider>().shareEvaluation(
            evaluationId: eval.id,
            title: titleCtrl.text.trim().isNotEmpty ? titleCtrl.text.trim() : null,
            description: descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : null,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(post != null ? 'Shared to feed!' : 'Failed to share')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EvaluationProvider>();
    final currentUserId = context.watch<AuthProvider>().user?.id;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (provider.loading) return const Scaffold(body: LoadingIndicator());

    final eval = provider.current;
    if (eval == null) {
      return Scaffold(
        appBar: AppBar(leading: BackButton(onPressed: () => context.pop())),
        body: const Center(child: Text('Evaluation not found')),
      );
    }

    final isOwner = eval.userId == currentUserId;
    final statusColor = Helpers.statusColor(eval.status, context);

    return Scaffold(
      appBar: AppBar(
        title: Text(eval.domain),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (eval.isCompleted)
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: () => _shareEvaluation(eval),
              tooltip: 'Share to Feed',
            ),
          if (isOwner)
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'delete') _deleteEvaluation(eval);
                if (v == 'compare') context.push('/evaluations/${eval.id}/versions');
                if (v == 'retry') context.read<EvaluationProvider>().retry(eval.id);
              },
              itemBuilder: (_) => [
                if (eval.canRetry)
                  const PopupMenuItem(value: 'retry', child: Text('Retry')),
                if (eval.isCompleted)
                  const PopupMenuItem(value: 'compare', child: Text('Compare Versions')),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<EvaluationProvider>().loadDetail(widget.evaluationId),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status + score header
              _SummaryCard(eval: eval, statusColor: statusColor, tt: tt, cs: cs),
              const SizedBox(height: 16),

              // In-progress state
              if (eval.isInProgress) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Evaluation is ${eval.status}. This page will update automatically.',
                            style: tt.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Error message
              if (eval.errorMessage != null) ...[
                Card(
                  color: cs.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.error_outline, color: cs.onErrorContainer),
                            const SizedBox(width: 8),
                            Text('Error', style: tt.titleSmall?.copyWith(color: cs.onErrorContainer)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(eval.errorMessage!, style: TextStyle(color: cs.onErrorContainer)),
                        if (eval.canRetry) ...[
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () => context.read<EvaluationProvider>().retry(eval.id),
                            child: const Text('Retry'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Metrics
              if (eval.metrics.isNotEmpty) ...[
                Text('Metrics', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...eval.metrics.map((m) => _MetricRow(metric: m, cs: cs, tt: tt)),
                const SizedBox(height: 16),
              ],

              // Agent insights
              if (eval.agentInsights != null) ...[
                Text('Agent Insights', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(eval.agentInsights!, style: tt.bodyMedium),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Input details
              _CollapsibleSection(
                title: 'Input Details',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DetailRow(label: 'Task Type', value: Helpers.taskTypeLabel(eval.taskType)),
                    _DetailRow(
                      label: 'Focus Areas',
                      value: eval.focusAreas.join(', '),
                    ),
                    _DetailRow(label: 'Task Description', value: eval.taskDescription),
                    _DetailRow(label: 'Created', value: DateFormatter.full(eval.createdAt)),
                    if (eval.processingTimeSeconds != null)
                      _DetailRow(
                        label: 'Processing Time',
                        value: '${eval.processingTimeSeconds}s',
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _CollapsibleSection(
                title: 'Prompt',
                child: Text(eval.prompt, style: tt.bodyMedium),
              ),
              const SizedBox(height: 12),
              _CollapsibleSection(
                title: 'LLM Output',
                child: Text(eval.llmOutput, style: tt.bodyMedium),
              ),
              if (eval.contextData != null) ...[
                const SizedBox(height: 12),
                _CollapsibleSection(
                  title: 'Context Data',
                  child: Text(eval.contextData!, style: tt.bodyMedium),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final Evaluation eval;
  final Color statusColor;
  final TextTheme tt;
  final ColorScheme cs;

  const _SummaryCard({
    required this.eval,
    required this.statusColor,
    required this.tt,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusColor.withAlpha(80)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Helpers.statusIcon(eval.status), size: 14, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              Helpers.statusLabel(eval.status),
                              style: TextStyle(
                                  fontSize: 12, color: statusColor, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(eval.domain, style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    Helpers.taskTypeLabel(eval.taskType),
                    style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if (eval.overallScore != null)
              Column(
                children: [
                  Text(
                    Helpers.formatScore(eval.overallScore),
                    style: tt.displaySmall?.copyWith(
                      color: Helpers.scoreColor(eval.overallScore, context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    Helpers.scoreLabel(eval.overallScore),
                    style: tt.bodySmall?.copyWith(
                      color: Helpers.scoreColor(eval.overallScore, context),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final EvaluationMetric metric;
  final ColorScheme cs;
  final TextTheme tt;
  const _MetricRow({required this.metric, required this.cs, required this.tt});

  @override
  Widget build(BuildContext context) {
    final pct = metric.percentage;
    final color = pct >= 80
        ? const Color(0xFF2E7D32)
        : pct >= 60
            ? const Color(0xFFE65100)
            : cs.error;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    metric.metricName,
                    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '${metric.score.toStringAsFixed(1)} / ${metric.maxScore.toStringAsFixed(0)}',
                  style: tt.labelLarge?.copyWith(color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct / 100,
                backgroundColor: color.withAlpha(30),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
            if (metric.reasoning != null) ...[
              const SizedBox(height: 6),
              Text(
                metric.reasoning!,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CollapsibleSection extends StatefulWidget {
  final String title;
  final Widget child;
  const _CollapsibleSection({required this.title, required this.child});

  @override
  State<_CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<_CollapsibleSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(widget.title,
                        style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: widget.child,
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: tt.bodySmall?.copyWith(color: cs.outline)),
          ),
          Expanded(child: Text(value, style: tt.bodyMedium)),
        ],
      ),
    );
  }
}
