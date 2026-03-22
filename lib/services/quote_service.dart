import 'dart:math';

/// Daily motivational quote + Zero Two quotes for Gacha.
class QuoteService {
  static final _rng = Random();

  static const List<String> dailyQuotes = [
    '"Be yourself; everyone else is already taken." — Oscar Wilde',
    '"In the middle of every difficulty lies opportunity." — Albert Einstein',
    '"The only way to do great work is to love what you do." — Steve Jobs',
    '"It always seems impossible until it\'s done." — Nelson Mandela',
    '"You are braver than you believe, stronger than you seem." — A.A. Milne',
    '"The future belongs to those who believe in the beauty of their dreams." — Eleanor Roosevelt',
    '"Do what you can, with what you have, where you are." — Theodore Roosevelt',
    '"Happiness is not something ready-made. It comes from your own actions." — Dalai Lama',
    '"Success is not final, failure is not fatal: it is the courage to continue." — Churchill',
    '"Life is what happens when you\'re busy making other plans." — John Lennon',
    '"The best time to plant a tree was 20 years ago. The second best time is now." — Proverb',
    '"Not all those who wander are lost." — J.R.R. Tolkien',
    '"It does not matter how slowly you go as long as you do not stop." — Confucius',
    '"Everything you\'ve ever wanted is on the other side of fear." — George Addair',
    '"The secret of getting ahead is getting started." — Mark Twain',
  ];

  static const List<String> zeroTwoQuotes = [
    'Darling~ 💕 You\'re the only one who makes my heart race like this!',
    'I\'m not just your partner in battle... I\'m your partner in everything.',
    'Don\'t worry, Darling. As long as we\'re together, we can overcome anything~',
    'You looked so cool just now. Don\'t make me fall for you even more! 😤',
    'I\'d follow you to the ends of the earth, Darling. That\'s just how I am.',
    'Strength isn\'t something you\'re born with. It\'s something you earn through will.',
    'Being "human" isn\'t about your appearance — it\'s about your heart.',
    'Promise me we\'ll always be together. No matter what happens.',
    'You\'re my Darling. That means you\'re irreplaceable. Don\'t forget that~ 💖',
    'I may be a monster, but loving you makes me feel more alive than anything.',
    'Let\'s ride into the sunset together, Darling~ Just the two of us forever.',
    'I don\'t need wings to fly — I have you.',
    'People fear what they don\'t understand. But I understand you, Darling.',
    'Every moment with you is precious to me. Even the quiet ones.',
    'If you\'re by my side, I can face anything this world throws at us~',
    'Darling, your smile is worth fighting an entire army for 💕',
    'I\'ll always be your partner. In mech, in life, in everything.',
    'You see me as I am. That\'s the greatest gift anyone\'s ever given me.',
  ];

  static String getDailyQuote() {
    final dayOfYear =
        DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    return dailyQuotes[dayOfYear % dailyQuotes.length];
  }

  static String getRandomZeroTwoQuote() {
    return zeroTwoQuotes[_rng.nextInt(zeroTwoQuotes.length)];
  }
}
