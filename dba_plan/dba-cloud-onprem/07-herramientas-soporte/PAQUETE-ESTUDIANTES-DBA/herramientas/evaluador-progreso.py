#!/usr/bin/env python3
"""
Sistema de Evaluación Automatizada para Escenarios de Diagnóstico
Programa DBA Cloud OnPrem Junior
"""

import json
import time
import datetime
import subprocess
import os
import sys
from pathlib import Path
from typing import Dict, List, Any, Optional
import yaml

class ScenarioEvaluator:
    def __init__(self, scenario_path: str):
        self.scenario_path = Path(scenario_path)
        self.scenario_name = self.scenario_path.name
        self.start_time = None
        self.end_time = None
        self.score = 0
        self.max_score = 100
        self.hints_used = 0
        self.evaluation_log = []
        
        # Cargar configuración del escenario
        self.config = self._load_scenario_config()
        
    def _load_scenario_config(self) -> Dict[str, Any]:
        """Carga la configuración del escenario"""
        config_file = self.scenario_path / "evaluacion-config.yml"
        
        if config_file.exists():
            with open(config_file, 'r', encoding='utf-8') as f:
                return yaml.safe_load(f)
        else:
            # Configuración por defecto
            return {
                'time_limit_minutes': 45,
                'max_hints': 3,
                'hint_penalty': 10,
                'criteria': {
                    'root_cause_identification': 30,
                    'quick_fix_implementation': 25,
                    'definitive_solution': 25,
                    'results_verification': 10,
                    'documentation': 10
                },
                'success_metrics': {},
                'automated_checks': []
            }
    
    def start_evaluation(self):
        """Inicia la evaluación del escenario"""
        self.start_time = datetime.datetime.now()
        print(f"🎯 Iniciando evaluación del escenario: {self.scenario_name}")
        print(f"⏰ Tiempo límite: {self.config['time_limit_minutes']} minutos")
        print(f"🎯 Puntuación máxima: {self.max_score} puntos")
        print("=" * 60)
        
        self._log_event("evaluation_started", {
            "scenario": self.scenario_name,
            "start_time": self.start_time.isoformat(),
            "time_limit": self.config['time_limit_minutes']
        })
    
    def end_evaluation(self):
        """Finaliza la evaluación del escenario"""
        self.end_time = datetime.datetime.now()
        duration = self.end_time - self.start_time
        duration_minutes = duration.total_seconds() / 60
        
        # Penalización por tiempo excedido
        if duration_minutes > self.config['time_limit_minutes']:
            overtime = duration_minutes - self.config['time_limit_minutes']
            time_penalty = int(overtime / 5) * 5  # 5 puntos por cada 5 minutos extra
            self.score = max(0, self.score - time_penalty)
            self._log_event("time_penalty", {
                "overtime_minutes": overtime,
                "penalty": time_penalty
            })
        
        # Penalización por pistas utilizadas
        hint_penalty = self.hints_used * self.config['hint_penalty']
        self.score = max(0, self.score - hint_penalty)
        
        self._log_event("evaluation_completed", {
            "end_time": self.end_time.isoformat(),
            "duration_minutes": duration_minutes,
            "hints_used": self.hints_used,
            "hint_penalty": hint_penalty,
            "final_score": self.score
        })
        
        self._generate_report()
    
    def use_hint(self, hint_number: int):
        """Registra el uso de una pista"""
        if self.hints_used < self.config['max_hints']:
            self.hints_used += 1
            self._log_event("hint_used", {
                "hint_number": hint_number,
                "total_hints_used": self.hints_used,
                "penalty": self.config['hint_penalty']
            })
            print(f"💡 Pista {hint_number} utilizada (-{self.config['hint_penalty']} puntos)")
            return True
        else:
            print(f"❌ No hay más pistas disponibles")
            return False
    
    def check_root_cause_identification(self, student_answer: str) -> int:
        """Evalúa la identificación de la causa raíz"""
        points = 0
        max_points = self.config['criteria']['root_cause_identification']
        
        # Aquí iría la lógica específica de evaluación
        # Por ahora, simulamos una evaluación básica
        
        keywords = self.config.get('root_cause_keywords', [])
        if keywords:
            found_keywords = sum(1 for keyword in keywords if keyword.lower() in student_answer.lower())
            points = int((found_keywords / len(keywords)) * max_points)
        else:
            # Evaluación manual requerida
            points = self._manual_evaluation("Identificación de causa raíz", max_points)
        
        self._log_event("root_cause_evaluated", {
            "points_awarded": points,
            "max_points": max_points,
            "student_answer": student_answer[:200] + "..." if len(student_answer) > 200 else student_answer
        })
        
        return points
    
    def check_quick_fix(self) -> int:
        """Evalúa la implementación del quick fix"""
        points = 0
        max_points = self.config['criteria']['quick_fix_implementation']
        
        # Ejecutar verificaciones automatizadas
        for check in self.config.get('quick_fix_checks', []):
            if self._run_automated_check(check):
                points += check.get('points', 5)
        
        points = min(points, max_points)
        
        self._log_event("quick_fix_evaluated", {
            "points_awarded": points,
            "max_points": max_points
        })
        
        return points
    
    def check_definitive_solution(self) -> int:
        """Evalúa la solución definitiva"""
        points = 0
        max_points = self.config['criteria']['definitive_solution']
        
        # Ejecutar verificaciones automatizadas
        for check in self.config.get('definitive_solution_checks', []):
            if self._run_automated_check(check):
                points += check.get('points', 5)
        
        points = min(points, max_points)
        
        self._log_event("definitive_solution_evaluated", {
            "points_awarded": points,
            "max_points": max_points
        })
        
        return points
    
    def check_results_verification(self) -> int:
        """Evalúa la verificación de resultados"""
        points = 0
        max_points = self.config['criteria']['results_verification']
        
        # Verificar métricas de éxito
        success_metrics = self.config.get('success_metrics', {})
        if success_metrics:
            met_metrics = 0
            for metric, target in success_metrics.items():
                if self._check_metric(metric, target):
                    met_metrics += 1
            
            if success_metrics:
                points = int((met_metrics / len(success_metrics)) * max_points)
        else:
            points = self._manual_evaluation("Verificación de resultados", max_points)
        
        self._log_event("results_verification_evaluated", {
            "points_awarded": points,
            "max_points": max_points
        })
        
        return points
    
    def check_documentation(self, documentation: str) -> int:
        """Evalúa la documentación"""
        points = 0
        max_points = self.config['criteria']['documentation']
        
        # Criterios básicos de documentación
        criteria_met = 0
        total_criteria = 5
        
        if len(documentation) >= 200:  # Longitud mínima
            criteria_met += 1
        
        if "causa raíz" in documentation.lower() or "root cause" in documentation.lower():
            criteria_met += 1
        
        if "solución" in documentation.lower() or "solution" in documentation.lower():
            criteria_met += 1
        
        if "resultado" in documentation.lower() or "result" in documentation.lower():
            criteria_met += 1
        
        if "lección" in documentation.lower() or "lesson" in documentation.lower():
            criteria_met += 1
        
        points = int((criteria_met / total_criteria) * max_points)
        
        self._log_event("documentation_evaluated", {
            "points_awarded": points,
            "max_points": max_points,
            "criteria_met": criteria_met,
            "total_criteria": total_criteria
        })
        
        return points
    
    def _run_automated_check(self, check: Dict[str, Any]) -> bool:
        """Ejecuta una verificación automatizada"""
        check_type = check.get('type')
        
        if check_type == 'docker_container_status':
            return self._check_container_status(check.get('container_name'))
        elif check_type == 'database_query':
            return self._check_database_query(check.get('query'), check.get('expected_result'))
        elif check_type == 'metric_threshold':
            return self._check_metric_threshold(check.get('metric'), check.get('threshold'))
        elif check_type == 'file_exists':
            return self._check_file_exists(check.get('file_path'))
        elif check_type == 'log_pattern':
            return self._check_log_pattern(check.get('log_file'), check.get('pattern'))
        
        return False
    
    def _check_container_status(self, container_name: str) -> bool:
        """Verifica el estado de un contenedor"""
        try:
            result = subprocess.run(
                ['docker', 'ps', '--filter', f'name={container_name}', '--format', '{{.Status}}'],
                capture_output=True, text=True, cwd=self.scenario_path
            )
            return 'Up' in result.stdout
        except:
            return False
    
    def _check_database_query(self, query: str, expected_result: Any) -> bool:
        """Ejecuta una consulta de base de datos y verifica el resultado"""
        # Implementación específica según el tipo de base de datos
        # Por ahora retorna True como placeholder
        return True
    
    def _check_metric_threshold(self, metric: str, threshold: float) -> bool:
        """Verifica que una métrica esté dentro del umbral"""
        # Implementación específica para obtener métricas
        # Por ahora retorna True como placeholder
        return True
    
    def _check_file_exists(self, file_path: str) -> bool:
        """Verifica que un archivo existe"""
        return (self.scenario_path / file_path).exists()
    
    def _check_log_pattern(self, log_file: str, pattern: str) -> bool:
        """Busca un patrón en un archivo de log"""
        try:
            log_path = self.scenario_path / log_file
            if log_path.exists():
                with open(log_path, 'r') as f:
                    content = f.read()
                    return pattern in content
        except:
            pass
        return False
    
    def _check_metric(self, metric: str, target: Any) -> bool:
        """Verifica una métrica específica"""
        # Implementación específica según el tipo de métrica
        return True
    
    def _manual_evaluation(self, criteria: str, max_points: int) -> int:
        """Solicita evaluación manual"""
        print(f"\n📝 Evaluación manual requerida para: {criteria}")
        print(f"Puntuación máxima: {max_points} puntos")
        
        while True:
            try:
                points = int(input(f"Ingresa la puntuación (0-{max_points}): "))
                if 0 <= points <= max_points:
                    return points
                else:
                    print(f"❌ La puntuación debe estar entre 0 y {max_points}")
            except ValueError:
                print("❌ Ingresa un número válido")
    
    def _log_event(self, event_type: str, data: Dict[str, Any]):
        """Registra un evento en el log de evaluación"""
        event = {
            "timestamp": datetime.datetime.now().isoformat(),
            "event_type": event_type,
            "data": data
        }
        self.evaluation_log.append(event)
    
    def _generate_report(self):
        """Genera el reporte final de evaluación"""
        duration = self.end_time - self.start_time
        duration_minutes = duration.total_seconds() / 60
        
        report = {
            "scenario": self.scenario_name,
            "student_info": {
                "start_time": self.start_time.isoformat(),
                "end_time": self.end_time.isoformat(),
                "duration_minutes": round(duration_minutes, 2),
                "time_limit_minutes": self.config['time_limit_minutes']
            },
            "scoring": {
                "final_score": self.score,
                "max_score": self.max_score,
                "percentage": round((self.score / self.max_score) * 100, 1),
                "hints_used": self.hints_used,
                "hint_penalty": self.hints_used * self.config['hint_penalty']
            },
            "evaluation_log": self.evaluation_log,
            "generated_at": datetime.datetime.now().isoformat()
        }
        
        # Guardar reporte
        reports_dir = Path("reports")
        reports_dir.mkdir(exist_ok=True)
        
        timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
        report_file = reports_dir / f"evaluacion_{self.scenario_name}_{timestamp}.json"
        
        with open(report_file, 'w', encoding='utf-8') as f:
            json.dump(report, f, indent=2, ensure_ascii=False)
        
        # Mostrar resumen
        self._print_summary(report)
        
        print(f"\n📄 Reporte completo guardado en: {report_file}")
    
    def _print_summary(self, report: Dict[str, Any]):
        """Imprime el resumen de la evaluación"""
        print("\n" + "=" * 60)
        print("🏆 RESUMEN DE EVALUACIÓN")
        print("=" * 60)
        
        print(f"📋 Escenario: {report['scenario']}")
        print(f"⏱️  Duración: {report['student_info']['duration_minutes']:.1f} minutos")
        print(f"💡 Pistas utilizadas: {report['scoring']['hints_used']}")
        print(f"🎯 Puntuación final: {report['scoring']['final_score']}/{report['scoring']['max_score']} ({report['scoring']['percentage']}%)")
        
        # Clasificación
        percentage = report['scoring']['percentage']
        if percentage >= 90:
            grade = "🥇 EXCELENTE"
        elif percentage >= 80:
            grade = "🥈 MUY BUENO"
        elif percentage >= 70:
            grade = "🥉 BUENO"
        elif percentage >= 60:
            grade = "✅ APROBADO"
        else:
            grade = "❌ NECESITA MEJORAR"
        
        print(f"📊 Calificación: {grade}")
        print("=" * 60)

