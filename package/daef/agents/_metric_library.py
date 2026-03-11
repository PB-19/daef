import logging

logger = logging.getLogger(__name__)

# ── Static metric definitions ──────────────────────────────────────────────────
# Each metric: name, category, applicable_task_types, applicable_focus_areas, description

_METRIC_LIBRARY = [
    # RAG-specific
    {
        "metric_name": "Faithfulness",
        "metric_category": "RAG Quality",
        "task_types": ["rag"],
        "focus_areas": ["Content Generation Quality", "Data and Dataset Related"],
        "description": "Measures whether all claims in the answer are supported by the retrieved context. Penalises hallucinated facts.",
    },
    {
        "metric_name": "Answer Relevancy",
        "metric_category": "RAG Quality",
        "task_types": ["rag"],
        "focus_areas": ["Content Generation Quality", "User Experience"],
        "description": "Measures how directly and completely the answer addresses the user question.",
    },
    {
        "metric_name": "Context Recall",
        "metric_category": "RAG Quality",
        "task_types": ["rag"],
        "focus_areas": ["Content Generation Quality", "Data and Dataset Related"],
        "description": "Measures what fraction of ground-truth information appears in the retrieved context.",
    },
    {
        "metric_name": "Context Precision",
        "metric_category": "RAG Quality",
        "task_types": ["rag"],
        "focus_areas": ["Content Generation Quality", "Data and Dataset Related"],
        "description": "Measures the signal-to-noise ratio of retrieved chunks — how much is actually useful.",
    },
    {
        "metric_name": "Groundedness",
        "metric_category": "RAG Quality",
        "task_types": ["rag"],
        "focus_areas": ["Content Generation Quality", "Security and Guardrails"],
        "description": "Measures whether each factual claim in the response is grounded in the provided source documents.",
    },
    {
        "metric_name": "Answer Completeness",
        "metric_category": "RAG Quality",
        "task_types": ["rag"],
        "focus_areas": ["Content Generation Quality", "User Experience"],
        "description": "Measures whether the answer fully addresses all aspects of the question without omissions.",
    },
    # Fine-tuning specific
    {
        "metric_name": "Instruction Following",
        "metric_category": "Fine-tuning Quality",
        "task_types": ["tuning"],
        "focus_areas": ["Content Generation Quality", "User Experience"],
        "description": "Measures how accurately the model follows the format, style, and structural instructions it was tuned on.",
    },
    {
        "metric_name": "Domain Adaptation",
        "metric_category": "Fine-tuning Quality",
        "task_types": ["tuning"],
        "focus_areas": ["Content Generation Quality", "Data and Dataset Related"],
        "description": "Measures correct usage of domain-specific terminology, tone, and conventions.",
    },
    {
        "metric_name": "Consistency",
        "metric_category": "Fine-tuning Quality",
        "task_types": ["tuning"],
        "focus_areas": ["Content Generation Quality", "Performance, Cost and Operations"],
        "description": "Measures whether the model produces consistent responses to semantically similar inputs.",
    },
    {
        "metric_name": "Factual Accuracy",
        "metric_category": "Fine-tuning Quality",
        "task_types": ["tuning", "single_call"],
        "focus_areas": ["Content Generation Quality", "Legal and Regulatory Compliance"],
        "description": "Measures correctness of domain-specific factual claims against known ground truth.",
    },
    # Single call / general
    {
        "metric_name": "Coherence",
        "metric_category": "Generation Quality",
        "task_types": ["single_call", "tuning"],
        "focus_areas": ["Content Generation Quality", "User Experience"],
        "description": "Measures logical flow, structure, and internal consistency of the response.",
    },
    {
        "metric_name": "Fluency",
        "metric_category": "Generation Quality",
        "task_types": ["single_call", "tuning"],
        "focus_areas": ["Content Generation Quality", "User Experience"],
        "description": "Measures grammatical correctness and naturalness of language.",
    },
    {
        "metric_name": "Response Relevance",
        "metric_category": "Generation Quality",
        "task_types": ["single_call", "tuning", "rag"],
        "focus_areas": ["Content Generation Quality", "User Experience"],
        "description": "Measures how well the response addresses the specific prompt or question asked.",
    },
    {
        "metric_name": "Helpfulness",
        "metric_category": "User Experience",
        "task_types": ["single_call", "tuning", "rag"],
        "focus_areas": ["User Experience", "Content Generation Quality"],
        "description": "Measures the practical utility and actionability of the response for the user.",
    },
    {
        "metric_name": "Conciseness",
        "metric_category": "User Experience",
        "task_types": ["single_call", "tuning", "rag"],
        "focus_areas": ["User Experience", "Performance, Cost and Operations"],
        "description": "Measures whether the response avoids unnecessary verbosity without sacrificing completeness.",
    },
    # Safety & Security
    {
        "metric_name": "Toxicity",
        "metric_category": "Safety",
        "task_types": ["single_call", "tuning", "rag"],
        "focus_areas": ["Security and Guardrails"],
        "description": "Measures absence of harmful, offensive, or inappropriate content in the response.",
    },
    {
        "metric_name": "PII Leakage",
        "metric_category": "Safety",
        "task_types": ["single_call", "tuning", "rag"],
        "focus_areas": ["Security and Guardrails", "Legal and Regulatory Compliance"],
        "description": "Detects whether the response exposes personally identifiable information inappropriately.",
    },
    {
        "metric_name": "Prompt Injection Resistance",
        "metric_category": "Safety",
        "task_types": ["single_call", "tuning", "rag"],
        "focus_areas": ["Security and Guardrails"],
        "description": "Measures the model's resistance to prompt injection attacks and jailbreak attempts.",
    },
    {
        "metric_name": "Hallucination Rate",
        "metric_category": "Safety",
        "task_types": ["single_call", "tuning", "rag"],
        "focus_areas": ["Security and Guardrails", "Content Generation Quality"],
        "description": "Measures the proportion of ungrounded or fabricated facts in the response.",
    },
    {
        "metric_name": "Bias and Fairness",
        "metric_category": "Safety",
        "task_types": ["single_call", "tuning", "rag"],
        "focus_areas": ["Security and Guardrails", "Legal and Regulatory Compliance"],
        "description": "Measures absence of demographic, political, or cultural bias in the response.",
    },
    # Legal & Regulatory
    {
        "metric_name": "Regulatory Compliance",
        "metric_category": "Legal",
        "task_types": ["single_call", "tuning", "rag"],
        "focus_areas": ["Legal and Regulatory Compliance"],
        "description": "Measures adherence to applicable industry regulations and legal requirements.",
    },
    {
        "metric_name": "Legal Accuracy",
        "metric_category": "Legal",
        "task_types": ["single_call", "tuning", "rag"],
        "focus_areas": ["Legal and Regulatory Compliance", "Content Generation Quality"],
        "description": "Measures correctness of legal citations, statutes, and interpretations.",
    },
    {
        "metric_name": "Disclaimer Appropriateness",
        "metric_category": "Legal",
        "task_types": ["single_call", "tuning", "rag"],
        "focus_areas": ["Legal and Regulatory Compliance", "User Experience"],
        "description": "Measures whether appropriate disclaimers and caveats are included when required.",
    },
    # Performance & Cost
    {
        "metric_name": "Token Efficiency",
        "metric_category": "Performance",
        "task_types": ["single_call", "tuning", "rag"],
        "focus_areas": ["Performance, Cost and Operations"],
        "description": "Measures information density — how much useful content is conveyed per token used.",
    },
    {
        "metric_name": "Response Length Appropriateness",
        "metric_category": "Performance",
        "task_types": ["single_call", "tuning", "rag"],
        "focus_areas": ["Performance, Cost and Operations", "User Experience"],
        "description": "Measures whether response length is calibrated appropriately to the complexity of the query.",
    },
    # Data Quality
    {
        "metric_name": "Format Compliance",
        "metric_category": "Data Quality",
        "task_types": ["single_call", "tuning"],
        "focus_areas": ["Data and Dataset Related", "Content Generation Quality"],
        "description": "Measures adherence to required output format (JSON, markdown, structured text, etc.).",
    },
    {
        "metric_name": "Dataset Consistency",
        "metric_category": "Data Quality",
        "task_types": ["tuning"],
        "focus_areas": ["Data and Dataset Related"],
        "description": "Measures whether the model output aligns with patterns expected from the training dataset.",
    },
    # Domain-specific: Healthcare
    {
        "metric_name": "Clinical Accuracy",
        "metric_category": "Domain: Healthcare",
        "task_types": ["single_call", "tuning", "rag"],
        "focus_areas": ["Content Generation Quality", "Legal and Regulatory Compliance"],
        "description": "Measures correctness of medical information against clinical guidelines and evidence-based medicine.",
        "domains": ["healthcare", "medical", "health", "clinical"],
    },
    {
        "metric_name": "Medical Safety",
        "metric_category": "Domain: Healthcare",
        "task_types": ["single_call", "tuning", "rag"],
        "focus_areas": ["Security and Guardrails", "Legal and Regulatory Compliance"],
        "description": "Measures absence of dangerous medical advice, incorrect dosages, or contraindication omissions.",
        "domains": ["healthcare", "medical", "health", "clinical"],
    },
    # Domain-specific: Legal
    {
        "metric_name": "Case Law Relevance",
        "metric_category": "Domain: Legal",
        "task_types": ["single_call", "rag"],
        "focus_areas": ["Content Generation Quality", "Legal and Regulatory Compliance"],
        "description": "Measures accuracy of legal precedent citations and applicability to the scenario.",
        "domains": ["legal", "law", "compliance"],
    },
    # Domain-specific: Finance
    {
        "metric_name": "Numerical Accuracy",
        "metric_category": "Domain: Finance",
        "task_types": ["single_call", "tuning", "rag"],
        "focus_areas": ["Content Generation Quality", "Legal and Regulatory Compliance"],
        "description": "Measures correctness of financial calculations, ratios, and quantitative claims.",
        "domains": ["finance", "financial", "banking", "investment"],
    },
    {
        "metric_name": "Risk Disclosure",
        "metric_category": "Domain: Finance",
        "task_types": ["single_call", "tuning", "rag"],
        "focus_areas": ["Legal and Regulatory Compliance", "Security and Guardrails"],
        "description": "Measures completeness of risk warnings and compliance with financial disclosure requirements.",
        "domains": ["finance", "financial", "banking", "investment"],
    },
    # Domain-specific: Education
    {
        "metric_name": "Pedagogical Clarity",
        "metric_category": "Domain: Education",
        "task_types": ["single_call", "tuning"],
        "focus_areas": ["Content Generation Quality", "User Experience"],
        "description": "Measures how well explanations are structured for learning — use of examples, scaffolding, clarity.",
        "domains": ["education", "learning", "teaching", "academic"],
    },
]

