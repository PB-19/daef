class AppConstants {
  static const appName = 'DAEF';
  static const appTagline = 'Domain-Aware Evaluation Framework';
  static const apiBaseUrl = 'http://34.63.118.199:8000/api/v1';
  static const tokenKey = 'auth_token';
  static const themeModeKey = 'theme_mode';
  static const evalPollInterval = Duration(seconds: 5);
  static const maxFocusAreas = 3;
  static const maxRetries = 3;
}

class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const home = '/';
  static const evaluationDetail = '/evaluations/:id';
  static const createEvaluation = '/evaluations/create';
  static const comparisonDetail = '/comparisons/:id';
  static const postDetail = '/social/posts/:id';
  static const settings = '/settings';
  static const notifications = '/notifications';
  static const userProfile = '/profile/:userId';
}

class FocusAreas {
  static const all = [
    'Security and Guardrails',
    'Legal and Regulatory Compliance',
    'Content Generation Quality',
    'Performance, Cost and Operations',
    'User Experience',
    'Data and Dataset Related',
  ];

  static const icons = {
    'Security and Guardrails': '🔒',
    'Legal and Regulatory Compliance': '⚖️',
    'Content Generation Quality': '✨',
    'Performance, Cost and Operations': '⚡',
    'User Experience': '👤',
    'Data and Dataset Related': '📊',
  };
}

class Domains {
  static const predefined = [
    'Healthcare',
    'Finance',
    'Legal',
    'Education',
    'E-commerce',
    'Customer Support',
    'Software Engineering',
    'Marketing',
    'HR and Recruitment',
    'Research and Science',
    'Media and Entertainment',
    'Government and Public Sector',
  ];
}

class TaskTypes {
  static const rag = 'rag';
  static const tuning = 'tuning';
  static const singleCall = 'single_call';

  static const displayNames = {
    rag: 'RAG',
    tuning: 'Fine-tuning',
    singleCall: 'Single LLM Call',
  };

  static const descriptions = {
    rag: 'Retrieval-Augmented Generation pipeline',
    tuning: 'Fine-tuned model evaluation',
    singleCall: 'Direct prompt-response evaluation',
  };
}

class EvalStatus {
  static const pending = 'pending';
  static const processing = 'processing';
  static const completed = 'completed';
  static const failed = 'failed';
}

class NotifType {
  static const evalComplete = 'eval_complete';
  static const like = 'like';
  static const comment = 'comment';
}

class PerformanceChange {
  static const better = 'better';
  static const worse = 'worse';
  static const similar = 'similar';
}
