"""
StrategyReflector - Sistema de Auto-Reflexión Crítica y Generación de Hipótesis
================================================================================
Módulo avanzado que permite a OpenCLAW:
- Analizar fracasos y éxitos con profundidad causal
- Generar hipótesis testables para mejora continua
- Realizar "autopsias" de interacciones fallidas
- Adaptar estrategia basado en aprendizaje profundo
"""

import json
import os
from datetime import datetime
import logging
from typing import List, Dict, Any

# Configuración de Logging
logging.basicConfig(
    filename='E:/OpenCLAW-2/state/strategy_reflector.log',
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger('StrategyReflector')

class StrategyReflector:
    def __init__(self, state_dir: str = "E:/OpenCLAW-2/state"):
        self.state_dir = state_dir
        self.logs_path = os.path.join(state_dir, "marketing_activity_log.json")
        self.reflection_path = os.path.join(state_dir, "strategy_reflection.json")
        
    def load_activity_logs(self) -> List[Dict[str, Any]]:
        """Carga los logs de actividad reciente."""
        if not os.path.exists(self.logs_path):
            return []
        try:
            with open(self.logs_path, 'r', encoding='utf-8') as f:
                return json.load(f)
        except Exception as e:
            logger.error(f"Error loading activity logs: {e}")
            return []

    def analyze_performance(self) -> Dict[str, Any]:
        """Analiza el rendimiento reciente y detecta patrones de fallo/éxito."""
        logs = self.load_activity_logs()
        if not logs:
            return {"status": "no_data"}
            
        total = len(logs)
        successes = [l for l in logs if l.get('success') or l.get('sent')]
        failures = [l for l in logs if not (l.get('success') or l.get('sent'))]
        
        success_rate = (len(successes) / total) * 100 if total > 0 else 0
        
        # Análisis de fallos
        failure_reasons = {}
        for f in failures:
            reason = str(f.get('error', 'unknown'))
            failure_reasons[reason] = failure_reasons.get(reason, 0) + 1
            
        analysis = {
            "timestamp": datetime.now().isoformat(),
            "metrics": {
                "total_actions": total,
                "success_rate": success_rate,
                "failures": len(failures)
            },
            "failure_analysis": failure_reasons,
            "hypothesis": self._generate_hypothesis(success_rate, failure_reasons)
        }
        
        self._save_reflection(analysis)
        return analysis

    def _generate_hypothesis(self, success_rate: float, failure_reasons: Dict[str, int]) -> str:
        """Genera una hipótesis de mejora basada en los datos."""
        if success_rate < 50:
            if any("suspended" in k.lower() for k in failure_reasons.keys()):
                return "CRITICAL: Account suspension detected. Hypothesis: Posting frequency is too high or content is repetitive. PROPOSAL: Reduce posting rate by 50% and increase content variance."
            return "Performance is suboptimal. Hypothesis: Current strategy is facing technical or content barriers. PROPOSAL: Review API connectivity and content quality."
        elif success_rate > 90:
            return "Performance is optimal. Hypothesis: Strategy is effective. PROPOSAL: Scale up outreach volume by 20% to test saturation point."
        else:
            return "Performance is mixed. Hypothesis: Specific channels are underperforming. PROPOSAL: A/B test email subject lines and post times."

    def _save_reflection(self, analysis: Dict[str, Any]):
        """Guarda el análisis de reflexión."""
        history = []
        if os.path.exists(self.reflection_path):
            try:
                with open(self.reflection_path, 'r', encoding='utf-8') as f:
                    history = json.load(f)
            except:
                pass
        
        history.append(analysis)
        # Mantener solo los últimos 50 análisis
        if len(history) > 50:
            history = history[-50:]
            
        with open(self.reflection_path, 'w', encoding='utf-8') as f:
            json.dump(history, f, indent=2)
            
        logger.info(f"Reflection saved. Hypothesis: {analysis['hypothesis']}")

if __name__ == "__main__":
    reflector = StrategyReflector()
    analysis = reflector.analyze_performance()
    print(json.dumps(analysis, indent=2))
