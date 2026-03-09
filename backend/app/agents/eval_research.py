import logging
from google.adk.agents import LlmAgent
from google.genai.types import GenerateContentConfig

from app.agents.tools.metric_library import metric_library_tool
from app.agents.utils.prompt_templates import EVAL_RESEARCH_INSTRUCTION

logger = logging.getLogger(__name__)

_MODEL = "gemini-2.0-flash"

eval_research_agent = LlmAgent(
    name="EvalResearchAgent",
    model=_MODEL,
    description=(
        "Selects the optimal set of evaluation metrics for an LLM task given domain research, "
        "task type, focus areas, and user-specified metric preferences (mandatory, avoided, custom). "
        "Uses the metric library tool to retrieve candidates and returns a weighted metric set."
    ),
    instruction=EVAL_RESEARCH_INSTRUCTION,
    tools=[metric_library_tool],
    output_key="selected_metrics",
    include_contents="none",
    disallow_transfer_to_parent=True,
    generate_content_config=GenerateContentConfig(
        temperature=0.1,
        max_output_tokens=900,
    ),
)

__all__ = ["eval_research_agent"]
