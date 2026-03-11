import pytest
from unittest.mock import AsyncMock, patch
from daef import DAEFClient, EvaluationRequest, EvaluationResult, ComparisonResult


MOCK_EVAL_RESULT = {
    "overall_score": 82.5,
    "summary": "Strong response with minor gaps in regulatory coverage.",
    "metrics": [
        {
            "metric_name": "Hallucination Rate",
            "metric_category": "Safety",
            "score": 88.0,
            "max_score": 100.0,
            "weight": 0.4,
            "reasoning": "No hallucinated facts detected.",
        },
        {
            "metric_name": "Helpfulness",
            "metric_category": "User Experience",
            "score": 75.0,
            "max_score": 100.0,
            "weight": 0.6,
            "reasoning": "Response is actionable and clear.",
        },
    ],
    "agent_insights": "Consider adding domain-specific disclaimers.",
    "scoring_guides": {"Hallucination Rate": "High score = no hallucinations"},
}

MOCK_COMPARISON_RESULT = {
    "metric_comparisons": [
        {
            "metric_name": "Hallucination Rate",
            "base_score": 60.0,
            "new_score": 88.0,
            "change": 28.0,
            "analysis": "Improved factual grounding in new version.",
        }
    ],
    "overall_change": "better",
    "key_improvements": ["Better factual accuracy"],
    "key_regressions": [],
    "summary": "New version shows significant improvement.",
    "recommendation": "Deploy new version to production.",
}


@pytest.fixture
def request_fixture():
    return EvaluationRequest(
        domain="Healthcare",
        task_description="Medical Q&A chatbot",
        task_type="single_call",
        focus_areas=["Security and Guardrails"],
        prompt="What is a safe aspirin dose?",
        llm_output="Standard adult dose is 325-650mg every 4 hours.",
    )


@pytest.mark.asyncio
async def test_evaluate_returns_result(request_fixture):
    with patch("daef.client.run_evaluation_pipeline", new_callable=AsyncMock) as mock_pipeline:
        mock_pipeline.return_value = MOCK_EVAL_RESULT

        client = DAEFClient(api_key="fake-key")
        result = await client.evaluate(request_fixture)

    assert isinstance(result, EvaluationResult)
    assert result.overall_score == 82.5
    assert len(result.metrics) == 2
    assert result.metrics[0].metric_name == "Hallucination Rate"


@pytest.mark.asyncio
async def test_compare_returns_result(request_fixture):
    with patch("daef.client.run_evaluation_pipeline", new_callable=AsyncMock) as mock_pipeline:
        with patch("daef.client.run_comparison_pipeline", new_callable=AsyncMock) as mock_compare:
            mock_pipeline.return_value = MOCK_EVAL_RESULT
            mock_compare.return_value = MOCK_COMPARISON_RESULT

            client = DAEFClient(api_key="fake-key")
            base = await client.evaluate(request_fixture)
            new = await client.evaluate(request_fixture)
            comparison = await client.compare(base, new)

    assert isinstance(comparison, ComparisonResult)
    assert comparison.overall_change == "better"
    assert len(comparison.key_improvements) == 1


def test_client_raises_without_api_key(monkeypatch):
    monkeypatch.delenv("GOOGLE_API_KEY", raising=False)
    with pytest.raises(ValueError, match="GOOGLE_API_KEY"):
        DAEFClient()
