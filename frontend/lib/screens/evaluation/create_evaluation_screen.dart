import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:daef/config/constants.dart';
import 'package:daef/models/evaluation.dart';
import 'package:daef/providers/evaluation_provider.dart';
import 'package:daef/services/file_service.dart';
import 'package:daef/utils/validators.dart';
import 'package:daef/widgets/custom_button.dart';

class CreateEvaluationScreen extends StatefulWidget {
  const CreateEvaluationScreen({super.key});

  @override
  State<CreateEvaluationScreen> createState() => _CreateEvaluationScreenState();
}

class _CreateEvaluationScreenState extends State<CreateEvaluationScreen> {
  int _step = 0;
  final _pageCtrl = PageController();

  // Step 1: Domain & task type
  final _domainCtrl = TextEditingController();
  String? _customDomain;
  String _taskType = TaskTypes.singleCall;

  // Step 2: Task description + focus areas
  final _taskDescCtrl = TextEditingController();
  final Set<String> _focusAreas = {};

  // Step 3: Prompt + output + context
  final _promptCtrl = TextEditingController();
  final _llmOutputCtrl = TextEditingController();
  final _contextCtrl = TextEditingController();

  // Step 4: Advanced (optional metrics + files)
  final _mandatoryCtrl = TextEditingController();
  final _avoidedCtrl = TextEditingController();
  final List<CustomMetric> _customMetrics = [];
  final _customMetricNameCtrl = TextEditingController();
  final _customMetricDescCtrl = TextEditingController();
  final List<PlatformFile> _pickedFiles = [];
  final List<String> _uploadedGcsPaths = [];
  bool _uploadingFile = false;

  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();
  final _step3Key = GlobalKey<FormState>();

  @override
  void dispose() {
    _pageCtrl.dispose();
    _domainCtrl.dispose();
    _taskDescCtrl.dispose();
    _promptCtrl.dispose();
    _llmOutputCtrl.dispose();
    _contextCtrl.dispose();
    _mandatoryCtrl.dispose();
    _avoidedCtrl.dispose();
    _customMetricNameCtrl.dispose();
    _customMetricDescCtrl.dispose();
    super.dispose();
  }

