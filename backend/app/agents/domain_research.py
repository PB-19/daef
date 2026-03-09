import logging
from google.adk.agents import LlmAgent
from google.genai.types import GenerateContentConfig

from app.agents.tools.web_search import web_search_tool
from app.agents.utils.prompt_templates import DOMAIN_RESEARCH_INSTRUCTION

logger = logging.getLogger(__name__)

_MODEL = "gemini-2.0-flash"

domain_research_agent = LlmAgent(
    name="DomainResearchAgent",
    model=_MODEL,
    description=(
        "Researches domain-specific LLM evaluation standards, regulations, and best practices "
        "for a given domain (e.g. Healthcare, Legal, Finance). Uses web search to find current "
        "industry standards and returns a structured research summary."
    ),
    instruction=DOMAIN_RESEARCH_INSTRUCTION,
    tools=[web_search_tool],
    output_key="domain_research",
    include_contents="none",
    disallow_transfer_to_parent=True,
    generate_content_config=GenerateContentConfig(
        temperature=0.1,
        max_output_tokens=900,
    ),
)

__all__ = ["domain_research_agent"]
