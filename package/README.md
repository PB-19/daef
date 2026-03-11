# DAEF — Domain-Aware Evaluation Framework

Intelligent LLM evaluation that adapts to your domain. Instead of generic metrics, DAEF researches your domain, understands industry-specific requirements, and generates tailored evaluation criteria using a multi-agent pipeline powered by Google's Agent Development Kit.

## Installation

```bash
pip install daef
```

## Quick Start

```python
import asyncio
from daef import DAEFClient, EvaluationRequest

client = DAEFClient(api_key="YOUR_GOOGLE_API_KEY")

request = EvaluationRequest(
    domain="Healthcare",
    task_description="Medical Q&A chatbot answering patient questions",
    task_type="single_call",
    focus_areas=["Security and Guardrails", "Content Generation Quality"],
    prompt="What is the recommended dosage of ibuprofen for adults?",
    llm_output="The standard adult dose of ibuprofen is 200-400mg every 4-6 hours...",
)

result = asyncio.run(client.evaluate(request))
print(f"Overall Score: {result.overall_score}/100")
for metric in result.metrics:
    print(f"  {metric.metric_name}: {metric.score}/100")
```

## Features

- **Domain-aware**: Researches domain-specific standards (Healthcare, Legal, Finance, Education, and more)
- **Adaptive metrics**: Selects from 30+ built-in metrics and supports custom metrics
- **Task-type support**: RAG, Fine-tuning, Single LLM Call
- **Version comparison**: Compare two evaluation results to understand regressions and improvements
- **Async-first**: Built on asyncio for high-throughput pipelines

## Configuration

Set your Google API key via environment variable or constructor:

```bash
export GOOGLE_API_KEY="your-key"
```

```python
# Or pass directly
client = DAEFClient(api_key="your-key")
```

## EvaluationRequest Fields

| Field | Type | Required | Description |
|---|---|---|---|
| `domain` | str | Yes | Domain (e.g. "Healthcare", "Finance") |
| `task_description` | str | Yes | What the LLM task does |
| `task_type` | str | Yes | `"rag"`, `"tuning"`, or `"single_call"` |
| `focus_areas` | list[str] | No | Up to 3 priority areas |
| `prompt` | str | No | The input prompt sent to the LLM |
| `llm_output` | str | No | The LLM's response to evaluate |
| `context_data` | str | No | Retrieved context (for RAG) |
| `mandatory_metrics` | list[str] | No | Metrics that must be included |
| `avoided_metrics` | list[str] | No | Metrics to exclude |
| `custom_metrics` | list[str] | No | User-defined metric names |

## Version Comparison

```python
result_v1 = asyncio.run(client.evaluate(request_v1))
result_v2 = asyncio.run(client.evaluate(request_v2))

comparison = asyncio.run(client.compare(result_v1, result_v2))
print(f"Overall change: {comparison.overall_change}")
print(f"Summary: {comparison.summary}")
```

## License

MIT
