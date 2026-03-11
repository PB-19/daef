import logging
from google.adk.agents import LlmAgent
from google.adk.tools import FunctionTool
from google.genai.types import GenerateContentConfig

from daef.agents._metric_library import get_candidate_metrics

logger = logging.getLogger(__name__)

_MODEL = "gemini-2.5-flash"

_INSTRUCTION = """You are an LLM evaluation metric specialist.

Your job: select the optimal set of evaluation metrics for a specific task, given domain research and user preferences.

INPUT (from session state):
Evaluation request: {evaluation_input}
Domain research: {domain_research}

TASK:
1. Call get_candidate_metrics with the task_type and focus_areas from the evaluation input.
2. Select 4-7 metrics that best fit this specific evaluation. Apply these rules:
   - ALWAYS include metrics listed in mandatory_metrics (from evaluation input).
   - NEVER include metrics listed in avoided_metrics.
   - Include any custom_metrics provided, treating them as user-defined metrics.
   - Weight metrics according to focus_areas — the first focus area gets the highest weight.
   - Weights must sum to exactly 1.0.
   - Prioritise domain-specific criteria surfaced by the domain research.

OUTPUT — respond with ONLY this JSON object, no markdown, no explanation:
{
  "selected_metrics": [
    {
      "metric_name": "<name>",
      "metric_category": "<category>",
      "weight": <0.0-1.0>,
      "scoring_guide": "<1-sentence rubric: what earns a high score vs low score>",
      "reasoning": "<why this metric matters for this specific task>"
    }
  ],
  "selection_rationale": "<1-2 sentences explaining the overall metric strategy>"
}

Weights must be floats summing to 1.0. Use 2 decimal places."""

_metric_library_tool = FunctionTool(func=get_candidate_metrics)

eval_research_agent = LlmAgent(
    name="EvalResearchAgent",
    model=_MODEL,
    description=(
        "Selects the optimal set of evaluation metrics for an LLM task given domain research, "
        "task type, focus areas, and user-specified metric preferences (mandatory, avoided, custom). "
        "Uses the metric library tool to retrieve candidates and returns a weighted metric set."
    ),
    instruction=_INSTRUCTION,
    tools=[_metric_library_tool],
    output_key="selected_metrics",
    include_contents="none",
    disallow_transfer_to_parent=True,
    generate_content_config=GenerateContentConfig(temperature=0.1),
)

__all__ = ["eval_research_agent"]
