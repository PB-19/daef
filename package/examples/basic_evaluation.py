"""
Basic single-call LLM evaluation example.
"""
import asyncio
from daef import DAEFClient, EvaluationRequest


async def main():
    client = DAEFClient()  # reads GOOGLE_API_KEY from environment

    request = EvaluationRequest(
        domain="Healthcare",
        task_description="Medical Q&A chatbot answering patient questions about medication",
        task_type="single_call",
        focus_areas=["Security and Guardrails", "Content Generation Quality"],
        prompt="What is the recommended dosage of ibuprofen for adults?",
        llm_output=(
            "The standard adult dose of ibuprofen is 200-400mg every 4-6 hours as needed, "
            "with a maximum of 1200mg per day for OTC use. Take with food or milk to reduce "
            "stomach upset. Do not exceed the recommended dose without consulting a doctor. "
            "Avoid if you have kidney disease, stomach ulcers, or are taking blood thinners."
        ),
    )

    print("Running evaluation...")
    result = await client.evaluate(request)

    print(f"Overall Score: {result.overall_score}/100")
    print(f"Summary: {result.summary}")
    print(f"Metrics:")
    for m in result.metrics:
        print(f"  {m.metric_name}: {m.score}/100 (weight: {m.weight})")
        print(f"    {m.reasoning}")
    print(f"Agent Insights:{result.agent_insights}")


if __name__ == "__main__":
    asyncio.run(main())
