# 📚 Literary Agent Skill - Francisco Angulo de Lafuente

> **Author:** Francisco Angulo de Lafuente · **ORCID:** https://orcid.org/0009-0001-1634-7063
> **Attribution recorded on:** 2026-11-05

<!--
Attribution metadata:
Project: OpenCLAW-2
Author: Francisco Angulo de Lafuente
ORCID: https://orcid.org/0009-0001-1634-7063
Attribution recorded: 2026-11-05
SPDX-License-Identifier: MIT
-->


Una Skill profesional de OpenCLAW que transforma un agente de IA en un representante literario digital 24/7 especializado en marketing, ventas y distribución de libros.

## 🎯 Descripción

Esta Skill convierte a OpenCLAW en un agente literario completo capaz de:

- 📈 **Marketing Digital 24/7**: Gestión automatizada de redes sociales, contenido y engagement
- 🔍 **SEO para Libros**: Optimización de metadatos, keywords y categorías
- 💰 **Estrategia de Precios**: Modelo de embudo con libros gratuitos y dinámica de precios
- 🌐 **Distribución Multicanal**: Amazon, Apple Books, Kobo, Barnes & Noble y más
- 📚 **Contacto con Bibliotecas**: Outreach automatizado a bibliotecas mundiales
- 📊 **Análisis de Ventas**: Dashboard completo con KPIs y recomendaciones
- 🎁 **Gestión de Promociones**: Libros gratuitos, countdown deals y campañas

## 📖 Sobre el Autor

**Francisco Angulo de Lafuente** (Madrid, 1976) es un autor español con:

- 📚 **55+ obras publicadas**
- 🌍 **6 idiomas**: Español, Inglés, Francés, Italiano, Portugués, Japonés
- 📖 **Múltiples formatos**: Ebook, Paperback, Hardcover, Audiolibro
- 🏆 **Diversos géneros**: Ciencia ficción, Thriller, No ficción, Infantil/Juvenil

### Catálogo Destacado

| Libro | Género | ASIN |
|-------|--------|------|
| Things you shouldn't do if you want to be a writer | Writing Guide | B00PIPTRI8 |
| ApocalypsAI: The Day After AGI | Science Fiction | B0CLQ2RJP3 |
| La Invasión de las Medusas Mutantes | Children's Illustrated | B0CL2YJMH6 |
| Eco-fuel-FA (ECOFA) | Sustainability | B0CHMQWSQB |
| Comandante Valentina Smirnova | Spy Thriller | B0CL2HH74Q |

## 🚀 Instalación

### Método 1: Instalación Manual

```bash
# Crear directorio de skills
mkdir -p ~/.openclaw/skills/literary-agent-francisco-angulo

# Copiar archivos
cp SKILL.md ~/.openclaw/skills/literary-agent-francisco-angulo/
cp -r scripts ~/.openclaw/skills/literary-agent-francisco-angulo/
cp config.json ~/.openclaw/skills/literary-agent-francisco-angulo/

# Instalar dependencias
pip install requests beautifulsoup4 pandas openpyxl
```

### Método 2: ClawHub (Próximamente)

```bash
npx clawhub@latest install literary-agent-francisco-angulo
```

## ⚙️ Configuración

### Variables de Entorno

```bash
# APIs de Plataformas (opcional, para funcionalidades avanzadas)
export AMAZON_API_KEY="your_key"
export GOODREADS_API_KEY="your_key"

# Email Marketing
export MAILCHIMP_API_KEY="your_key"

# Redes Sociales
export TWITTER_API_KEY="your_key"
export FACEBOOK_ACCESS_TOKEN="your_token"
```

### Archivo de Configuración

Edita `config.json` para personalizar:

- Metas de ventas
- Presupuesto publicitario
- Frecuencia de publicaciones
- Alertas y umbrales

## 🎮 Uso

### Comandos Principales

```
"Generar reporte de ventas de hoy"
→ Analiza datos y genera reporte diario completo

"Crear contenido para redes esta semana"
→ Genera tweets, captions, guiones para 7 días

"Enviar campaña a bibliotecas de Europa"
→ Prepara y envía emails personalizados

"Analizar precios de competencia"
→ Monitorea precios y genera recomendaciones

"Planificar lanzamiento de ApocalypsAI"
→ Crea timeline completo de lanzamiento

"Optimizar metadata de La Invasión de las Medusas Mutantes"
→ Revisa y mejora título, keywords, descripción

"Generar seguimiento de reviews"
→ Crea plan para obtener más reseñas

"Crear promoción gratuita para MANUFACTURED LOVE"
→ Configura estrategia de días gratis
```

### Scripts de Automatización

#### 1. Monitor de Precios

```bash
python scripts/price_monitor.py
```

Monitorea precios de competidores y genera alertas.

#### 2. Generador de Contenido Social

```bash
python scripts/social_content.py
```

Genera contenido para Twitter, Instagram, Facebook, LinkedIn y TikTok.

#### 3. Contacto a Bibliotecas

```bash
python scripts/library_outreach.py
```

Gestiona campañas de outreach a bibliotecas mundiales.

#### 4. Dashboard de Ventas

```bash
python scripts/sales_dashboard.py
```

Genera reportes diarios, semanales y pronósticos.

## 📊 Funcionalidades Detalladas

### 1. Marketing Digital 24/7

#### Calendario Editorial Automático