def main():
    if len(sys.argv) != 2:
        print("Uso: python evaluador-automatico.py <ruta_del_escenario>")
        print("Ejemplo: python evaluador-automatico.py mysql/escenario-01-deadlocks")
        sys.exit(1)
    
    scenario_path = sys.argv[1]
    
    if not os.path.exists(scenario_path):
        print(f"❌ Error: El escenario '{scenario_path}' no existe")
        sys.exit(1)
    
    evaluator = ScenarioEvaluator(scenario_path)
    
    print("🎓 Sistema de Evaluación Automatizada")
    print("Programa DBA Cloud OnPrem Junior")
    print()
    
    # Ejemplo de uso del evaluador
    evaluator.start_evaluation()
    
    # Simular evaluación (en uso real, esto sería interactivo)
    print("⏳ Evaluación en progreso...")
    time.sleep(2)
    
    # Aquí irían las evaluaciones reales
    evaluator.score += evaluator.check_root_cause_identification("Ejemplo de respuesta del estudiante")
    evaluator.score += evaluator.check_quick_fix()
    evaluator.score += evaluator.check_definitive_solution()
    evaluator.score += evaluator.check_results_verification()
    evaluator.score += evaluator.check_documentation("Documentación de ejemplo del estudiante")
    
    evaluator.end_evaluation()

if __name__ == "__main__":
    main()
