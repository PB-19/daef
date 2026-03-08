# DAEF - Domain-Aware Evaluation Framework

## 1. Idea Overview

DAEF is an intelligent LLM evaluation system that adapts to specific domains and task types. Instead of using generic evaluation metrics, it researches the domain, understands industry-specific requirements, and generates tailored evaluation criteria. The system uses a multi-agent architecture powered by Google's Agent Development Kit to orchestrate domain research, metric selection, and comprehensive evaluation.

Available as both a **PyPI package** for developers and a **Flutter mobile app** for general users, DAEF makes sophisticated LLM evaluation accessible to everyone while maintaining the flexibility needed for technical users.

---

## 2. End-to-End Flow

### Input Phase
1. **User selects domain** - Choose from predefined options or specify custom domain
2. **Provide task description** - Text input with optional file attachments (PDF/TXT)
3. **Choose task type** - RAG, Fine-tuning, or Single LLM call
4. **Select focus areas** - Pick up to 3 aspects to prioritize:
   - Security and Guardrails
   - Legal and Regulatory Compliance
   - Content Generation Quality
   - Performance, Cost and Operations
   - User Experience
   - Data and Dataset Related
5. **Define metric preferences** - Specify:
   - Mandatory metrics to include
   - Metrics to avoid
   - Custom metrics with descriptions
6. **Submit for evaluation** - Provide:
   - The prompt used
   - LLM output received
   - Context/ground truth (if applicable)

### Processing Phase
The multi-agent system processes the request:
- **OrchestratorAgent** structures the input and coordinates agent workflow
- **DomainResearchAgent** researches industry standards and best practices
- **EvalResearchAgent** curates the optimal evaluation metrics
- **EvaluatorAgent** performs the actual evaluation with detailed scoring

### Output Phase
Receive a comprehensive evaluation report with:
- Individual metric scores with justifications
- Weighted overall score based on selected focus areas
- Domain-specific insights and recommendations

### Additional Features
- **Save evaluations** for future reference and comparison
- **Version tracking** to compare iterations of the same task
- **EvalCompareAgent** analyzes differences between evaluation versions
- **Social features** to share exceptional results with the community
- **Leaderboards** showcasing top evaluations by score, likes, and engagement

---

## 3. Agents Planned

| Agent | Purpose |
|-------|---------|
| **OrchestratorAgent** | Parses user input and coordinates the agent workflow |
| **DomainResearchAgent** | Researches domain-specific standards and evaluation practices |
| **EvalResearchAgent** | Curates optimal metric set based on task type and user preferences |
| **EvaluatorAgent** | Performs evaluation with detailed scoring and reasoning |
| **EvalCompareAgent** | Compares evaluation versions and explains performance differences |

---

## 4. Tech Stack

**Backend:**
- Python FastAPI (async)
- Google Agent Development Kit (ADK) for multi-agent orchestration
- MySQL with aiomysql for database + SQLAlchemy for ORM
- Redis for caching and session management

**Frontend:**
- Flutter (cross-platform mobile app)

**AI/LLM:**
- Gemini/Vertex AI via Google's ADK framework

**Storage:**
- Google Cloud Storage (GCS) for file uploads

**Distribution:**
- PyPI package for developer integration
- Mobile app for general users

---

## 5. Key Considerations

### Performance & Architecture
- **Async everywhere** - FastAPI async, aiomysql, async agent execution
- **Polling-based notifications** - Simple DB-backed notification system for MVP scale
- **Background task execution** - Long-running evaluations don't block user experience
- **Agent retry logic** - Maximum 3 retries on ADK failures to conserve API usage

### Security & Privacy
- **User-provided API keys** - Users bring their own Gemini API keys (encrypted in DB for app users, env variables for package users)
- **Selective sharing** - Users choose which evaluations to post publicly
- **No external auth complexity** - OAuth2/JWT handled entirely in backend

### Data Management
- **Separate tables** - Evaluations (private) vs Social Posts (public) for clean data separation
- **GCS for file storage** - PDFs/documents stored in cloud, not bloating database
- **No persistent agent outputs** - Intermediate JSON only lives during request lifecycle unless needed for debugging

### Social Features
- **Four leaderboards** - Recent, Most Liked, Most Commented, Highest Score
- **Weighted scoring** - Overall score combines user focus areas + agent-determined importance
- **Version comparison** - EvalCompareAgent provides insights, not just raw diff

### Scope Management (MVP/POC)
- **3-5 dummy users** for testing complete functionality
- **No content moderation** initially - focus on core evaluation pipeline
- **No real-time features** - polling is sufficient for notification delivery
- **Package scope** - Evaluation pipeline only, no social features in PyPI distribution

---

## Distribution Model

**PyPI Package (`daef`):**
- Import and use evaluation pipeline programmatically
- Users manage their own API keys via environment variables
- Returns structured evaluation JSON
- No UI, social features, or persistence

**Flutter Mobile App:**
- Full-featured UI with social capabilities
- API key management in encrypted settings
- Save, compare, and share evaluations
- Profile management and notifications

---

*This is a proof-of-concept to validate the domain-aware evaluation approach. All functionality is production-ready, using realistic dummy data for demonstration purposes.*