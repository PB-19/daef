import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:daef/config/constants.dart';
import 'package:daef/models/api_response.dart';
import 'package:daef/models/evaluation.dart';
import 'package:daef/services/evaluation_service.dart';

class EvaluationProvider extends ChangeNotifier {
  List<Evaluation> _evaluations = [];
  Evaluation? _current;
  List<EvaluationVersion> _versions = [];
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  int _page = 1;
  bool _hasMore = true;
  Timer? _pollTimer;

  List<Evaluation> get evaluations => _evaluations;
  Evaluation? get current => _current;
  List<EvaluationVersion> get versions => _versions;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  String? get error => _error;
  bool get hasMore => _hasMore;

  // ── Load first page ───────────────────────────────────────────────────────────

  Future<void> loadEvaluations({String? status}) async {
    _setLoading(true);
    _error = null;
    _page = 1;
    try {
      final result = await EvaluationService.instance.list(
        page: 1,
        status: status,
      );
      _evaluations = result.items;
      _hasMore = result.hasMore;
      _startPollingIfNeeded();
    } on ApiError catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ── Load next page (infinite scroll) ─────────────────────────────────────────

  Future<void> loadMore({String? status}) async {
    if (_loadingMore || !_hasMore) return;
    _loadingMore = true;
    notifyListeners();
    try {
      final result = await EvaluationService.instance.list(
        page: _page + 1,
        status: status,
      );
      _page++;
      _evaluations = [..._evaluations, ...result.items];
      _hasMore = result.hasMore;
      _startPollingIfNeeded();
    } on ApiError catch (e) {
      _error = e.toString();
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  // ── Load single evaluation detail ─────────────────────────────────────────────

  Future<void> loadDetail(String id) async {
    _setLoading(true);
    _error = null;
    try {
      _current = await EvaluationService.instance.get(id);
    } on ApiError catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ── Create ────────────────────────────────────────────────────────────────────

  Future<Evaluation?> create({
    required String domain,
    required String taskDescription,
    required String taskType,
    required List<String> focusAreas,
    List<String> mandatoryMetrics = const [],
    List<String> avoidedMetrics = const [],
    List<CustomMetric> customMetrics = const [],
    required String prompt,
    required String llmOutput,
    String? contextData,
    List<String> attachedFiles = const [],
  }) async {
    _setLoading(true);
    _error = null;
    try {
      final eval = await EvaluationService.instance.create(
        domain: domain,
        taskDescription: taskDescription,
        taskType: taskType,
        focusAreas: focusAreas,
        mandatoryMetrics: mandatoryMetrics,
        avoidedMetrics: avoidedMetrics,
        customMetrics: customMetrics,
        prompt: prompt,
        llmOutput: llmOutput,
        contextData: contextData,
        attachedFiles: attachedFiles,
      );
      _evaluations = [eval, ..._evaluations];
      _startPollingIfNeeded();
      return eval;
    } on ApiError catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // ── Delete ────────────────────────────────────────────────────────────────────

  Future<bool> delete(String id) async {
    try {
      await EvaluationService.instance.delete(id);
      _evaluations.removeWhere((e) => e.id == id);
      if (_current?.id == id) _current = null;
      notifyListeners();
      return true;
    } on ApiError catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Retry failed evaluation ───────────────────────────────────────────────────

  Future<bool> retry(String id) async {
    try {
      final updated = await EvaluationService.instance.retry(id);
      _replaceInList(updated);
      _startPollingIfNeeded();
      return true;
    } on ApiError catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Comparisons ───────────────────────────────────────────────────────────────

  Future<EvaluationVersion?> compare({
    required String baseId,
    required String newId,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      return await EvaluationService.instance.compare(
        baseEvaluationId: baseId,
        newEvaluationId: newId,
      );
    } on ApiError catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadVersions(String evaluationId) async {
    _setLoading(true);
    _error = null;
    try {
      _versions = await EvaluationService.instance.getVersions(evaluationId);
    } on ApiError catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ── Polling: refreshes in-progress evaluations every 5 seconds ───────────────

  void _startPollingIfNeeded() {
    final hasInProgress = _evaluations.any((e) => e.isInProgress);
    if (hasInProgress && _pollTimer == null) {
      _pollTimer = Timer.periodic(AppConstants.evalPollInterval, (_) => _poll());
    } else if (!hasInProgress) {
      _stopPolling();
    }
  }

  Future<void> _poll() async {
    final inProgress = _evaluations.where((e) => e.isInProgress).toList();
    if (inProgress.isEmpty) {
      _stopPolling();
      return;
    }
    for (final eval in inProgress) {
      try {
        final updated = await EvaluationService.instance.get(eval.id);
        _replaceInList(updated);
        if (_current?.id == updated.id) _current = updated;
      } catch (_) {
        // Ignore individual poll errors silently
      }
    }
    final stillInProgress = _evaluations.any((e) => e.isInProgress);
    if (!stillInProgress) _stopPolling();
    notifyListeners();
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void _replaceInList(Evaluation updated) {
    final idx = _evaluations.indexWhere((e) => e.id == updated.id);
    if (idx != -1) {
      _evaluations = List.from(_evaluations)..[idx] = updated;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearCurrent() {
    _current = null;
    _versions = [];
    notifyListeners();
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}