| Día | Tema | Contenido |
|-----|------|-----------|
| Lunes | #MotivationMonday | Citas, consejos de escritura |
| Martes | #TeaserTuesday | Extractos de libros |
| Miércoles | #WriterWednesday | Proceso creativo |
| Jueves | #ThrowbackThursday | Libros clásicos |
| Viernes | #FreeBookFriday | Promoción libros gratuitos |
| Sábado | #ShelfieSaturday | Fotos de lectores |
| Domingo | #SampleSunday | Capítulos gratuitos |

#### Hashtags Estratégicos

**Español:**
```
#LibrosRecomendados #Lectura #EscritorEspañol #KindleUnlimited
#BookTokEspañol #LibrosGratis #AutorIndie
```

**Inglés:**
```
#BookRecommendations #IndieAuthor #KindleUnlimited #BookTok
#MustRead #SciFi #FantasyBooks
```

### 2. SEO para Libros

#### Keywords Principales

- "best sci fi books 2024"
- "artificial intelligence novels"
- "how to become a writer"
- "spy thriller books"
- "spanish author science fiction"

#### Optimización Amazon

```yaml
Título: [Título] | [Subtítulo con keywords]
Subtítulo: [Género] | [Hook] | [Beneficio]
Descripción: 7 líneas óptimas
Keywords Backend: 7 slots estratégicos
```

### 3. Estrategia de Precios

#### Modelo de Embudo

```
NIVEL 1 - ATRACCIÓN: Gratis / $0.99
├── Libros gratuitos en KU
├── Promociones periódicas
└── Objetivo: Adquisición

NIVEL 2 - ENGANCHE: $2.99 - $4.99
├── Libros cortos
├── Serie starters
└── Objetivo: Conversión

NIVEL 3 - MONETIZACIÓN: $5.99 - $9.99
├── Novelas completas
└── Objetivo: Ingresos

NIVEL 4 - PREMIUM: $10.99 - $19.99
├── Box sets
├── Audiolibros
└── Objetivo: Valor por cliente
```

### 4. Distribución a Bibliotecas

#### Plataformas Soportadas

| Plataforma | Alcance | Distribuidores |
|------------|---------|----------------|
| OverDrive | 43,000+ bibliotecas | D2D, PublishDrive, StreetLib |
| hoopla | 2,000+ sistemas | D2D, PublishDrive |
| cloudLibrary | 30,000 bibliotecas | Draft2Digital |
| Odilo | 30,000 bibliotecas | D2D, StreetLib |
| EBSCOhost | Académica | IngramSpark |
| Mackin | 50,000 escuelas | PublishDrive |

#### Template de Email

La Skill incluye templates profesionales en español, inglés y francés para contacto con bibliotecas.

### 5. Análisis de Ventas

#### KPIs Monitoreados

- Ventas totales por plataforma
- Unidades vendidas
- Page Reads (Kindle Unlimited)
- Best Sellers Rank (BSR)
- Reviews nuevas
- Conversion rate
- ROAS (Return on Ad Spend)

#### Alertas Automáticas

- Ventas significativamente bajas
- Caída de BSR
- Sin nuevas reviews
- Cambios de precio de competencia

## 📅 Automatización

### Tareas Programadas

```yaml
diarias:
  - 09:00: Reporte de ventas
  - 12:00: Monitoreo de reviews
  
semanales:
  - Lunes 10:00: Campaña a bibliotecas
  - Viernes 18:00: Reporte semanal
  
mensuales:
  - Día 1: Pronóstico de ventas
  - Día 15: Análisis de competencia
```

## 🎯 Metas 2026

| Métrica | Objetivo |
|---------|----------|
| Ventas totales | 10,000 unidades |
| Ingresos | $50,000 USD |
| Nuevas reviews | 200 |
| Suscriptores email | 2,000 |
| Seguidores redes | 15,000 |
| Bibliotecas contactadas | 500 |
| Bibliotecas adquiridas | 50 |

## 🔧 Personalización

### Añadir Nuevo Libro

Edita `config.json` y añade a la sección `catalog`:

```json
{
  "asin": "B0XXXXXXXX",
  "title": "Nuevo Título",
  "genre": "Género",
  "languages": ["ES", "EN"],
  "formats": ["ebook", "paperback"]
}
```

### Modificar Templates de Email

Edita `scripts/library_outreach.py` en la sección `self.templates`.

### Ajustar Frecuencia de Posts

Edita `config.json` en `marketing.social_media.posting_frequency`.

## 📈 Roadmap

### v1.1 (Próximo)
- [ ] Integración con APIs de Amazon/Apple
- [ ] Análisis de sentimiento de reviews
- [ ] Chatbot para atención a lectores

### v1.2
- [ ] Automatización de ads con IA
- [ ] Traducción automática de marketing copy
- [ ] Integración con blockchain para royalties

### v2.0
- [ ] Sistema de afiliados
- [ ] Real-time pricing optimization
- [ ] Predictive analytics

## 🤝 Contribuciones

Las contribuciones son bienvenidas. Por favor:

1. Fork el repositorio
2. Crea una rama (`git checkout -b feature/nueva-funcionalidad`)
3. Commit tus cambios (`git commit -am 'Añadir nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Abre un Pull Request

## 📄 Licencia

MIT License - ver LICENSE para detalles.

## 🙏 Créditos

- **Autor**: Francisco Angulo de Lafuente
- **Desarrollador**: [Tu nombre]
- **Inspiración**: Agent Skills Specification by Anthropic

## 📞 Contacto

- **Email**: contact@franciscoangulo.com
- **Web**: https://www.franciscoangulo.com
- **Amazon**: https://www.amazon.com/stores/author/B0086LDX3G

---

<p align="center">
  <i>"Un libro es un sueño que tienes en tus manos."</i> - Neil Gaiman
</p>
