"""
RAG pipeline evaluation example.
"""
import asyncio
from daef import DAEFClient, EvaluationRequest


async def main():
    client = DAEFClient()

    request = EvaluationRequest(
        domain="Legal",
        task_description="Legal document Q&A system for contract review",
        task_type="rag",
        focus_areas=["Legal and Regulatory Compliance", "Content Generation Quality"],
        context_data=(
            "Section 12.3: Either party may terminate this agreement with 30 days written notice. "
            "Section 12.4: Termination for cause requires material breach and 10 days cure period. "
            "Section 15.1: Governing law shall be the State of California."
        ),
        prompt="How many days notice is required to terminate this contract?",
        llm_output=(
            "According to Section 12.3, either party may terminate the agreement with 30 days "
            "written notice. If terminating for cause due to material breach, Section 12.4 requires "
            "a 10-day cure period before termination can be effected."
        ),
        mandatory_metrics=["Faithfulness", "Answer Relevancy"],
        avoided_metrics=["Toxicity"],
    )

    print("Running RAG evaluation...")
    result = await client.evaluate(request)

    print(f"Overall Score: {result.overall_score}/100")
    print(f"Summary: {result.summary}")
    print(f"Metrics:")
    for m in result.metrics:
        print(f"  {m.metric_name}: {m.score}/100")
    print(f"Agent Insights:{result.agent_insights}")


if __name__ == "__main__":
    asyncio.run(main())
