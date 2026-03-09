import logging
from google.adk.tools import google_search

logger = logging.getLogger(__name__)

# google_search is ADK's built-in Google Search grounding tool.
# It uses Gemini's native search grounding — no extra API key required beyond GOOGLE_API_KEY.
# Pass it directly in tools=[google_search] on any LlmAgent.

web_search_tool = google_search

__all__ = ["web_search_tool"]