  bool _validateCurrentStep() {
    switch (_step) {
      case 0:
        return _step1Key.currentState?.validate() == true;
      case 1:
        if (!(_step2Key.currentState?.validate() == true)) return false;
        if (_focusAreas.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Select at least one focus area')),
          );
          return false;
        }
        return true;
      case 2:
        return _step3Key.currentState?.validate() == true;
      default:
        return true;
    }
  }

  void _nextStep() {
    if (!_validateCurrentStep()) return;
    if (_step < 3) {
      setState(() => _step++);
      _pageCtrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _submit();
    }
  }

  Future<void> _pickAndUploadFile() async {
    final file = await FileService.instance.pickFile();
    if (file == null) return;
    setState(() => _uploadingFile = true);
    try {
      final path = await FileService.instance.upload(file);
      setState(() {
        _pickedFiles.add(file);
        _uploadedGcsPaths.add(path);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e'), backgroundColor: Theme.of(context).colorScheme.error),
      );
    } finally {
      setState(() => _uploadingFile = false);
    }
  }

  void _removeFile(int index) {
    setState(() {
      _pickedFiles.removeAt(index);
      _uploadedGcsPaths.removeAt(index);
    });
  }

  void _prevStep() {
    if (_step > 0) {
      setState(() => _step--);
      _pageCtrl.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  Future<void> _submit() async {
    final domain = _domainCtrl.text.trim().isNotEmpty
        ? _domainCtrl.text.trim()
        : _customDomain ?? '';
    if (domain.isEmpty) {
      setState(() => _step = 0);
      return;
    }

    final mandatoryList = _mandatoryCtrl.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final avoidedList = _avoidedCtrl.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final eval = await context.read<EvaluationProvider>().create(
          domain: domain,
          taskDescription: _taskDescCtrl.text.trim(),
          taskType: _taskType,
          focusAreas: _focusAreas.toList(),
          mandatoryMetrics: mandatoryList,
          avoidedMetrics: avoidedList,
          customMetrics: _customMetrics,
          prompt: _promptCtrl.text.trim(),
          llmOutput: _llmOutputCtrl.text.trim(),
          contextData: _contextCtrl.text.trim().isNotEmpty ? _contextCtrl.text.trim() : null,
          attachedFiles: _uploadedGcsPaths,
        );

    if (!mounted) return;
    if (eval != null) {
      context.pop();
      context.push('/evaluations/${eval.id}');
    } else {
      final error = context.read<EvaluationProvider>().error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Failed to create evaluation'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<EvaluationProvider>().loading;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Evaluation'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Stepper indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: List.generate(4, (i) {
                return Expanded(
                  child: Row(
                    children: [
                      _StepDot(index: i, current: _step, cs: cs),
                      if (i < 3)
                        Expanded(
                          child: Container(
                            height: 2,
                            color: i < _step ? cs.primary : cs.outlineVariant,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ),
          // Step labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Domain', style: TextStyle(fontSize: 11)),
                Text('Description', style: TextStyle(fontSize: 11)),
                Text('Inputs', style: TextStyle(fontSize: 11)),
                Text('Advanced', style: TextStyle(fontSize: 11)),
              ],
            ),
          ),
          const Divider(height: 16),

          // Pages
          Expanded(
            child: PageView(
              controller: _pageCtrl,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _Step1Domain(
                  formKey: _step1Key,
                  domainCtrl: _domainCtrl,
                  taskType: _taskType,
                  onTaskTypeChanged: (t) => setState(() => _taskType = t),
                ),
                _Step2Description(
                  formKey: _step2Key,
                  taskDescCtrl: _taskDescCtrl,
                  focusAreas: _focusAreas,
                  onFocusToggle: (area) {
                    setState(() {
                      if (_focusAreas.contains(area)) {
                        _focusAreas.remove(area);
                      } else if (_focusAreas.length < AppConstants.maxFocusAreas) {
                        _focusAreas.add(area);
                      }
                    });
                  },
                ),
                _Step3Inputs(
                  formKey: _step3Key,
                  promptCtrl: _promptCtrl,
                  llmOutputCtrl: _llmOutputCtrl,
                  contextCtrl: _contextCtrl,
                ),
                _Step4Advanced(
                  mandatoryCtrl: _mandatoryCtrl,
                  avoidedCtrl: _avoidedCtrl,
                  customMetrics: _customMetrics,
                  nameCtrl: _customMetricNameCtrl,
                  descCtrl: _customMetricDescCtrl,
                  pickedFiles: _pickedFiles,
                  uploadingFile: _uploadingFile,
                  onAddCustomMetric: () {
                    final name = _customMetricNameCtrl.text.trim();
                    final desc = _customMetricDescCtrl.text.trim();
                    if (name.isNotEmpty && desc.isNotEmpty) {
                      setState(() {
                        _customMetrics.add(CustomMetric(name: name, description: desc));
                        _customMetricNameCtrl.clear();
                        _customMetricDescCtrl.clear();
                      });
                    }
                  },
                  onRemoveCustomMetric: (i) => setState(() => _customMetrics.removeAt(i)),
                  onPickFile: _pickAndUploadFile,
                  onRemoveFile: _removeFile,
                ),
              ],
            ),
          ),

          // Navigation buttons
          SafeArea(
            top: false,
            child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                if (_step > 0)
                  Expanded(
                    child: SecondaryButton(
                      label: 'Back',
                      onPressed: loading ? null : _prevStep,
                    ),
                  ),
                if (_step > 0) const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    label: _step == 3 ? 'Submit' : 'Continue',
                    onPressed: loading ? null : _nextStep,
                    loading: loading,
                  ),
                ),
              ],
            ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final int index;
  final int current;
  final ColorScheme cs;
  const _StepDot({required this.index, required this.current, required this.cs});

  @override
  Widget build(BuildContext context) {
    final done = index < current;
    final active = index == current;
    return CircleAvatar(
      radius: 14,
      backgroundColor: done || active ? cs.primary : cs.outlineVariant,
      child: done
          ? Icon(Icons.check, size: 16, color: cs.onPrimary)
          : Text(
              '${index + 1}',
              style: TextStyle(
                color: active ? cs.onPrimary : cs.outline,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
    );
  }
}

// ── Step 1: Domain & Task Type ─────────────────────────────────────────────────

class _Step1Domain extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController domainCtrl;
  final String taskType;
  final ValueChanged<String> onTaskTypeChanged;

  const _Step1Domain({
    required this.formKey,
    required this.domainCtrl,
    required this.taskType,
    required this.onTaskTypeChanged,
  });

  @override
  State<_Step1Domain> createState() => _Step1DomainState();
}

class _Step1DomainState extends State<_Step1Domain> {
  String? _selectedDomain;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: widget.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Domain', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('What domain is this LLM being used in?',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 12),

            // Predefined domain chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: Domains.predefined.map((d) {
                final isSelected = _selectedDomain == d;
                return FilterChip(
                  label: Text(d),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      _selectedDomain = isSelected ? null : d;
                      widget.domainCtrl.text = isSelected ? '' : d;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: widget.domainCtrl,
              decoration: const InputDecoration(
                labelText: 'Or enter custom domain',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              onChanged: (v) => setState(() => _selectedDomain = null),
              validator: (v) => (v == null || v.trim().isEmpty) && _selectedDomain == null
                  ? 'Domain is required'
                  : null,
            ),
            const SizedBox(height: 24),

            Text('Task Type', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('How is this LLM being invoked?',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 12),

            ...TaskTypes.displayNames.entries.map((e) {
              final selected = widget.taskType == e.key;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: selected ? cs.primaryContainer.withAlpha(80) : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: selected ? cs.primary : cs.outlineVariant,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => widget.onTaskTypeChanged(e.key),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                          color: selected ? cs.primary : cs.outline,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.value,
                                  style: TextStyle(
                                      fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
                              Text(
                                TaskTypes.descriptions[e.key] ?? '',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: cs.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Step 2: Description + Focus Areas ─────────────────────────────────────────

class _Step2Description extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController taskDescCtrl;
  final Set<String> focusAreas;
  final ValueChanged<String> onFocusToggle;

  const _Step2Description({
    required this.formKey,
    required this.taskDescCtrl,
    required this.focusAreas,
    required this.onFocusToggle,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Task Description', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Describe what the LLM is supposed to do.',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 12),
            TextFormField(
              controller: taskDescCtrl,
              decoration: const InputDecoration(
                labelText: 'Task Description',
                hintText: 'e.g. Summarize medical reports for doctors...',
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              validator: Validators.required,
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Text('Focus Areas', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Text(
                  '(${focusAreas.length}/${AppConstants.maxFocusAreas})',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Select up to ${AppConstants.maxFocusAreas} areas to emphasize in evaluation.',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            ...FocusAreas.all.map((area) {
              final icon = FocusAreas.icons[area] ?? '•';
              final selected = focusAreas.contains(area);
              final disabled = !selected && focusAreas.length >= AppConstants.maxFocusAreas;
              return CheckboxListTile(
                value: selected,
                title: Text('$icon  $area'),
                onChanged: disabled ? null : (_) => onFocusToggle(area),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Step 3: Prompt + LLM Output ────────────────────────────────────────────────

class _Step3Inputs extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController promptCtrl;
  final TextEditingController llmOutputCtrl;
  final TextEditingController contextCtrl;

  const _Step3Inputs({
    required this.formKey,
    required this.promptCtrl,
    required this.llmOutputCtrl,
    required this.contextCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Prompt', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('The prompt sent to the LLM.',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 8),
            TextFormField(
              controller: promptCtrl,
              decoration: const InputDecoration(
                labelText: 'Prompt',
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              validator: Validators.required,
            ),
            const SizedBox(height: 20),

            Text('LLM Output', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('The response generated by the LLM.',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 8),
            TextFormField(
              controller: llmOutputCtrl,
              decoration: const InputDecoration(
                labelText: 'LLM Output',
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              validator: Validators.required,
            ),
            const SizedBox(height: 20),

            Text('Context Data (optional)', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Any retrieved context (for RAG) or training examples.',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 8),
            TextFormField(
              controller: contextCtrl,
              decoration: const InputDecoration(
                labelText: 'Context Data',
                alignLabelWithHint: true,
              ),
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step 4: Advanced Options ────────────────────────────────────────────────────

class _Step4Advanced extends StatelessWidget {
  final TextEditingController mandatoryCtrl;
  final TextEditingController avoidedCtrl;
  final List<CustomMetric> customMetrics;
  final TextEditingController nameCtrl;
  final TextEditingController descCtrl;
  final List<PlatformFile> pickedFiles;
  final bool uploadingFile;
  final VoidCallback onAddCustomMetric;
  final ValueChanged<int> onRemoveCustomMetric;
  final VoidCallback onPickFile;
  final ValueChanged<int> onRemoveFile;

  const _Step4Advanced({
    required this.mandatoryCtrl,
    required this.avoidedCtrl,
    required this.customMetrics,
    required this.nameCtrl,
    required this.descCtrl,
    required this.pickedFiles,
    required this.uploadingFile,
    required this.onAddCustomMetric,
    required this.onRemoveCustomMetric,
    required this.onPickFile,
    required this.onRemoveFile,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Advanced (Optional)', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('All fields below are optional.',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 20),

          TextFormField(
            controller: mandatoryCtrl,
            decoration: const InputDecoration(
              labelText: 'Mandatory Metrics (comma-separated)',
              hintText: 'e.g. accuracy, relevance',
              prefixIcon: Icon(Icons.check_circle_outline),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: avoidedCtrl,
            decoration: const InputDecoration(
              labelText: 'Avoided Metrics (comma-separated)',
              hintText: 'e.g. creativity, humor',
              prefixIcon: Icon(Icons.remove_circle_outline),
            ),
          ),
          const SizedBox(height: 24),

          // ── Attached Files ──────────────────────────────────────────────────
          Row(
            children: [
              Text('Attached Files', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Text('(PDF, TXT)', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 8),
          ...pickedFiles.asMap().entries.map((entry) {
            final file = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.attach_file),
                title: Text(file.name, overflow: TextOverflow.ellipsis),
                subtitle: file.size > 0
                    ? Text('${(file.size / 1024).toStringAsFixed(1)} KB')
                    : null,
                trailing: IconButton(
                  icon: Icon(Icons.delete_outline, color: cs.error),
                  onPressed: () => onRemoveFile(entry.key),
                ),
              ),
            );
          }),
          OutlinedButton.icon(
            icon: uploadingFile
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
                  )
                : const Icon(Icons.upload_file),
            label: Text(uploadingFile ? 'Uploading...' : 'Attach File'),
            onPressed: uploadingFile ? null : onPickFile,
          ),
          const SizedBox(height: 24),

          // ── Custom Metrics ──────────────────────────────────────────────────
          Text('Custom Metrics', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          ...customMetrics.asMap().entries.map((entry) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(entry.value.name),
                subtitle: Text(entry.value.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: IconButton(
                  icon: Icon(Icons.delete_outline, color: cs.error),
                  onPressed: () => onRemoveCustomMetric(entry.key),
                ),
              ),
            );
          }),

          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Metric Name',
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      isDense: true,
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add Metric'),
                      onPressed: onAddCustomMetric,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
