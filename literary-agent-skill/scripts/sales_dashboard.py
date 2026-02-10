#!/usr/bin/env python3
"""
Dashboard de ventas y análisis
Ubicación: ~/.openclaw/literary-agent/scripts/sales_dashboard.py
"""

import json
from datetime import datetime, timedelta
from collections import defaultdict
import os

class SalesDashboard:
    def __init__(self):
        self.base_dir = os.path.expanduser("~/.openclaw/literary-agent")
        self.reports_dir = os.path.join(self.base_dir, "reports")
        os.makedirs(self.reports_dir, exist_ok=True)
        
        self.data_file = os.path.join(self.reports_dir, "sales_data.json")
        self.kpi_file = os.path.join(self.reports_dir, "kpi_history.json")
        
        # Datos de ejemplo para demostración
        self.sample_books = {
            "B00PIPTRI8": {
                "title": "Things you shouldn't do if you want to be a writer",
                "genre": "Writing/Non-Fiction",
                "languages": ["ES", "EN"],
                "formats": ["ebook", "paperback", "audiobook"]
            },
            "B0CLQ2RJP3": {
                "title": "ApocalypsAI: The Day After AGI",
                "genre": "Science Fiction",
                "languages": ["ES", "EN", "FR"],
                "formats": ["ebook", "paperback", "audiobook"]
            },
            "B0CL2YJMH6": {
                "title": "La Invasión de las Medusas Mutantes",
                "genre": "Children's Illustrated",
                "languages": ["ES", "EN", "FR", "IT", "PT", "JP"],
                "formats": ["ebook", "paperback"]
            },
            "B0CHMQWSQB": {
                "title": "Eco-fuel-FA (ECOFA)",
                "genre": "Sustainability/Non-Fiction",
                "languages": ["ES", "EN"],
                "formats": ["ebook", "paperback"]
            }
        }
    
    def generate_daily_report(self, include_sample_data=True):
        """Genera reporte diario de ventas"""
        
        report = {
            "fecha_generacion": datetime.now().isoformat(),
            "periodo": {
                "inicio": (datetime.now() - timedelta(days=1)).strftime('%Y-%m-%d'),
                "fin": datetime.now().strftime('%Y-%m-%d')
            },
            "resumen_ejecutivo": {
                "ventas_totales_usd": 0,
                "unidades_vendidas": 0,
                "page_reads_ku": 0,
                "nuevas_reviews": 0,
                "libro_mas_vendido": "",
                "plataforma_top": ""
            },
            "por_plataforma": {
                "Amazon KDP": {"ventas_usd": 0, "unidades": 0, "page_reads": 0},
                "Apple Books": {"ventas_usd": 0, "unidades": 0},
                "Kobo": {"ventas_usd": 0, "unidades": 0},
                "Barnes & Noble": {"ventas_usd": 0, "unidades": 0},
                "Google Play": {"ventas_usd": 0, "unidades": 0}
            },
            "por_libro": {},
            "por_mercado": {
                "US": {"ventas_usd": 0, "unidades": 0},
                "UK": {"ventas_usd": 0, "unidades": 0},
                "ES": {"ventas_usd": 0, "unidades": 0},
                "MX": {"ventas_usd": 0, "unidades": 0},
                "FR": {"ventas_usd": 0, "unidades": 0},
                "DE": {"ventas_usd": 0, "unidades": 0},
                "IT": {"ventas_usd": 0, "unidades": 0},
                "JP": {"ventas_usd": 0, "unidades": 0}
            },
            "kpi_diarios": {
                "conversion_rate": 0,
                "average_order_value": 0,
                "customer_acquisition_cost": 0,
                "return_on_ad_spend": 0
            },
            "alertas": [],
            "recomendaciones": []
        }
        
        # Si se incluyen datos de ejemplo, poblar con datos simulados
        if include_sample_data:
            report = self._populate_sample_data(report)
        
        # Generar recomendaciones basadas en datos
        report["recomendaciones"] = self._generate_recommendations(report)
        
        # Detectar alertas
        report["alertas"] = self._detect_alerts(report)
        
        # Guardar reporte
        self._save_report(report, "daily")
        
        return report
    
    def _populate_sample_data(self, report):
        """Pobla el reporte con datos de ejemplo realistas"""
        import random
        
        # Simular ventas por plataforma
        platforms = {
            "Amazon KDP": {"ventas_usd": round(random.uniform(150, 400), 2), "unidades": random.randint(40, 100), "page_reads": random.randint(5000, 15000)},
            "Apple Books": {"ventas_usd": round(random.uniform(30, 80), 2), "unidades": random.randint(8, 20)},
            "Kobo": {"ventas_usd": round(random.uniform(20, 60), 2), "unidades": random.randint(5, 15)},
            "Barnes & Noble": {"ventas_usd": round(random.uniform(15, 50), 2), "unidades": random.randint(4, 12)},
            "Google Play": {"ventas_usd": round(random.uniform(25, 70), 2), "unidades": random.randint(6, 18)}
        }
        
        report["por_plataforma"] = platforms
        
        # Calcular totales
        total_ventas = sum(p["ventas_usd"] for p in platforms.values())
        total_unidades = sum(p["unidades"] for p in platforms.values())
        total_page_reads = platforms["Amazon KDP"]["page_reads"]
        
        report["resumen_ejecutivo"]["ventas_totales_usd"] = round(total_ventas, 2)
        report["resumen_ejecutivo"]["unidades_vendidas"] = total_unidades
        report["resumen_ejecutivo"]["page_reads_ku"] = total_page_reads
        report["resumen_ejecutivo"]["nuevas_reviews"] = random.randint(1, 5)
        report["resumen_ejecutivo"]["libro_mas_vendido"] = "Things you shouldn't do if you want to be a writer"
        report["resumen_ejecutivo"]["plataforma_top"] = "Amazon KDP"
        
        # Simular ventas por libro
        for asin, book in self.sample_books.items():
            report["por_libro"][asin] = {
                "titulo": book["title"],
                "ventas_usd": round(random.uniform(20, 150), 2),
                "unidades": random.randint(5, 35),
                "page_reads": random.randint(500, 4000) if "Amazon KDP" in platforms else 0,
                "bsr": random.randint(5000, 500000)
            }
        
        # Simular ventas por mercado
        markets = {
            "US": {"ventas_usd": round(total_ventas * 0.45, 2), "unidades": int(total_unidades * 0.45)},
            "UK": {"ventas_usd": round(total_ventas * 0.15, 2), "unidades": int(total_unidades * 0.15)},
            "ES": {"ventas_usd": round(total_ventas * 0.20, 2), "unidades": int(total_unidades * 0.20)},
            "MX": {"ventas_usd": round(total_ventas * 0.08, 2), "unidades": int(total_unidades * 0.08)},
            "FR": {"ventas_usd": round(total_ventas * 0.05, 2), "unidades": int(total_unidades * 0.05)},
            "DE": {"ventas_usd": round(total_ventas * 0.04, 2), "unidades": int(total_unidades * 0.04)},
            "IT": {"ventas_usd": round(total_ventas * 0.02, 2), "unidades": int(total_unidades * 0.02)},
            "JP": {"ventas_usd": round(total_ventas * 0.01, 2), "unidades": int(total_unidades * 0.01)}
        }
        
        report["por_mercado"] = markets
        
        # KPIs
        report["kpi_diarios"] = {
            "conversion_rate": round(random.uniform(2.5, 8.5), 2),
            "average_order_value": round(random.uniform(3.5, 6.5), 2),
            "customer_acquisition_cost": round(random.uniform(0.5, 2.5), 2),
            "return_on_ad_spend": round(random.uniform(2.0, 5.5), 2)
        }
        
        return report
    
    def _generate_recommendations(self, report):
        """Genera recomendaciones basadas en análisis de datos"""
        recommendations = []
        
        # Análisis de plataformas
        amazon_sales = report["por_plataforma"]["Amazon KDP"]["ventas_usd"]
        total_sales = report["resumen_ejecutivo"]["ventas_totales_usd"]
        amazon_percentage = (amazon_sales / total_sales * 100) if total_sales > 0 else 0
        
        if amazon_percentage > 70:
            recommendations.append({
                "tipo": "diversificación",
                "prioridad": "alta",
                "mensaje": "📊 Amazon representa más del 70% de las ventas. Considera diversificar a otras plataformas para reducir dependencia."
            })
        
        # Análisis de KU
        page_reads = report["resumen_ejecutivo"]["page_reads_ku"]
        if page_reads > 10000:
            recommendations.append({
                "tipo": "kindle_unlimited",
                "prioridad": "media",
                "mensaje": "📚 Excelente rendimiento en Kindle Unlimited. Considera añadir más títulos a KDP Select."
            })
        
        # Análisis de mercados
        us_sales = report["por_mercado"]["US"]["ventas_usd"]
        if us_sales < total_sales * 0.35:
            recommendations.append({
                "tipo": "expansión",
                "prioridad": "alta",
                "mensaje": "🇺🇸 El mercado US está sub-representado. Aumenta presupuesto publicitario en Amazon.com"
            })
        
        # Recomendaciones generales
        recommendations.extend([
            {
                "tipo": "pricing",
                "prioridad": "media",
                "mensaje": "💰 Libros con BSR < 50,000 podrían soportar aumento de precio del 10-15%"
            },
            {
                "tipo": "bundling",
                "prioridad": "baja",
                "mensaje": "📦 Crear bundle 'Valentina Smirnova - Serie Completa' podría aumentar AOV"
            },
            {
                "tipo": "promoción",
                "prioridad": "media",
                "mensaje": "🎁 Programar promoción gratuita para libro con menor visibilidad este fin de semana"
            },
            {
                "tipo": "contenido",
                "prioridad": "baja",
                "mensaje": "✍️ Aumentar frecuencia de posts en BookTok - tendencia alcista en engagement"
            }
        ])
        
        return recommendations
    
    def _detect_alerts(self, report):
        """Detecta alertas y anomalías"""
        alerts = []
        
        # Alerta de caída de ventas
        if report["resumen_ejecutivo"]["unidades_vendidas"] < 20:
            alerts.append({
                "tipo": "ventas_bajas",
                "severidad": "alta",
                "mensaje": "⚠️ Ventas significativamente bajas. Revisar visibilidad y ads."
            })
        
        # Alerta de reviews
        if report["resumen_ejecutivo"]["nuevas_reviews"] == 0:
            alerts.append({
                "tipo": "sin_reviews",
                "severidad": "media",
                "mensaje": "📭 Sin nuevas reviews en 24h. Activar campaña de solicitud de reviews."
            })
        
        # Alerta de BSR
        for asin, data in report["por_libro"].items():
            if data.get("bsr", 999999) > 100000:
                alerts.append({
                    "tipo": "bsr_alto",
                    "severidad": "baja",
                    "mensaje": f"📉 '{data['titulo'][:30]}...' tiene BSR elevado. Considerar promoción."
                })
        
        return alerts
    
    def _save_report(self, report, report_type):
        """Guarda reporte en archivo"""
        filename = f"{report_type}_report_{datetime.now().strftime('%Y%m%d_%H%M')}.json"
        filepath = os.path.join(self.reports_dir, filename)
        
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(report, f, indent=2, ensure_ascii=False)
        
        return filepath
    
    def generate_weekly_report(self):
        """Genera reporte semanal consolidado"""
        # En implementación real, agregaría datos de los últimos 7 días
        report = self.generate_daily_report(include_sample_data=True)
        
        report["periodo"] = {
            "inicio": (datetime.now() - timedelta(days=7)).strftime('%Y-%m-%d'),
            "fin": datetime.now().strftime('%Y-%m-%d')
        }
        
        # Multiplicar datos para simular semana
        report["resumen_ejecutivo"]["ventas_totales_usd"] *= 7
        report["resumen_ejecutivo"]["unidades_vendidas"] *= 7
        report["resumen_ejecutivo"]["page_reads_ku"] *= 7
        
        self._save_report(report, "weekly")
        
        return report
    
    def generate_monthly_forecast(self):
        """Genera pronóstico de ventas mensual"""
        forecast = {
            "fecha_generacion": datetime.now().isoformat(),
            "mes_pronosticado": (datetime.now() + timedelta(days=30)).strftime('%Y-%m'),
            "proyeccion": {
                "ventas_usd": 8500,
                "unidades": 2200,
                "page_reads_ku": 350000,
                "nuevos_suscriptores": 150
            },
            "factores_crecimiento": [
                {
                    "factor": "Temporada alta de lectura (primavera)",
                    "impacto": "+15%"
                },
                {
                    "factor": "Nuevas promociones programadas",
                    "impacto": "+10%"
                },
                {
                    "factor": "Expansión a mercado latinoamericano",
                    "impacto": "+8%"
                },
                {
                    "factor": "Campaña en BookTok",
                    "impacto": "+12%"
                }
            ],
            "riesgos": [
                {
                    "riesgo": "Aumento de competencia en categoría sci-fi",
                    "mitigacion": "Diferenciación mediante marketing de autor"
                },
                {
                    "riesgo": "Cambios en algoritmo de Amazon",
                    "mitigacion": "Diversificación a otras plataformas"
                },
                {
                    "riesgo": "Fluctuaciones tipo de cambio EUR/USD",
                    "mitigacion": "Pricing dinámico por región"
                }
            ],
            "escenarios": {
                "optimista": {
                    "ventas_usd": 10500,
                    "probabilidad": "25%"
                },
                "esperado": {
                    "ventas_usd": 8500,
                    "probabilidad": "50%"
                },
                "conservador": {
                    "ventas_usd": 6500,
                    "probabilidad": "25%"
                }
            }
        }
        
        self._save_report(forecast, "forecast")
        
        return forecast
    
    def track_kpi(self, metric_name, value, timestamp=None):
        """Registra KPIs importantes en historial"""
        if not timestamp:
            timestamp = datetime.now().isoformat()
        
        kpis = {}
        if os.path.exists(self.kpi_file):
            with open(self.kpi_file, 'r') as f:
                kpis = json.load(f)
        
        if metric_name not in kpis:
            kpis[metric_name] = []
        
        kpis[metric_name].append({
            "timestamp": timestamp,
            "value": value
        })
        
        # Mantener solo últimos 90 registros
        kpis[metric_name] = kpis[metric_name][-90:]
        
        with open(self.kpi_file, 'w') as f:
            json.dump(kpis, f, indent=2)
        
        return kpis
    
    def get_kpi_trend(self, metric_name, days=7):
        """Obtiene tendencia de un KPI"""
        if not os.path.exists(self.kpi_file):
            return None
        
        with open(self.kpi_file, 'r') as f:
            kpis = json.load(f)
        
        if metric_name not in kpis:
            return None
        
        data = kpis[metric_name][-days:]
        
        if len(data) < 2:
            return {"trend": "insufficient_data"}
        
        values = [d["value"] for d in data]
        avg = sum(values) / len(values)
        
        # Calcular tendencia
        first_half = values[:len(values)//2]
        second_half = values[len(values)//2:]
        
        first_avg = sum(first_half) / len(first_half) if first_half else 0
        second_avg = sum(second_half) / len(second_half) if second_half else 0
        
        if second_avg > first_avg * 1.1:
            trend = "up"
        elif second_avg < first_avg * 0.9:
            trend = "down"
        else:
            trend = "stable"
        
        return {
            "metric": metric_name,
            "period_days": days,
            "average": round(avg, 2),
            "trend": trend,
            "change_percent": round(((second_avg - first_avg) / first_avg * 100), 2) if first_avg else 0,
            "data_points": len(data)
        }
    
    def format_report_for_display(self, report):
        """Formatea reporte para visualización en consola"""
        lines = []
        
        lines.append("=" * 70)
        lines.append("📊 REPORTE DE VENTAS - FRANCISCO ANGULO DE LAFUENTE")
        lines.append("=" * 70)
        lines.append(f"Generado: {datetime.now().strftime('%Y-%m-%d %H:%M')}")
        lines.append("")
        
        # Resumen ejecutivo
        resumen = report["resumen_ejecutivo"]
        lines.append("📈 RESUMEN EJECUTIVO")
        lines.append("-" * 40)
        lines.append(f"💰 Ventas totales: ${resumen['ventas_totales_usd']:.2f}")
        lines.append(f"📚 Unidades vendidas: {resumen['unidades_vendidas']}")
        lines.append(f"📖 Page Reads KU: {resumen['page_reads_ku']:,}")
        lines.append(f"⭐ Nuevas reviews: {resumen['nuevas_reviews']}")
        lines.append(f"🏆 Libro más vendido: {resumen['libro_mas_vendido'][:40]}...")
        lines.append(f"🛒 Plataforma top: {resumen['plataforma_top']}")
        lines.append("")
        
        # Por plataforma
        lines.append("🌐 VENTAS POR PLATAFORMA")
        lines.append("-" * 40)
        for platform, data in report["por_plataforma"].items():
            lines.append(f"{platform:20} ${data['ventas_usd']:8.2f} | {data['unidades']:4d} unidades")
        lines.append("")
        
        # Por mercado
        lines.append("🌍 VENTAS POR MERCADO")
        lines.append("-" * 40)
        for market, data in sorted(report["por_mercado"].items(), key=lambda x: x[1]['ventas_usd'], reverse=True):
            lines.append(f"{market:6} ${data['ventas_usd']:8.2f} | {data['unidades']:4d} unidades")
        lines.append("")
        
        # KPIs
        lines.append("📊 KPIs DIARIOS")
        lines.append("-" * 40)
        kpi = report["kpi_diarios"]
        lines.append(f"Conversion Rate:      {kpi['conversion_rate']:.2f}%")
        lines.append(f"Average Order Value:  ${kpi['average_order_value']:.2f}")
        lines.append(f"CAC:                  ${kpi['customer_acquisition_cost']:.2f}")
        lines.append(f"ROAS:                 {kpi['return_on_ad_spend']:.2f}x")
        lines.append("")
        
        # Alertas
        if report["alertas"]:
            lines.append("⚠️ ALERTAS")
            lines.append("-" * 40)
            for alert in report["alertas"]:
                lines.append(f"[{alert['severidad'].upper()}] {alert['mensaje']}")
            lines.append("")
        
        # Recomendaciones
        lines.append("💡 RECOMENDACIONES")
        lines.append("-" * 40)
        for rec in report["recomendaciones"][:5]:
            lines.append(f"[{rec['prioridad'].upper()}] {rec['mensaje']}")
        
        lines.append("")
        lines.append("=" * 70)
        
        return "\n".join(lines)

if __name__ == "__main__":
    dashboard = SalesDashboard()
    
    print("🎯 Generando reporte de ventas...")
    print()
    
    # Generar reporte diario
    daily = dashboard.generate_daily_report(include_sample_data=True)
    
    # Mostrar formateado
    print(dashboard.format_report_for_display(daily))
    
    print()
    print("📄 Reporte guardado en:", dashboard._save_report(daily, "daily"))
    
    # Generar forecast
    print()
    print("🔮 Generando pronóstico mensual...")
    forecast = dashboard.generate_monthly_forecast()
    print(f"Proyección de ventas: ${forecast['proyeccion']['ventas_usd']:,}")
