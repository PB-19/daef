import 'package:daef/models/api_response.dart';
import 'package:daef/models/evaluation.dart';
import 'package:daef/services/api_client.dart';

class EvaluationService {
  EvaluationService._();
  static final EvaluationService instance = EvaluationService._();

  final _client = ApiClient.instance;

  // ── Create ────────────────────────────────────────────────────────────────────

  Future<Evaluation> create({
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
    final response = await _client.post('/evaluations', data: {
      'domain': domain,
      'task_description': taskDescription,
      'task_type': taskType,
      'focus_areas': focusAreas,
      'mandatory_metrics': mandatoryMetrics,
      'avoided_metrics': avoidedMetrics,
      'custom_metrics': customMetrics.map((m) => m.toJson()).toList(),
      'prompt': prompt,
      'llm_output': llmOutput,
      'context_data': contextData,
      'attached_files': attachedFiles,
    });
    return Evaluation.fromJson(response.data as Map<String, dynamic>);
  }

  // ── List (paginated) ──────────────────────────────────────────────────────────

  Future<PaginatedResponse<Evaluation>> list({
    int page = 1,
    int pageSize = 20,
    String? status,
  }) async {
    final response = await _client.get('/evaluations', params: {
      'page': page,
      'page_size': pageSize,
      'status': status,
    });
    return PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      Evaluation.fromJson,
    );
  }

  // ── Get detail (includes metrics) ────────────────────────────────────────────

  Future<Evaluation> get(String id) async {
    final response = await _client.get('/evaluations/$id');
    return Evaluation.fromJson(response.data as Map<String, dynamic>);
  }

  // ── Delete ────────────────────────────────────────────────────────────────────

  Future<void> delete(String id) async {
    await _client.delete('/evaluations/$id');
  }

  // ── Retry a failed evaluation ─────────────────────────────────────────────────

  Future<Evaluation> retry(String id) async {
    final response = await _client.post('/evaluations/$id/retry');
    return Evaluation.fromJson(response.data as Map<String, dynamic>);
  }

  // ── Create comparison between two evaluations ─────────────────────────────────

  Future<EvaluationVersion> compare({
    required String baseEvaluationId,
    required String newEvaluationId,
  }) async {
    final response = await _client.post('/comparisons', data: {
      'base_evaluation_id': baseEvaluationId,
      'new_evaluation_id': newEvaluationId,
    });
    return EvaluationVersion.fromJson(response.data as Map<String, dynamic>);
  }

  // ── Get all version comparisons for an evaluation ─────────────────────────────

  Future<List<EvaluationVersion>> getVersions(String evaluationId) async {
    final response = await _client.get('/comparisons/evaluation/$evaluationId');
    return (response.data as List)
        .map((e) => EvaluationVersion.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
