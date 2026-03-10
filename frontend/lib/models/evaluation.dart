// Matches backend MetricResponse schema exactly
class EvaluationMetric {
  final String metricName;
  final String? metricCategory;
  final double score;
  final double maxScore;
  final double? weight;
  final String? reasoning;

  const EvaluationMetric({
    required this.metricName,
    this.metricCategory,
    required this.score,
    required this.maxScore,
    this.weight,
    this.reasoning,
  });

  factory EvaluationMetric.fromJson(Map<String, dynamic> json) =>
      EvaluationMetric(
        metricName: json['metric_name'] as String,
        metricCategory: json['metric_category'] as String?,
        score: (json['score'] as num).toDouble(),
        maxScore: (json['max_score'] as num? ?? 100).toDouble(),
        weight: json['weight'] != null ? (json['weight'] as num).toDouble() : null,
        reasoning: json['reasoning'] as String?,
      );

  double get percentage => maxScore > 0 ? (score / maxScore) * 100 : 0;
}

// Used only for create request (not an API response model)
class CustomMetric {
  final String name;
  final String description;

  const CustomMetric({required this.name, required this.description});

  factory CustomMetric.fromJson(Map<String, dynamic> json) => CustomMetric(
        name: json['name'] as String,
        description: json['description'] as String,
      );

  Map<String, dynamic> toJson() => {'name': name, 'description': description};
}

// Matches backend EvaluationResponse + EvaluationDetailResponse schemas
class Evaluation {
  final String id;
  final String userId;
  final String domain;
  final String taskDescription;
  final String taskType;
  final List<String> focusAreas;
  final String prompt;
  final String llmOutput;
  final String? contextData;
  final double? overallScore;
  final Map<String, dynamic>? evaluationReport;
  final String? agentInsights;
  final String status;
  final String? errorMessage;
  final int? processingTimeSeconds;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Only populated by EvaluationDetailResponse
  final List<EvaluationMetric> metrics;

  const Evaluation({
    required this.id,
    required this.userId,
    required this.domain,
    required this.taskDescription,
    required this.taskType,
    required this.focusAreas,
    required this.prompt,
    required this.llmOutput,
    this.contextData,
    this.overallScore,
    this.evaluationReport,
    this.agentInsights,
    required this.status,
    this.errorMessage,
    this.processingTimeSeconds,
    required this.createdAt,
    required this.updatedAt,
    this.metrics = const [],
  });

  factory Evaluation.fromJson(Map<String, dynamic> json) => Evaluation(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        domain: json['domain'] as String,
        taskDescription: json['task_description'] as String,
        taskType: json['task_type'] as String,
        focusAreas: List<String>.from(json['focus_areas'] as List? ?? []),
        prompt: json['prompt'] as String,
        llmOutput: json['llm_output'] as String,
        contextData: json['context_data'] as String?,
        overallScore: json['overall_score'] != null
            ? (json['overall_score'] as num).toDouble()
            : null,
        evaluationReport:
            json['evaluation_report'] as Map<String, dynamic>?,
        agentInsights: json['agent_insights'] as String?,
        status: json['status'] as String,
        errorMessage: json['error_message'] as String?,
        processingTimeSeconds: json['processing_time_seconds'] as int?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        metrics: (json['metrics'] as List? ?? [])
            .map((e) => EvaluationMetric.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  bool get isPending => status == 'pending';
  bool get isProcessing => status == 'processing';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isInProgress => isPending || isProcessing;
  bool get canRetry => isFailed;
}

// Matches backend VersionComparisonResponse schema — all result fields are Optional
class EvaluationVersion {
  final String id;
  final String baseEvaluationId;
  final String newEvaluationId;
  final Map<String, dynamic>? comparisonReport;
  final String? performanceChange;
  final double? scoreDifference;
  final DateTime createdAt;

  const EvaluationVersion({
    required this.id,
    required this.baseEvaluationId,
    required this.newEvaluationId,
    this.comparisonReport,
    this.performanceChange,
    this.scoreDifference,
    required this.createdAt,
  });

  factory EvaluationVersion.fromJson(Map<String, dynamic> json) =>
      EvaluationVersion(
        id: json['id'] as String,
        baseEvaluationId: json['base_evaluation_id'] as String,
        newEvaluationId: json['new_evaluation_id'] as String,
        comparisonReport:
            json['comparison_report'] as Map<String, dynamic>?,
        performanceChange: json['performance_change'] as String?,
        scoreDifference: json['score_difference'] != null
            ? (json['score_difference'] as num).toDouble()
            : null,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  bool get isBetter => performanceChange == 'better';
  bool get isWorse => performanceChange == 'worse';
  bool get isProcessing => comparisonReport == null;
}
