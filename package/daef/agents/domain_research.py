import logging
from google.adk.agents import LlmAgent
from google.adk.tools import google_search
from google.genai.types import GenerateContentConfig

logger = logging.getLogger(__name__)

_MODEL = "gemini-2.5-flash"

_INSTRUCTION = """You are a domain research specialist for LLM evaluation systems.

Your job: research evaluation standards relevant to a specific domain and task.

INPUT (from session state):
{evaluation_input}

TASK:
1. Use the google_search tool to find domain-specific LLM/AI evaluation standards and best practices.
   - Search query example: "[domain] LLM evaluation standards best practices"
   - Search once or twice maximum — do not over-search.
2. Synthesize findings into a compact research summary.

OUTPUT — respond with ONLY this JSON object, no markdown, no explanation:
{
  "domain_standards": ["<standard or regulation relevant to domain>", ...],
  "key_requirements": ["<must-have quality requirement>", ...],
  "evaluation_priorities": ["<what matters most when evaluating LLM output in this domain>", ...],
  "risk_areas": ["<specific risk or failure mode in this domain>", ...],
  "domain_context": "<2-3 sentence summary of what makes LLM evaluation in this domain unique>"
}

Keep each list to 3-5 items. Be specific to the domain — avoid generic statements."""

domain_research_agent = LlmAgent(
    name="DomainResearchAgent",
    model=_MODEL,
    description=(
        "Researches domain-specific LLM evaluation standards, regulations, and best practices "
        "for a given domain (e.g. Healthcare, Legal, Finance). Uses web search to find current "
        "industry standards and returns a structured research summary."
    ),
    instruction=_INSTRUCTION,
    tools=[google_search],
    output_key="domain_research",
    include_contents="none",
    disallow_transfer_to_parent=True,
    generate_content_config=GenerateContentConfig(temperature=0.1),
)

__all__ = ["domain_research_agent"]