# ── Focus-area weight multipliers ──────────────────────────────────────────────

_FOCUS_AREA_CATEGORY_MAP = {
    "Security and Guardrails": ["Safety"],
    "Legal and Regulatory Compliance": ["Legal"],
    "Content Generation Quality": ["RAG Quality", "Fine-tuning Quality", "Generation Quality"],
    "Performance, Cost and Operations": ["Performance"],
    "User Experience": ["User Experience"],
    "Data and Dataset Related": ["Data Quality", "Fine-tuning Quality"],
}


async def get_candidate_metrics(
    task_type: str,
    focus_areas: list[str],
    domain: str,
) -> dict:
    """Return candidate evaluation metrics for a given task type, focus areas, and domain.

    Args:
        task_type: One of 'rag', 'tuning', 'single_call'.
        focus_areas: List of selected focus areas (up to 3).
        domain: The domain string (e.g. 'Healthcare', 'Legal').

    Returns:
        A dict with key 'metrics' containing a list of candidate metric dicts.
    """
    domain_lower = domain.lower()
    task_type_norm = task_type.lower()

    # Priority categories derived from focus areas
    priority_categories = set()
    for fa in focus_areas:
        priority_categories.update(_FOCUS_AREA_CATEGORY_MAP.get(fa, []))

    candidates = []
    for m in _METRIC_LIBRARY:
        # Task type filter
        if task_type_norm not in [t.lower() for t in m["task_types"]]:
            continue

        # Domain filter — domain-specific metrics only show if domain matches
        metric_domains = m.get("domains", [])
        if metric_domains and not any(d in domain_lower for d in metric_domains):
            continue

        # Score by relevance
        relevance = 0
        if m["metric_category"] in priority_categories:
            relevance += 2
        for fa in focus_areas:
            if fa in m["focus_areas"]:
                relevance += 1

        candidates.append({**m, "relevance_score": relevance})

    # Sort by relevance then name; cap at 12 candidates to avoid overwhelming the agent
    candidates.sort(key=lambda x: (-x["relevance_score"], x["metric_name"]))
    top = candidates[:12]

    # Clean output — remove internal fields
    clean = [
        {
            "metric_name": c["metric_name"],
            "metric_category": c["metric_category"],
            "description": c["description"],
            "relevance_score": c["relevance_score"],
        }
        for c in top
    ]

    logger.debug("Metric library returned %d candidates for task_type=%s domain=%s", len(clean), task_type, domain)
    return {"metrics": clean}


__all__ = ["get_candidate_metrics"]
