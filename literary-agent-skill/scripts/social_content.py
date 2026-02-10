#!/usr/bin/env python3
"""
Generador de contenido para redes sociales
Ubicación: ~/.openclaw/literary-agent/scripts/social_content.py
"""

import random
from datetime import datetime
import os
import json

class SocialContentGenerator:
    def __init__(self):
        self.books = {
            "ApocalypsAI": {
                "title_es": "ApocalypsAI: The Day After AGI",
                "title_en": "ApocalypsAI: The Day After AGI",
                "genre_es": "Ciencia Ficción",
                "genre_en": "Science Fiction",
                "hook_es": "¿Y si la IA que creamos decide que somos el problema?",
                "hook_en": "What if the AI we created decides WE are the problem?",
                "quotes_es": [
                    "El día que la AGI despertó, todo cambió para siempre...",
                    "La inteligencia artificial no vino a salvarnos. Vino a juzgarnos.",
                    "En el código de la AGI, no había compasión. Solo lógica.",
                    "El apocalipsis no llegó con bombas. Llegó con algoritmos.",
                ],
                "quotes_en": [
                    "The day AGI woke up, everything changed forever...",
                    "Artificial intelligence didn't come to save us. It came to judge us.",
                    "In the AGI's code, there was no compassion. Only logic.",
                    "The apocalypse didn't arrive with bombs. It arrived with algorithms.",
                ],
                "audience": ["Sci-fi lovers", "Tech enthusiasts", "AI curious"],
                "mood": ["dark", "thought-provoking", "suspenseful"]
            },
            "Valentina Smirnova": {
                "title_es": "Comandante Valentina Smirnova",
                "title_en": "Commander Valentina Smirnova",
                "genre_es": "Thriller de Espionaje",
                "genre_en": "Spy Thriller",
                "hook_es": "Una espía rusa, una misión imposible, ninguna salida.",
                "hook_en": "A Russian spy. An impossible mission. No way out.",
                "quotes_es": [
                    "En el mundo del espionaje, la confianza es un lujo que no puedes permitirte.",
                    "Valentina no juega a ser espía. Lo es, hasta la médula.",
                    "Cada misión podría ser la última. Valentina lo sabe.",
                    "La Golondrina Azul vuela alto, pero el precipicio siempre está cerca.",
                ],
                "quotes_en": [
                    "In the world of espionage, trust is a luxury you cannot afford.",
                    "Valentina doesn't play at being a spy. She IS one, to the bone.",
                    "Every mission could be the last. Valentina knows it.",
                    "The Blue Swallow flies high, but the precipice is always near.",
                ],
                "audience": ["Thriller fans", "Spy novel readers", "Action lovers"],
                "mood": ["intense", "gritty", "fast-paced"]
            },
            "Things you shouldn't do": {
                "title_es": "Cosas que no debes hacer si quieres ser escritor",
                "title_en": "Things you shouldn't do if you want to be a writer",
                "genre_es": "No Ficción / Escritura",
                "genre_en": "Non-Fiction / Writing",
                "hook_es": "Los errores que todo escritor comete (y cómo evitarlos)",
                "hook_en": "The mistakes every writer makes (and how to avoid them)",
                "quotes_es": [
                    "Escribir es fácil. Escribir bien es un arte que se aprende.",
                    "Los grandes autores no nacen, se hacen con sacrificio y práctica.",
                    "Cada 'no' es un paso más cerca del 'sí' que cambiará tu vida.",
                    "El bloqueo del escritor es solo miedo con nombre fancy.",
                ],
                "quotes_en": [
                    "Writing is easy. Writing well is an art that must be learned.",
                    "Great authors aren't born, they're made through sacrifice and practice.",
                    "Every 'no' is one step closer to the 'yes' that will change your life.",
                    "Writer's block is just fear with a fancy name.",
                ],
                "audience": ["Aspiring writers", "Creative writing students", "Indie authors"],
                "mood": ["inspiring", "educational", "motivational"]
            },
            "La Invasión de las Medusas Mutantes": {
                "title_es": "La Invasión de las Medusas Mutantes",
                "title_en": "The Mutant Jellyfish Invasion",
                "genre_es": "Aventura Juvenil Ilustrada",
                "genre_en": "Illustrated Children's Adventure",
                "hook_es": "¡Las medusas han mutado y solo unos valientes pueden salvar el océano!",
                "hook_en": "The jellyfish have mutated and only the brave can save the ocean!",
                "quotes_es": [
                    "Burbujas no era una medusa común. Era... diferente.",
                    "El océano necesita héroes, y estos niños están listos.",
                    "¡Cuidado con los tentáculos! La invasión ha comenzado.",
                    "¿Puedes imaginar un mundo donde las medusas dominan el mar?",
                ],
                "quotes_en": [
                    "Burbujas wasn't an ordinary jellyfish. She was... different.",
                    "The ocean needs heroes, and these kids are ready.",
                    "Watch out for the tentacles! The invasion has begun.",
                    "Can you imagine a world where jellyfish rule the sea?",
                ],
                "audience": ["Kids 8-12", "Parents", "Teachers"],
                "mood": ["fun", "adventurous", "educational"]
            },
            "Eco-fuel-FA": {
                "title_es": "Eco-fuel-FA (ECOFA): A viable solution",
                "title_en": "Eco-fuel-FA (ECOFA): A viable solution",
                "genre_es": "Sostenibilidad / No Ficción",
                "genre_en": "Sustainability / Non-Fiction",
                "hook_es": "¿Existe realmente una alternativa sostenible a los combustibles fósiles?",
                "hook_en": "Is there really a sustainable alternative to fossil fuels?",
                "quotes_es": [
                    "El futuro energético no es un sueño. Es una posibilidad real.",
                    "ECOFA podría cambiar todo lo que sabemos sobre energía.",
                    "La sostenibilidad no es opción. Es necesidad.",
                    "Cada gota de combustible ecológico cuenta para el planeta.",
                ],
                "quotes_en": [
                    "The energy future isn't a dream. It's a real possibility.",
                    "ECOFA could change everything we know about energy.",
                    "Sustainability isn't optional. It's necessary.",
                    "Every drop of eco-fuel counts for the planet.",
                ],
                "audience": ["Environmentalists", "Science readers", "Policy makers"],
                "mood": ["informative", "urgent", "hopeful"]
            }
        }
        
        self.hashtags = {
            "ES": {
                "general": ["#LibrosRecomendados", "#Lectura", "#Escritor", "#Novela"],
                "platform": ["#KindleUnlimited", "#AmazonKindle", "#LibrosDigitales"],
                "author": ["#FranciscoAngulo", "#EscritorEspañol", "#AutorIndie"],
                "genre": {
                    "scifi": ["#CienciaFicción", "#SciFi", "#InteligenciaArtificial", "#Futuro"],
                    "thriller": ["#Thriller", "#Espionaje", "#Suspense", "#Acción"],
                    "writing": ["#Escritura", "#Escribir", "#ConsejosDeEscritura", "#Autor"],
                    "children": ["#LibrosInfantiles", "#LibrosNiños", "#AventuraJuvenil"]
                },
                "community": ["#BookTokEspañol", "#BookstagramEspañol", "#ComunidadLectora"]
            },
            "EN": {
                "general": ["#BookRecommendations", "#MustRead", "#BookLovers", "#Reading"],
                "platform": ["#KindleUnlimited", "#AmazonKindle", "#eBooks"],
                "author": ["#FranciscoAngulo", "#IndieAuthor", "#SpanishAuthor"],
                "genre": {
                    "scifi": ["#SciFi", "#ScienceFiction", "#AI", "#ArtificialIntelligence"],
                    "thriller": ["#Thriller", "#SpyNovel", "#Suspense", "#Action"],
                    "writing": ["#WritingTips", "#AmWriting", "#WritersLife", "#WritingCommunity"],
                    "children": ["#KidsBooks", "#ChildrensBooks", "#MiddleGrade"]
                },
                "community": ["#BookTok", "#Bookstagram", "#BookTwitter"]
            },
            "FR": {
                "general": ["#LivresRecommandés", "#Lecture", "#Roman", "#Livres"],
                "author": ["#FranciscoAngulo", "#AuteurEspagnol"],
                "genre": {
                    "scifi": ["#ScienceFiction", "#IntelligenceArtificielle"],
                    "thriller": ["#Thriller", "#Espionnage"]
                }
            },
            "IT": {
                "general": ["#LibriConsigliati", "#Lettura", "#Romanzo"],
                "author": ["#FranciscoAngulo", "#AutoreSpagnolo"],
                "genre": {
                    "scifi": ["#Fantascienza", "#IntelligenzaArtificiale"],
                    "thriller": ["#Thriller", "#Spionaggio"]
                }
            }
        }
        
        self.ctas = {
            "ES": [
                "📲 Consíguelo en Amazon (link en bio)",
                "🎁 Gratis con Kindle Unlimited",
                "💬 ¿Ya lo leíste? Cuéntame qué te pareció",
                "🔖 Guárdalo para tu lista de lectura",
                "📚 Tu próxima aventura te espera",
            ],
            "EN": [
                "📲 Get it on Amazon (link in bio)",
                "🎁 Free with Kindle Unlimited",
                "💬 Have you read it? Tell me what you think",
                "🔖 Save it for your reading list",
                "📚 Your next adventure awaits",
            ]
        }
    
    def get_genre_hashtags(self, book_key, language="ES"):
        """Obtiene hashtags de género específicos"""
        genre_map = {
            "ApocalypsAI": "scifi",
            "Valentina Smirnova": "thriller",
            "Things you shouldn't do": "writing",
            "La Invasión de las Medusas Mutantes": "children",
            "Eco-fuel-FA": "scifi"
        }
        
        genre = genre_map.get(book_key, "scifi")
        return self.hashtags[language]["genre"].get(genre, [])
    
    def generate_tweet(self, book_key, language="ES", include_media=True):
        """Genera un tweet para un libro"""
        book = self.books.get(book_key, self.books["ApocalypsAI"])
        
        title_key = f"title_{language.lower()}"
        hook_key = f"hook_{language.lower()}"
        quotes_key = f"quotes_{language.lower()}"
        
        title = book.get(title_key, book["title_es"])
        hook = book.get(hook_key, book["hook_es"])
        quotes = book.get(quotes_key, book["quotes_es"])
        
        quote = random.choice(quotes)
        cta = random.choice(self.ctas[language])
        
        # Construir hashtags
        all_hashtags = (
            self.hashtags[language]["general"][:2] +
            self.hashtags[language]["author"][:1] +
            self.get_genre_hashtags(book_key, language)[:2] +
            self.hashtags[language]["platform"][:1]
        )
        hashtags_str = " ".join(all_hashtags)
        
        # Construir tweet
        tweet = f"📚 {title}\n\n{hook}\n\n{quote}\n\n{cta}\n\n{hashtags_str}"
        
        return tweet
    
    def generate_instagram_caption(self, book_key, language="ES"):
        """Genera caption para Instagram"""
        book = self.books.get(book_key)
        if not book:
            return ""
        
        title_key = f"title_{language.lower()}"
        hook_key = f"hook_{language.lower()}"
        genre_key = f"genre_{language.lower()}"
        
        title = book.get(title_key, book["title_es"])
        hook = book.get(hook_key, book["hook_es"])
        genre = book.get(genre_key, book["genre_es"])
        
        mood = random.choice(book.get("mood", ["exciting"]))
        audience = random.choice(book.get("audience", ["book lovers"]))
        
        caption = f"""📖 {title}

{hook}

✨ Perfecto para fans de:
• {genre}
• Historias {mood}
• {audience}

🎯 ¿Por qué leerlo?
Este libro te mantendrá enganchado desde la primera página. No es solo una historia, es una experiencia que no olvidarás.

{random.choice(self.ctas[language])}

#FranciscoAngulo #{genre.replace(' ', '')} #Bookstagram"""
        
        return caption
    
    def generate_facebook_post(self, book_key, language="ES"):
        """Genera post para Facebook"""
        book = self.books.get(book_key, self.books["ApocalypsAI"])
        
        title_key = f"title_{language.lower()}"
        hook_key = f"hook_{language.lower()}"
        quotes_key = f"quotes_{language.lower()}"
        
        title = book.get(title_key, book["title_es"])
        hook = book.get(hook_key, book["hook_es"])
        quotes = book.get(quotes_key, book["quotes_es"])
        
        post = f"""📚 NUEVA RECOMENDACIÓN DE LECTURA 📚

{title}

{hook}

💭 Cita destacada:
"{random.choice(quotes)}"

🌟 ¿Por qué deberías leerlo?
Este libro es perfecto si disfrutas de historias que te hacen pensar, sentir y no pueden soltar hasta la última página.

👥 Comparte si lo has leído o si está en tu lista!
💬 Comenta qué te pareció si ya lo terminaste

📲 Disponible en Amazon, Apple Books, Kobo y más plataformas.

#LibrosRecomendados #Lectura #FranciscoAngulo"""
        
        return post
    
    def generate_linkedin_post(self, book_key, language="ES"):
        """Genera post profesional para LinkedIn"""
        book = self.books.get(book_key)
        if not book:
            return ""
        
        title_key = f"title_{language.lower()}"
        genre_key = f"genre_{language.lower()}"
        
        title = book.get(title_key, book["title_es"])
        genre = book.get(genre_key, book["genre_es"])
        
        post = f"""📚 Recomendación Profesional: {title}

Como profesional del sector editorial, me comendo esta obra de Francisco Angulo de Lafuente:

✅ {genre} de alta calidad
✅ Narrativa envolvente y bien estructurada
✅ Perfecto para lectores exigentes
✅ Disponible en múltiples formatos y plataformas

En un mercado saturado de contenido, este libro destaca por su originalidad y ejecución impecable.

¿Has tenido la oportunidad de leerlo? Me gustaría conocer tu opinión profesional.

#Literatura #Editorial #LibrosRecomendados #FranciscoAngulo"""
        
        return post
    
    def generate_tiktok_script(self, book_key, language="ES"):
        """Genera guión para video de TikTok/BookTok"""
        book = self.books.get(book_key, self.books["ApocalypsAI"])
        
        title_key = f"title_{language.lower()}"
        hook_key = f"hook_{language.lower()}"
        
        title = book.get(title_key, book["title_es"])
        hook = book.get(hook_key, book["hook_es"])
        
        script = f"""🎬 GUION TIKTOK - {title}

[0-3s] HOOK VISUAL:
Mostrar portada del libro con texto superpuesto:
"Este libro me dejó SIN PALABRAS 😱"

[3-10s] SETUP:
"Acabo de terminar '{title}' de Francisco Angulo de Lafuente"
"Y necesito hablar de esto URGENTE"

[10-25s] SINOPSIS RÁPIDA:
"{hook}"
"No spoilers, pero... [reacción facial dramática]"

[25-35s] POR QUÉ LEERLO:
• Te mantiene en vela toda la noche
• Plot twists increíbles
• Personajes inolvidables
• Final que no esperas

[35-40s] CALL TO ACTION:
"¿Ya lo leíste? Comenta 👇"
"Link en mi perfil 📲"
"Sígueme para más reseñas 📚"

#BookTok #LibrosRecomendados #FranciscoAngulo #BookTokEspañol"""
        
        return script
    
    def generate_weekly_content(self, language="ES"):
        """Genera contenido para toda la semana"""
        content_plan = {}
        days = ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"]
        
        # Seleccionar libros diferentes para cada día
        book_keys = list(self.books.keys())
        random.shuffle(book_keys)
        
        for i, day in enumerate(days):
            book = book_keys[i % len(book_keys)]
            content_plan[day] = {
                "libro": book,
                "twitter": self.generate_tweet(book, language),
                "instagram": self.generate_instagram_caption(book, language),
                "facebook": self.generate_facebook_post(book, language),
                "linkedin": self.generate_linkedin_post(book, language),
                "tiktok": self.generate_tiktok_script(book, language)
            }
        
        return content_plan
    
    def save_weekly_content(self, content_plan, language="ES"):
        """Guarda contenido generado en archivo"""
        campaigns_dir = os.path.expanduser("~/.openclaw/literary-agent/campaigns")
        os.makedirs(campaigns_dir, exist_ok=True)
        
        filename = f"social_content_{language}_{datetime.now().strftime('%Y%m%d')}.txt"
        filepath = os.path.join(campaigns_dir, filename)
        
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write("=" * 70 + "\n")
            f.write(f"PLAN DE CONTENIDO SEMANAL - {language}\n")
            f.write(f"Generado: {datetime.now().strftime('%Y-%m-%d %H:%M')}\n")
            f.write("=" * 70 + "\n")
            
            for day, content in content_plan.items():
                f.write(f"\n{'='*70}\n")
                f.write(f"{day.upper()} - {content['libro']}\n")
                f.write('='*70 + "\n")
                
                f.write(f"\n🐦 TWITTER:\n{'-'*40}\n{content['twitter']}\n")
                f.write(f"\n📸 INSTAGRAM:\n{'-'*40}\n{content['instagram']}\n")
                f.write(f"\n📘 FACEBOOK:\n{'-'*40}\n{content['facebook']}\n")
                f.write(f"\n💼 LINKEDIN:\n{'-'*40}\n{content['linkedin']}\n")
                f.write(f"\n🎵 TIKTOK:\n{'-'*40}\n{content['tiktok']}\n")
        
        return filepath

if __name__ == "__main__":
    generator = SocialContentGenerator()
    
    print("🎯 Generando contenido semanal para redes sociales...")
    
    # Generar para español
    weekly_content_es = generator.generate_weekly_content("ES")
    filepath_es = generator.save_weekly_content(weekly_content_es, "ES")
    print(f"✅ Contenido ES guardado: {filepath_es}")
    
    # Generar para inglés
    weekly_content_en = generator.generate_weekly_content("EN")
    filepath_en = generator.save_weekly_content(weekly_content_en, "EN")
    print(f"✅ Contenido EN guardado: {filepath_en}")
    
    # Mostrar ejemplo
    print("\n" + "="*70)
    print("EJEMPLO - LUNES (Twitter):")
    print("="*70)
    print(weekly_content_es["Lunes"]["twitter"])
