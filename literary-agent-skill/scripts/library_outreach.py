#!/usr/bin/env python3
"""
Sistema de contacto a bibliotecas
Ubicación: ~/.openclaw/literary-agent/scripts/library_outreach.py
"""

import csv
import json
from datetime import datetime
import os

class LibraryOutreach:
    def __init__(self):
        self.base_dir = os.path.expanduser("~/.openclaw/literary-agent")
        self.contacts_dir = os.path.join(self.base_dir, "contacts")
        self.reports_dir = os.path.join(self.base_dir, "reports")
        
        # Crear directorios si no existen
        os.makedirs(self.contacts_dir, exist_ok=True)
        os.makedirs(self.reports_dir, exist_ok=True)
        
        self.libraries_db = os.path.join(self.contacts_dir, "libraries.csv")
        self.campaigns_db = os.path.join(self.contacts_dir, "campaigns.json")
        
        # Templates de email en múltiples idiomas
        self.templates = {
            "ES": {
                "subject": "Nuevo Catálogo de Autor Español - Francisco Angulo de Lafuente - Disponible para Bibliotecas",
                "body": """Estimado/a {nombre},

Mi nombre es [Agent Name], representante literario de Francisco Angulo de Lafuente, autor español con más de 55 obras publicadas en múltiples idiomas.

Me pongo en contacto para informarle que el catálogo del autor está disponible para adquisición bibliotecaria a través de las principales plataformas de distribución.

**SOBRE EL AUTOR:**
Francisco Angulo de Lafuente (Madrid, 1976) es un autor versátil cuyas obras abarcan desde ciencia ficción y thrillers de espionaje hasta literatura infantil ilustrada y guías para escritores. Aficionado al cine de fantasía y la literatura, es seguidor de Isaac Asimov y Stephen King.

**CATÁLOGO DESTACADO:**

📚 **Para Adultos:**
• "ApocalypsAI: The Day After AGI" - Ciencia ficción sobre inteligencia artificial
• "Comandante Valentina Smirnova" - Serie thriller de espionaje internacional
• "Things you shouldn't do if you want to be a writer" - Guía esencial para escritores
• "Eco-fuel-FA (ECOFA)" - Sostenibilidad y soluciones energéticas

📖 **Para Jóvenes y Niños:**
• "La Invasión de las Medusas Mutantes" - Novela ilustrada de aventuras
• "Company Nº12" - Aventuras juveniles (disponible en francés)

🌍 **IDIOMAS DISPONIBLES:**
• Español (principal)
• Inglés
• Francés
• Italiano
• Portugués
• Japonés

**PLATAFORMAS DE DISTRIBUCIÓN:**
✓ OverDrive / Libby
✓ hoopla Digital
✓ cloudLibrary (Bibliotheca)
✓ Odilo
✓ EBSCOhost
✓ Mackin (para escuelas)

Todos los títulos están disponibles en formato ebook y muchos también en audiolibro y edición impresa.

**PARA ADQUIRIR:**
Puede adquirir los títulos a través de su distribuidor habitual o contactarme directamente para obtener información adicional sobre precios institucionales y licencias.

Adjunto encontrará el catálogo completo con ISBNs, descripciones y metadatos BISAC.

Quedo a su disposición para cualquier consulta o para programar una presentación virtual del autor para sus usuarios.

Un saludo cordial,

[Nombre del Agente]
Literary Agent - Francisco Angulo de Lafuente
Email: agent@franciscoangulo.com
Web: www.franciscoangulo.com

---

P.D.: Ofrecemos descuentos especiales para compras de colecciones completas y estamos abiertos a participar en programas de lectura de su biblioteca."""
            },
            "EN": {
                "subject": "New Spanish Author Catalog - Francisco Angulo de Lafuente - Available for Library Acquisition",
                "body": """Dear {nombre},

My name is [Agent Name], literary agent for Francisco Angulo de Lafuente, a Spanish author with over 55 published works in multiple languages.

I am writing to inform you that the author's catalog is available for library acquisition through major distribution platforms.

**ABOUT THE AUTHOR:**
Francisco Angulo de Lafuente (Madrid, 1976) is a versatile author whose works span from science fiction and spy thrillers to illustrated children's literature and writing guides. A fan of fantasy cinema and literature, he follows Isaac Asimov and Stephen King.

**FEATURED TITLES:**

📚 **For Adults:**
• "ApocalypsAI: The Day After AGI" - Science fiction about artificial intelligence
• "Commander Valentina Smirnova" - International spy thriller series
• "Things you shouldn't do if you want to be a writer" - Essential guide for writers
• "Eco-fuel-FA (ECOFA)" - Sustainability and energy solutions

📖 **For Young Readers:**
• "The Mutant Jellyfish Invasion" - Illustrated adventure novel
• "Company Nº12" - Youth adventures (available in French)

🌍 **LANGUAGES AVAILABLE:**
• Spanish (primary)
• English
• French
• Italian
• Portuguese
• Japanese

**DISTRIBUTION PLATFORMS:**
✓ OverDrive / Libby
✓ hoopla Digital
✓ cloudLibrary (Bibliotheca)
✓ Odilo
✓ EBSCOhost
✓ Mackin (for schools)

All titles are available in ebook format, with many also in audiobook and print editions.

**TO ACQUIRE:**
You can purchase titles through your regular distributor or contact me directly for institutional pricing and licensing information.

Attached you will find the complete catalog with ISBNs, descriptions, and BISAC metadata.

I remain at your disposal for any questions or to schedule a virtual author presentation for your patrons.

Best regards,

[Agent Name]
Literary Agent - Francisco Angulo de Lafuente
Email: agent@franciscoangulo.com
Web: www.franciscoangulo.com

---

P.S.: We offer special discounts for complete collection purchases and are open to participating in your library's reading programs."""
            },
            "FR": {
                "subject": "Nouveau Catalogue d'Auteur Espagnol - Francisco Angulo de Lafuente - Disponible pour les Bibliothèques",
                "body": """Cher/Chère {nombre},

Je m'appelle [Agent Name], agent littéraire de Francisco Angulo de Lafuente, auteur espagnol avec plus de 55 œuvres publiées en plusieurs langues.

Je vous contacte pour vous informer que le catalogue de l'auteur est disponible pour l'acquisition bibliothécaire via les principales plateformes de distribution.

**CATÉGORIES PRINCIPALES:**
• Science-fiction sur l'intelligence artificielle
• Thriller d'espionnage international
• Littérature jeunesse illustrée
• Guides d'écriture

**LANGUES DISPONIBLES:**
Espagnol, Anglais, Français, Italien, Portugais, Japonais

**PLATEFORMES:**
OverDrive/Libby, hoopla, cloudLibrary, Odilo, EBSCOhost

Cordialement,
[Agent Name]
Agent Littéraire - Francisco Angulo de Lafuente"""
            }
        }
    
    def create_library_template(self):
        """Crea template CSV para bibliotecas con datos de ejemplo"""
        if os.path.exists(self.libraries_db):
            return
        
        template = [
            ['nombre', 'email', 'ciudad', 'pais', 'region', 'tipo', 'idioma_preferido', 'contactado', 'fecha_contacto', 'respuesta', 'notas'],
            # España
            ['Biblioteca Nacional de España', 'contacto@bne.es', 'Madrid', 'España', 'Europa', 'Nacional', 'ES', 'No', '', '', ''],
            ['Biblioteca Pública Municipal de Madrid', 'bibliotecas@madrid.es', 'Madrid', 'España', 'España', 'Publica', 'ES', 'No', '', '', ''],
            ['Biblioteca de Catalunya', 'biblioteca@bc.cat', 'Barcelona', 'España', 'España', 'Nacional', 'ES', 'No', '', '', ''],
            ['Biblioteca Pública de Andalucía', 'biblioteca@juntadeandalucia.es', 'Sevilla', 'España', 'España', 'Publica', 'ES', 'No', '', '', ''],
            # Latinoamérica
            ['Biblioteca Nacional de México', 'contacto@bnm.unam.mx', 'Ciudad de México', 'México', 'Latinoamérica', 'Nacional', 'ES', 'No', '', '', ''],
            ['Biblioteca Nacional de Argentina', 'info@bn.gov.ar', 'Buenos Aires', 'Argentina', 'Latinoamérica', 'Nacional', 'ES', 'No', '', '', ''],
            ['Biblioteca Nacional de Colombia', 'contacto@bn.gov.co', 'Bogotá', 'Colombia', 'Latinoamérica', 'Nacional', 'ES', 'No', '', '', ''],
            ['Biblioteca de Santiago', 'biblioteca@santiago.cl', 'Santiago', 'Chile', 'Latinoamérica', 'Publica', 'ES', 'No', '', '', ''],
            # Estados Unidos
            ['New York Public Library', 'acquisitions@nypl.org', 'New York', 'USA', 'Norte America', 'Publica', 'EN', 'No', '', '', ''],
            ['Los Angeles Public Library', 'collections@lapl.org', 'Los Angeles', 'USA', 'Norte America', 'Publica', 'EN', 'No', '', '', ''],
            ['Miami-Dade Public Library', 'acquisitions@mdpls.org', 'Miami', 'USA', 'Norte America', 'Publica', 'ES', 'No', '', '', 'Hispanic community'],
            ['Houston Public Library', 'collections@houstontx.gov', 'Houston', 'USA', 'Norte America', 'Publica', 'EN', 'No', '', '', ''],
            # Reino Unido
            ['British Library', 'acquisitions@bl.uk', 'London', 'UK', 'Europa', 'Nacional', 'EN', 'No', '', '', ''],
            ['London Public Library', 'info@londonlibrary.co.uk', 'London', 'UK', 'Europa', 'Publica', 'EN', 'No', '', '', ''],
            # Francia
            ['Bibliothèque Nationale de France', 'contact@bnf.fr', 'Paris', 'Francia', 'Europa', 'Nacional', 'FR', 'No', '', '', ''],
            ['Bibliothèque Publique de Paris', 'bibliotheque@paris.fr', 'Paris', 'Francia', 'Europa', 'Publica', 'FR', 'No', '', '', ''],
            # Italia
            ['Biblioteca Nazionale Centrale di Roma', 'bncrm@beniculturali.it', 'Roma', 'Italia', 'Europa', 'Nacional', 'IT', 'No', '', '', ''],
            ['Biblioteca Nazionale di Milano', 'bnm@beniculturali.it', 'Milán', 'Italia', 'Europa', 'Nacional', 'IT', 'No', '', '', ''],
            # Canadá
            ['Toronto Public Library', 'collections@tpl.ca', 'Toronto', 'Canadá', 'Norte America', 'Publica', 'EN', 'No', '', '', ''],
            ['Vancouver Public Library', 'info@vpl.ca', 'Vancouver', 'Canadá', 'Norte America', 'Publica', 'EN', 'No', '', '', ''],
        ]
        
        with open(self.libraries_db, 'w', newline='', encoding='utf-8') as f:
            writer = csv.writer(f)
            writer.writerows(template)
        
        print(f"✅ Template de bibliotecas creado: {self.libraries_db}")
    
    def load_libraries(self, region=None, language=None, only_new=True):
        """Carga lista de bibliotecas con filtros"""
        self.create_library_template()
        
        libraries = []
        try:
            with open(self.libraries_db, 'r', encoding='utf-8') as f:
                reader = csv.DictReader(f)
                for row in reader:
                    # Filtro por región
                    if region and row.get('region') != region:
                        continue
                    
                    # Filtro por idioma preferido
                    if language and row.get('idioma_preferido') != language:
                        continue
                    
                    # Solo no contactados
                    if only_new and row.get('contactado') == 'Si':
                        continue
                    
                    libraries.append(row)
        except Exception as e:
            print(f"Error cargando bibliotecas: {e}")
        
        return libraries
    
    def generate_email(self, library, language=None):
        """Genera email personalizado para biblioteca"""
        # Determinar idioma
        if not language:
            language = library.get('idioma_preferido', 'ES')
        
        template = self.templates.get(language, self.templates['ES'])
        
        # Personalizar
        nombre = library.get('nombre', 'Bibliotecario/a')
        email_body = template['body'].format(nombre=nombre)
        
        return {
            'subject': template['subject'],
            'body': email_body,
            'language': language
        }
    
    def track_contact(self, library_email, status, notes=""):
        """Registra contacto en base de datos"""
        # Leer bibliotecas actuales
        libraries = []
        with open(self.libraries_db, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            libraries = list(reader)
        
        # Actualizar registro
        for lib in libraries:
            if lib['email'] == library_email:
                lib['contactado'] = 'Si'
                lib['fecha_contacto'] = datetime.now().strftime('%Y-%m-%d')
                lib['respuesta'] = status
                lib['notas'] = notes
                break
        
        # Guardar actualización
        with open(self.libraries_db, 'w', newline='', encoding='utf-8') as f:
            if libraries:
                writer = csv.DictWriter(f, fieldnames=libraries[0].keys())
                writer.writeheader()
                writer.writerows(libraries)
    
    def save_campaign(self, campaign_data):
        """Guarda información de campaña"""
        campaigns = []
        if os.path.exists(self.campaigns_db):
            with open(self.campaigns_db, 'r', encoding='utf-8') as f:
                campaigns = json.load(f)
        
        campaigns.append(campaign_data)
        
        with open(self.campaigns_db, 'w', encoding='utf-8') as f:
            json.dump(campaigns, f, indent=2, ensure_ascii=False)
    
    def batch_outreach(self, region=None, language=None, max_emails=50, dry_run=True):
        """Ejecuta campaña de outreach a bibliotecas"""
        libraries = self.load_libraries(region, language, only_new=True)
        
        if len(libraries) == 0:
            return {
                'status': 'no_libraries',
                'message': 'No hay bibliotecas disponibles con los filtros seleccionados'
            }
        
        campaign_results = []
        
        print(f"📚 Preparando campaña para {min(len(libraries), max_emails)} bibliotecas...")
        print(f"   Región: {region or 'Todas'}")
        print(f"   Idioma: {language or 'Auto-detect'}")
        print(f"   Modo: {'Simulación' if dry_run else 'Envío real'}")
        print()
        
        for i, library in enumerate(libraries[:max_emails]):
            email_data = self.generate_email(library, language)
            
            result = {
                'biblioteca': library['nombre'],
                'email': library['email'],
                'ciudad': library['ciudad'],
                'pais': library['pais'],
                'idioma': email_data['language'],
                'asunto': email_data['subject'],
                'estado': 'simulado' if dry_run else 'enviado',
                'fecha': datetime.now().isoformat()
            }
            
            campaign_results.append(result)
            
            if not dry_run:
                # Aquí iría el envío real de email
                # send_email(library['email'], email_data['subject'], email_data['body'])
                self.track_contact(library['email'], 'enviado')
            
            print(f"  [{i+1}] {library['nombre']} ({library['ciudad']}, {library['pais']})")
            print(f"      → {library['email']}")
            print(f"      Idioma: {email_data['language']}")
            print()
        
        # Guardar reporte de campaña
        campaign_data = {
            'id': datetime.now().strftime('%Y%m%d_%H%M%S'),
            'fecha': datetime.now().isoformat(),
            'region': region,
            'idioma': language,
            'total_enviados': len(campaign_results),
            'modo': 'simulacion' if dry_run else 'real',
            'resultados': campaign_results
        }
        
        self.save_campaign(campaign_data)
        
        # Guardar CSV de resultados
        report_file = os.path.join(
            self.reports_dir, 
            f"library_campaign_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv"
        )
        
        with open(report_file, 'w', newline='', encoding='utf-8') as f:
            if campaign_results:
                writer = csv.DictWriter(f, fieldnames=campaign_results[0].keys())
                writer.writeheader()
                writer.writerows(campaign_results)
        
        return {
            'status': 'success',
            'total_enviados': len(campaign_results),
            'report_file': report_file,
            'campaign_data': campaign_data
        }
    
    def get_campaign_stats(self):
        """Obtiene estadísticas de campañas"""
        if not os.path.exists(self.campaigns_db):
            return {'message': 'No hay campañas registradas'}
        
        with open(self.campaigns_db, 'r', encoding='utf-8') as f:
            campaigns = json.load(f)
        
        total_enviados = sum(c['total_enviados'] for c in campaigns)
        
        stats = {
            'total_campañas': len(campaigns),
            'total_emails_enviados': total_enviados,
            'campañas_por_region': {},
            'campañas_por_idioma': {}
        }
        
        for c in campaigns:
            region = c.get('region', 'Desconocida') or 'Todas'
            idioma = c.get('idioma', 'Auto') or 'Auto'
            
            stats['campañas_por_region'][region] = stats['campañas_por_region'].get(region, 0) + 1
            stats['campañas_por_idioma'][idioma] = stats['campañas_por_idioma'].get(idioma, 0) + 1
        
        return stats
    
    def generate_catalog_pdf(self):
        """Genera catálogo PDF para adjuntar (placeholder)"""
        # Esta función requeriría una librería como reportlab
        # Por ahora, generamos un resumen en texto
        
        catalog = """
CATÁLOGO FRANCISCO ANGULO DE LAFUENTE
======================================

CIENCIA FICCIÓN:
- ApocalypsAI: The Day After AGI
- [ISBN] - Disponible en: ES, EN, FR

THRILLER:
- Comandante Valentina Smirnova (Serie)
- [ISBN] - Disponible en: ES, EN, FR, IT, PT

NO FICCIÓN:
- Things you shouldn't do if you want to be a writer
- Eco-fuel-FA (ECOFA)
- [ISBNs] - Disponible en: ES, EN

INFANTIL/JUVENIL:
- La Invasión de las Medusas Mutantes
- Company Nº12
- [ISBNs] - Disponible en: ES, EN, FR, IT, PT, JP

DISTRIBUCIÓN:
OverDrive, hoopla, cloudLibrary, Odilo, EBSCOhost, Mackin

CONTACTO:
agent@franciscoangulo.com
www.franciscoangulo.com
"""
        return catalog

if __name__ == "__main__":
    outreach = LibraryOutreach()
    
    print("📚 Sistema de Contacto a Bibliotecas")
    print("=" * 50)
    print()
    
    # Mostrar estadísticas
    stats = outreach.get_campaign_stats()
    if 'total_campañas' in stats:
        print(f"Campañas realizadas: {stats['total_campañas']}")
        print(f"Total emails enviados: {stats['total_emails_enviados']}")
    
    print()
    
    # Ejemplo: Simular campaña a bibliotecas de Europa
    print("🚀 Ejecutando campaña de prueba (modo simulación)...")
    result = outreach.batch_outreach(region="España", max_emails=5, dry_run=True)
    
    print()
    print("=" * 50)
    print(f"✅ Resultado: {result['total_enviados']} bibliotecas contactadas")
    print(f"📄 Reporte guardado en: {result['report_file']}")
