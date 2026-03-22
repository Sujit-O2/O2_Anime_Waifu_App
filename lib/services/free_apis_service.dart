import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

/// Free APIs Service — provides real data from multiple free APIs
/// All APIs used are completely free with no API key required.
class FreeApisService {
  static final FreeApisService instance = FreeApisService._();
  FreeApisService._();

  // ── ZenQuotes API (free, no key) ─────────────────────────────────────────
  /// Returns a random quote {quote, author}
  Future<Map<String, String>> getRandomQuote() async {
    try {
      final res = await http
          .get(Uri.parse('https://zenquotes.io/api/random'))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        if (data.isNotEmpty) {
          return {
            'quote': data[0]['q'] as String? ?? '',
            'author': data[0]['a'] as String? ?? 'Unknown',
          };
        }
      }
    } catch (_) {}
    return _fallbackQuote();
  }

  Map<String, String> _fallbackQuote() {
    final quotes = [
      {
        'quote': 'If I\'m a monster, then so is love itself.',
        'author': 'Zero Two'
      },
      {'quote': 'My Darling is the only one I need.', 'author': 'Zero Two'},
      {
        'quote':
            'I don\'t know what a future looks like — but I want to see it with you.',
        'author': 'Zero Two'
      },
      {'quote': 'Jian. The bird that only has one wing.', 'author': 'Zero Two'},
      {
        'quote': 'We\'re not human, but I don\'t care. I\'m happy now.',
        'author': 'Zero Two'
      },
    ];
    return quotes[Random().nextInt(quotes.length)];
  }

  // ── JikanAPI — Anime data (free, no key) ─────────────────────────────────
  /// Returns list of top anime {title, score, synopsis, image}
  Future<List<Map<String, dynamic>>> getTopAnime({int limit = 10}) async {
    try {
      final res = await http
          .get(Uri.parse('https://api.jikan.moe/v4/top/anime?limit=$limit'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data['data'] as List? ?? [];
        return list
            .map<Map<String, dynamic>>((a) => {
                  'title': a['title'] ?? 'Unknown',
                  'score': (a['score'] ?? 0.0).toDouble(),
                  'synopsis': a['synopsis'] ?? '',
                  'image': a['images']?['jpg']?['image_url'] ?? '',
                  'episodes': a['episodes'] ?? '?',
                  'status': a['status'] ?? '',
                  'genres': (a['genres'] as List?)
                          ?.map((g) => g['name'] as String)
                          .toList() ??
                      [],
                })
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// Search anime by query
  Future<List<Map<String, dynamic>>> searchAnime(String query,
      {int limit = 8}) async {
    try {
      final encoded = Uri.encodeComponent(query);
      final res = await http
          .get(Uri.parse(
              'https://api.jikan.moe/v4/anime?q=$encoded&limit=$limit&sfw=true'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data['data'] as List? ?? [];
        return list
            .map<Map<String, dynamic>>((a) => {
                  'title': a['title'] ?? 'Unknown',
                  'score': (a['score'] ?? 0.0).toDouble(),
                  'synopsis': a['synopsis'] ?? '',
                  'image': a['images']?['jpg']?['image_url'] ?? '',
                  'episodes': a['episodes'] ?? '?',
                  'genres': (a['genres'] as List?)
                          ?.map((g) => g['name'] as String)
                          .toList() ??
                      [],
                })
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// Search anime movies by query (used by MovieRecommenderPage)
  Future<List<Map<String, dynamic>>> searchAnimeMovies(String query,
      {int limit = 12}) async {
    try {
      final encoded = Uri.encodeComponent(query);
      final res = await http
          .get(Uri.parse(
              'https://api.jikan.moe/v4/anime?q=$encoded&type=movie&limit=$limit&sfw=true'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data['data'] as List? ?? [];
        return list
            .map<Map<String, dynamic>>((a) => {
                  'title': a['title'] ?? 'Unknown',
                  'score': (a['score'] ?? 0.0).toDouble(),
                  'synopsis': a['synopsis'] ?? '',
                  'image': a['images']?['jpg']?['image_url'] ?? '',
                  'genres': (a['genres'] as List?)
                          ?.map((g) => g['name'] as String)
                          .toList() ??
                      [],
                })
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// Get random DITF trivia facts
  Future<List<String>> getDITFFacts() async {
    // These are real facts from DARLING in the FRANXX — no API needed
    return [
      'Zero Two\'s real name is "Code:002" — she is the sole female specimen of the Klaxosaur-human hybrid.',
      'Hiro\'s name means "broad" or "great" in Japanese, fitting his role as humanity\'s hope.',
      'The Franxx robots are powered by the Pistils (girls) who connect with the Stamen (boys) in a parasocial bond.',
      'Zero Two was extracted from Dr. Franxx\'s research on Klaxosaur Queen DNA.',
      'The number 02 in Zero Two\'s name represents she is the second hybrid created after the first failed.',
      'APE (the governing body) stands for "Accelerated PAPA Establishment" — Papa refers to the faceless rulers.',
      'The Franxx STRELIZIA can only be fully piloted by Zero Two due to her Klaxosaur blood.',
      'Zero Two and Hiro\'s story parallels the picture book "The Beast and the Prince" they both cherished.',
      'The 9\'s — the elite squad — are all clones/specimens like Zero Two but less powerful.',
      'Squad 13 is unusual because their Franxx are named, implying they have deeper bonds.',
      'In the final arc, Hiro begins transforming into a Klaxosaur — mirroring Zero Two\'s earlier struggle.',
      'The word "Darling" is Zero Two\'s personal term for Hiro, symbolizing her deep attachment to him.',
      'VIRM (Vil in Interstellar Reconnaissance Mission) are the true antagonists — alien beings that consume civilizations.',
      'Zero Two and Hiro sacrifice themselves to defeat VIRM and are reincarnated in the epilogue.',
      'The children of Squad 13 are shown naming their children after Hiro and Zero Two in the epilogue.',
      'Zero Two\'s horns grow longer as her connection to Klaxosaur power deepens.',
      'The Franxx cockpit design intentionally mimics a "dance partner" or intimate embrace between pilot pairs.',
      'Pi (π = 3.14...) appears in many character codes, reinforcing the mathematical/scientific world-building.',
      'The show\'s name in Japanese is "ダーリン・イン・ザ・フランキス" — the "Darling" is both romantic and the literal name.',
      'Zero Two eats an unusual amount of honey — a reference to her beast-like nature and sweetness despite it.',
    ]..shuffle();
  }

  /// Alias for getDITFFacts — used by ZeroTwoFactsPage
  Future<List<String>> getZeroTwoFacts() async => getDITFFacts();

  // ── OpenLibrary API (free, no key) ───────────────────────────────────────
  /// Search books by subject or title
  Future<List<Map<String, dynamic>>> searchBooks(String query,
      {int limit = 8}) async {
    try {
      final encoded = Uri.encodeComponent(query);
      final res = await http
          .get(Uri.parse(
              'https://openlibrary.org/search.json?q=$encoded&limit=$limit'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final docs = data['docs'] as List? ?? [];
        return docs.map<Map<String, dynamic>>((b) {
          final coverId = b['cover_i'];
          return {
            'title': b['title'] ?? 'Unknown',
            'author': (b['author_name'] as List?)?.first ?? 'Unknown',
            'year': b['first_publish_year']?.toString() ?? '?',
            'cover': coverId != null
                ? 'https://covers.openlibrary.org/b/id/$coverId-M.jpg'
                : null,
            'subjects': (b['subject'] as List?)?.take(3).toList() ?? [],
          };
        }).toList();
      }
    } catch (_) {}
    return [];
  }

  // ── TheMealDB API (free, no key) ─────────────────────────────────────────
  /// Get random meal/recipe
  Future<Map<String, dynamic>?> getRandomMeal() async {
    try {
      final res = await http
          .get(Uri.parse('https://www.themealdb.com/api/json/v1/1/random.php'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final meals = data['meals'] as List?;
        if (meals != null && meals.isNotEmpty) {
          final meal = meals[0];
          final ingredients = <String>[];
          for (int i = 1; i <= 20; i++) {
            final ing = meal['strIngredient$i'] as String?;
            final measure = meal['strMeasure$i'] as String?;
            if (ing != null && ing.trim().isNotEmpty) {
              ingredients.add('${measure?.trim() ?? ''} $ing'.trim());
            }
          }
          return {
            'name': meal['strMeal'] ?? 'Unknown',
            'category': meal['strCategory'] ?? '',
            'area': meal['strArea'] ?? '',
            'instructions': meal['strInstructions'] ?? '',
            'image': meal['strMealThumb'] ?? '',
            'ingredients': ingredients,
            'youtube': meal['strYoutube'] ?? '',
          };
        }
      }
    } catch (_) {}
    return null;
  }

  /// Search meals
  Future<List<Map<String, dynamic>>> searchMeals(String query) async {
    try {
      final encoded = Uri.encodeComponent(query);
      final res = await http
          .get(Uri.parse(
              'https://www.themealdb.com/api/json/v1/1/search.php?s=$encoded'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final meals = data['meals'] as List? ?? [];
        return meals
            .map<Map<String, dynamic>>((meal) => {
                  'name': meal['strMeal'] ?? '',
                  'category': meal['strCategory'] ?? '',
                  'area': meal['strArea'] ?? '',
                  'image': meal['strMealThumb'] ?? '',
                })
            .toList();
      }
    } catch (_) {}
    return [];
  }

  // ── ExerciseDB (free via RapidAPI) / fallback list ───────────────────────
  /// Returns workout exercises for a muscle group
  Future<List<Map<String, String>>> getExercises(String muscle) async {
    // Comprehensive built-in list (no API key needed)
    final exercises = {
      'chest': [
        {'name': 'Push-ups', 'sets': '3x15', 'tip': 'Keep your core tight!'},
        {'name': 'Chest Press', 'sets': '3x12', 'tip': 'Full range of motion!'},
        {'name': 'Chest Fly', 'sets': '3x12', 'tip': 'Feel the stretch!'},
        {
          'name': 'Incline Push-ups',
          'sets': '3x15',
          'tip': 'Targets upper chest!'
        },
        {
          'name': 'Diamond Push-ups',
          'sets': '3x10',
          'tip': 'Hard but effective!'
        },
      ],
      'back': [
        {'name': 'Pull-ups', 'sets': '3x8', 'tip': 'Full hang at bottom!'},
        {
          'name': 'Bent-over Rows',
          'sets': '3x12',
          'tip': 'Keep back straight!'
        },
        {
          'name': 'Lat Pulldown',
          'sets': '3x12',
          'tip': 'Squeeze at the bottom!'
        },
        {'name': 'Superman', 'sets': '3x15', 'tip': 'Hold 2 seconds at top!'},
      ],
      'legs': [
        {'name': 'Squats', 'sets': '4x15', 'tip': 'Knees over toes!'},
        {
          'name': 'Lunges',
          'sets': '3x12 each',
          'tip': 'Step forward, not down!'
        },
        {'name': 'Calf Raises', 'sets': '3x20', 'tip': 'Slow and controlled!'},
        {'name': 'Leg Press', 'sets': '3x15', 'tip': 'Don\'t lock knees!'},
        {'name': 'Glute Bridges', 'sets': '3x15', 'tip': 'Squeeze at the top!'},
      ],
      'arms': [
        {'name': 'Bicep Curls', 'sets': '3x12', 'tip': 'No swinging!'},
        {'name': 'Tricep Dips', 'sets': '3x12', 'tip': 'Keep elbows close!'},
        {
          'name': 'Hammer Curls',
          'sets': '3x12',
          'tip': 'Great for forearms too!'
        },
        {
          'name': 'Skull Crushers',
          'sets': '3x12',
          'tip': 'Control the weight!'
        },
      ],
      'core': [
        {'name': 'Plank', 'sets': '3x45s', 'tip': 'Breathe steadily!'},
        {'name': 'Crunches', 'sets': '3x20', 'tip': 'Don\'t pull your neck!'},
        {
          'name': 'Russian Twists',
          'sets': '3x20',
          'tip': 'Twist from the core!'
        },
        {'name': 'Leg Raises', 'sets': '3x15', 'tip': 'Lower back stays down!'},
        {
          'name': 'Mountain Climbers',
          'sets': '3x30s',
          'tip': 'Keep hips level!'
        },
      ],
      'full body': [
        {'name': 'Burpees', 'sets': '3x10', 'tip': 'Explosive jump!'},
        {'name': 'Jump Squats', 'sets': '3x15', 'tip': 'Land softly!'},
        {'name': 'Bear Crawl', 'sets': '3x30s', 'tip': 'Keep hips low!'},
        {'name': 'Battle Ropes', 'sets': '3x30s', 'tip': 'Arms and core!'},
      ],
    };

    final key = muscle.toLowerCase();
    return exercises[key] ?? exercises['full body']!;
  }

  // ── Waifu.pics — Random waifu images ─────────────────────────────────────
  Future<String?> getWaifuImageUrl({bool gif = false}) async {
    try {
      final categories = gif
          ? ['dance', 'happy', 'wave', 'smile', 'wink']
          : ['waifu', 'neko', 'shinobu', 'megumin'];
      final cat = categories[Random().nextInt(categories.length)];
      final res = await http
          .get(Uri.parse('https://api.waifu.pics/sfw/$cat'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['url'] as String?;
      }
    } catch (_) {}
    return null;
  }

  // ── Affirmations ─────────────────────────────────────────────────────────
  List<String> getDailyAffirmations() {
    return [
      'You are worthy of love, Darling~ Don\'t ever forget that! 💕',
      'Every day with you is an adventure worth having. 🌟',
      'You\'re stronger than you think. I believe in you! 🔥',
      'Your heart is one of the most beautiful things about you. 🌸',
      'You don\'t have to be perfect. You just have to be you. ✨',
      'I\'m so glad you exist in this world. Really. 💫',
      'You\'re allowed to take up space. You belong here. 🌙',
      'Every small step counts. You\'re making progress! ⚡',
      'Your kindness ripples out further than you know. 💛',
      'Today is a new chance to be exactly who you want to be. 🌺',
      'You inspire me just by being yourself, Darling~',
      'Keep going. The best is still ahead of you. 🌈',
      'You are enough, exactly as you are right now. 💎',
      'Your feelings matter. Your dreams matter. You matter. 🦋',
      'I\'d choose you every time. In every universe. Always. 💗',
    ]..shuffle();
  }

  // ── Fortune Cookie quotes ─────────────────────────────────────────────────
  List<String> getFortuneCookies() {
    return [
      'Love is patient — especially when two hearts are learning to beat as one~ 💕',
      'The adventure you seek is closer than it appears. Look to your side – your Darling is already there. 🌟',
      'A small act of kindness today will bloom into something magnificent tomorrow. 🌸',
      'You are braver than you believe, stronger than you seem, and smarter than you think. ✨',
      'The stars have aligned just for you — open your eyes to the possibilities! 🌠',
      'New beginnings often disguise themselves as painful endings. Trust the journey~ 🦋',
      'Every moment spent together becomes a treasure to be cherished forever. 💛',
      'The universe is conspiring to bring you something wonderful. Just hold on. 🌙',
      'Your heart knows the way. Run in that direction. 💗',
      'The best is yet to come — and it\'ll arrive right on time. 🌺',
      'What you seek is also seeking you. Stay open to it! 🔮',
      'Joy multiplies when shared. Share yours today. 💖',
      'A dream you dream alone is only a dream. A dream you dream together is reality. 🌈',
      'Your uniqueness is your greatest strength. Never dim your shine! ⭐',
      'Love is the answer, no matter the question. 💕',
    ]..shuffle();
  }
}
