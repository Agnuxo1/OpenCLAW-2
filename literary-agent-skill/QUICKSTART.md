# 🚀 Guía de Inicio Rápido - Literary Agent Skill

## Instalación en 5 Minutos

### Paso 1: Preparar Entorno

```bash
# Verificar Python 3.8+
python3 --version

# Instalar dependencias
pip install requests beautifulsoup4 pandas openpyxl
```

### Paso 2: Instalar Skill

```bash
# Crear directorio de skills
mkdir -p ~/.openclaw/skills/literary-agent-francisco-angulo

# Copiar archivos
cp SKILL.md ~/.openclaw/skills/literary-agent-francisco-angulo/
cp -r scripts ~/.openclaw/skills/literary-agent-francisco-angulo/
cp config.json ~/.openclaw/skills/literary-agent-francisco-angulo/

# Crear directorios de trabajo
mkdir -p ~/.openclaw/literary-agent/{reports,campaigns,contacts,assets}
```

### Paso 3: Configurar

```bash
# Editar configuración
nano ~/.openclaw/skills/literary-agent-francisco-angulo/config.json

# Configurar variables de entorno (opcional)
export AMAZON_API_KEY="tu_key"
export MAILCHIMP_API_KEY="tu_key"
```

### Paso 4: Reiniciar OpenCLAW

```bash
openclaw gateway restart
```

## 🎯 Primeros Comandos

### 1. Generar Reporte de Ventas

```
Usuario: Generar reporte de ventas de hoy

Agente: 📊 REPORTE DE VENTAS - FRANCISCO ANGULO DE LAFUENTE
==================================================
Generado: 2026-02-07 14:30

📈 RESUMEN EJECUTIVO
----------------------------------------
💰 Ventas totales: $523.45
📚 Unidades vendidas: 127
📖 Page Reads KU: 12,450
⭐ Nuevas reviews: 3
🏆 Libro más vendido: Things you shouldn't do...
🛒 Plataforma top: Amazon KDP

💡 RECOMENDACIONES
----------------------------------------
[HIGH] Amazon representa 75% de ventas - diversificar
[MEDIUM] Excelente rendimiento KU - añadir más títulos
[LOW] Crear bundle serie Valentina Smirnova
```

### 2. Crear Contenido Social

```
Usuario: Crear contenido para redes esta semana

Agente: ✅ Contenido generado para 7 días:

📅 LUNES - ApocalypsAI
🐦 Twitter: "¿Y si la IA que creamos decide que somos el problema? 
El día que la AGI despertó, todo cambió... #SciFi #AI"

📸 Instagram: [Caption completo con hashtags]

🎵 TikTok: [Guion de 40 segundos]

📄 Guardado en: ~/.openclaw/literary-agent/campaigns/social_content_20260207.txt
```

### 3. Contactar Bibliotecas

```
Usuario: Enviar campaña a bibliotecas de España

Agente: 📚 Preparando campaña para bibliotecas de España...

Modo: Simulación (dry-run)
Total bibliotecas: 5

[1] Biblioteca Nacional de España (Madrid)
    → contacto@bne.es
    Idioma: ES

[2] Biblioteca Pública Municipal de Madrid
    → bibliotecas@madrid.es
    Idioma: ES
...

✅ 5 bibliotecas preparadas
📄 Reporte: ~/.openclaw/literary-agent/reports/library_campaign_20260207_143000.csv

Para envío real, ejecutar con: dry_run=false
```

### 4. Analizar Competencia

```
Usuario: Analizar precios de competencia

Agente: 🔍 ANÁLISIS DE PRECIOS DE COMPETENCIA
==================================================
Fecha: 2026-02-07 14:35

📚 SCIENCE FICTION
----------------------------------------
  📖 The Martian (Andy Weir)
     💰 Precio: $9.99
     ⭐ Rating: 4.7/5
     📊 BSR: #1,234

  📖 Dark Matter (Blake Crouch)
     💰 Precio: $12.99
     ⭐ Rating: 4.5/5
     📊 BSR: #2,456

💡 RECOMENDACIONES:
• Precio óptimo para sci-fi: $4.99-$9.99
• Tu libro ApocalypsAI podría aumentar a $6.99
```

