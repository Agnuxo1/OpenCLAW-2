#!/usr/bin/env python3
"""
Monitor de precios de libros competidores
Ubicación: ~/.openclaw/literary-agent/scripts/price_monitor.py
"""

import requests
from bs4 import BeautifulSoup
import json
from datetime import datetime
import os

def check_amazon_price(asin):
    """Obtiene precio actual de un libro en Amazon"""
    url = f"https://www.amazon.com/dp/{asin}"
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        'Accept-Language': 'en-US,en;q=0.9',
        'Accept-Encoding': 'gzip, deflate, br',
        'Connection': 'keep-alive',
    }
    
    try:
        response = requests.get(url, headers=headers, timeout=10)
        soup = BeautifulSoup(response.content, 'html.parser')
        
        # Buscar precio Kindle
        price_selectors = [
            '.kindlePrice',
            '#kindle-price',
            '.a-price .a-offscreen',
            '#priceblock_kindleprice',
            '.a-color-price'
        ]
        
        for selector in price_selectors:
            price_element = soup.select_one(selector)
            if price_element:
                return price_element.text.strip()
        
        return "No disponible"
    except Exception as e:
        return f"Error: {e}"

def get_book_info(asin):
    """Obtiene información completa del libro"""
    url = f"https://www.amazon.com/dp/{asin}"
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    }
    
    try:
        response = requests.get(url, headers=headers, timeout=10)
        soup = BeautifulSoup(response.content, 'html.parser')
        
        # Título
        title = soup.select_one('#productTitle')
        title = title.text.strip() if title else "Desconocido"
        
        # Precio
        price = check_amazon_price(asin)
        
        # Rating
        rating = soup.select_one('.a-icon-alt')
        rating = rating.text.strip() if rating else "Sin rating"
        
        # BSR (Best Sellers Rank)
        bsr_element = soup.find(text=lambda t: t and 'Best Sellers Rank' in t)
        bsr = "No disponible"
        if bsr_element:
            bsr_parent = bsr_element.parent
            if bsr_parent:
                bsr = bsr_parent.text.strip()[:100]
        
        return {
            "titulo": title,
            "precio": price,
            "rating": rating,
            "bsr": bsr
        }
    except Exception as e:
        return {"error": str(e)}

def analyze_competition():
    """Analiza precios de competidores en ciencia ficción y thrillers"""
    
    # ASINs de libros competidores (ejemplos representativos)
    competitors = {
        "sci_fi_post_apocalyptic": [
            "B08XXXX1",  # Placeholder - reemplazar con ASINs reales
        ],
        "sci_fi_ai": [
            "B00XXXX2",  # Placeholder
        ],
        "thriller_espionage": [
            "B07XXXX3",  # Placeholder
        ],
        "writing_guides": [
            "B00XXXX4",  # Placeholder
        ]
    }
    
    report = {
        "fecha": datetime.now().isoformat(),
        "categorias": {}
    }
    
    for category, asins in competitors.items():
        report["categorias"][category] = []
        for asin in asins:
            info = get_book_info(asin)
            report["categorias"][category].append({
                "asin": asin,
                **info
            })
    
    # Guardar reporte
    reports_dir = os.path.expanduser("~/.openclaw/literary-agent/reports")
    os.makedirs(reports_dir, exist_ok=True)
    
    filename = f"price_report_{datetime.now().strftime('%Y%m%d_%H%M')}.json"
    filepath = os.path.join(reports_dir, filename)
    
    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(report, f, indent=2, ensure_ascii=False)
    
    # Generar resumen
    summary = generate_price_summary(report)
    
    return {
        "report_file": filepath,
        "summary": summary,
        "raw_data": report
    }

def generate_price_summary(report):
    """Genera resumen ejecutivo del análisis de precios"""
    summary = []
    
    summary.append("=" * 60)
    summary.append("ANÁLISIS DE PRECIOS DE COMPETENCIA")
    summary.append(f"Fecha: {datetime.now().strftime('%Y-%m-%d %H:%M')}")
    summary.append("=" * 60)
    
    for category, books in report["categorias"].items():
        summary.append(f"\n📚 {category.upper().replace('_', ' ')}")
        summary.append("-" * 40)
        
        for book in books:
            if "error" not in book:
                summary.append(f"\n  📖 {book['titulo'][:50]}...")
                summary.append(f"     💰 Precio: {book['precio']}")
                summary.append(f"     ⭐ Rating: {book['rating']}")
                summary.append(f"     📊 BSR: {book['bsr'][:50]}...")
    
    summary.append("\n" + "=" * 60)
    summary.append("RECOMENDACIONES:")
    summary.append("=" * 60)
    summary.append("• Mantener precios competitivos en rango $2.99-$4.99")
    summary.append("• Monitorear cambios de precio semanalmente")
    summary.append("• Ajustar estrategia según temporada")
    
    return "\n".join(summary)

def track_price_history(asin, current_price):
    """Registra historial de precios para un libro"""
    history_file = os.path.expanduser(f"~/.openclaw/literary-agent/reports/price_history_{asin}.json")
    
    history = []
    if os.path.exists(history_file):
        with open(history_file, 'r') as f:
            history = json.load(f)
    
    history.append({
        "fecha": datetime.now().isoformat(),
        "precio": current_price
    })
    
    # Mantener solo últimos 90 días
    history = history[-90:]
    
    with open(history_file, 'w') as f:
        json.dump(history, f, indent=2)
    
    return history

def detect_price_changes():
    """Detecta cambios significativos en precios de competencia"""
    # Implementación para alertar sobre cambios >20%
    pass

if __name__ == "__main__":
    print("🔍 Iniciando análisis de precios de competencia...")
    result = analyze_competition()
    print(result["summary"])
    print(f"\n📄 Reporte completo guardado en: {result['report_file']}")