## 📋 Flujos de Trabajo Comunes

### Lanzamiento de Nuevo Libro

```
1. "Planificar lanzamiento de [título]"
   → Agente genera timeline completo (30 días)

2. "Crear contenido teaser para [título]"
   → Genera posts, extracts, trailers

3. "Configurar promoción ARC para [título]"
   → Prepara BookSprout/NetGalley

4. "Generar email de lanzamiento"
   → Template para lista de suscriptores

5. "Crear ads para [título]"
   → Copy para Amazon/Facebook ads
```

### Promoción de Libros Gratuitos

```
1. "Crear promoción gratuita para MANUFACTURED LOVE"
   → Configura 5 días gratis en KDP

2. "Generar anuncio promoción gratuita"
   → Posts para redes y grupos

3. "Enviar a sitios de libros gratuitos"
   → Freebooksy, BookBub, ENT

4. "Monitorear promoción"
   → Tracking de descargas y conversiones
```

### Contacto Mensual a Bibliotecas

```
1. "Cargar nuevas bibliotecas en base de datos"
   → Actualiza CSV con contactos

2. "Enviar campaña a bibliotecas de [región]"
   → Outreach personalizado

3. "Seguimiento de bibliotecas contactadas"
   → Actualiza estados y respuestas

4. "Generar reporte de bibliotecas"
   → Métricas de conversión
```

## 🔧 Solución de Problemas

### Skill no aparece en OpenCLAW

```bash
# Verificar ubicación
ls ~/.openclaw/skills/literary-agent-francisco-angulo/SKILL.md

# Reiniciar gateway
openclaw gateway restart

# Verificar logs
openclaw logs
```

### Scripts no funcionan

```bash
# Verificar Python
python3 --version

# Instalar dependencias faltantes
pip install requests beautifulsoup4 pandas

# Verificar permisos
chmod +x ~/.openclaw/skills/literary-agent-francisco-angulo/scripts/*.py
```

### Error de directorios

```bash
# Crear estructura manualmente
mkdir -p ~/.openclaw/literary-agent/{reports,campaigns,contacts,assets}
```

## 📊 Métricas Importantes

### KPIs Diarios a Monitorear

| KPI | Objetivo | Alerta |
|-----|----------|--------|
| Ventas | >20 unidades | <10 |
| Page Reads KU | >5,000 | <2,000 |
| BSR | <50,000 | >100,000 |
| Reviews nuevas | >1 | 0 |
| Conversion Rate | >3% | <2% |

### Métricas Semanales

- Total ventas vs. semana anterior
- Crecimiento de seguidores
- Engagement rate en redes
- Tasa de apertura de emails
- Conversiones de promociones

## 💡 Tips y Mejores Prácticas

### 1. Frecuencia de Uso Recomendada

- **Reporte de ventas**: Diario (9am)
- **Contenido social**: Semanal (lunes)
- **Bibliotecas**: Mensual (primer lunes)
- **Análisis competencia**: Quincenal
- **Optimización precios**: Mensual

### 2. Combinar Funcionalidades

```
# Flujo óptimo semanal:
Lunes: Generar contenido social + reporte ventas
Martes: Revisar alertas + ajustar ads
Miércoles: Engagement redes + responder reviews
Jueves: Análisis datos + optimizar
Viernes: Planificar siguiente semana
```

### 3. Personalización Progresiva

1. **Semana 1**: Usar configuración por defecto
2. **Semana 2**: Ajustar horarios de posts
3. **Semana 3**: Personalizar templates de email
4. **Semana 4**: Añadir bibliotecas específicas

## 📚 Recursos Adicionales

- [SKILL.md](SKILL.md) - Documentación completa
- [config.json](config.json) - Configuración detallada
- [README.md](README.md) - Información general

## 🆘 Soporte

¿Problemas o preguntas?

1. Revisar logs: `openclaw logs`
2. Verificar configuración: `cat ~/.openclaw/skills/literary-agent-francisco-angulo/config.json`
3. Consultar documentación en SKILL.md

---

**¡Listo para vender más libros!** 📚🚀
