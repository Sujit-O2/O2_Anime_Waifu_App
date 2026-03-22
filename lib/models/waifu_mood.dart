enum WaifuMood {
  happy,
  sad,
  angry,
  jealous,
  playful,
  affectionate,
  sleepy,
  energetic,
  worried,
  neutral,
  possessive,
  tsundere,
  comforting,
}

extension WaifuMoodExtension on WaifuMood {
  String get displayName {
    switch (this) {
      case WaifuMood.happy:
        return 'Happy';
      case WaifuMood.sad:
        return 'Sad';
      case WaifuMood.angry:
        return 'Angry';
      case WaifuMood.jealous:
        return 'Jealous';
      case WaifuMood.playful:
        return 'Playful';
      case WaifuMood.affectionate:
        return 'Affectionate';
      case WaifuMood.sleepy:
        return 'Sleepy';
      case WaifuMood.energetic:
        return 'Energetic';
      case WaifuMood.worried:
        return 'Worried';
      case WaifuMood.neutral:
        return 'Neutral';
      case WaifuMood.possessive:
        return 'Possessive';
      case WaifuMood.tsundere:
        return 'Tsundere';
      case WaifuMood.comforting:
        return 'Comforting';
    }
  }

  String get emoji {
    switch (this) {
      case WaifuMood.happy:
        return '😊';
      case WaifuMood.sad:
        return '😢';
      case WaifuMood.angry:
        return '😠';
      case WaifuMood.jealous:
        return '😤';
      case WaifuMood.playful:
        return '😜';
      case WaifuMood.affectionate:
        return '🥰';
      case WaifuMood.sleepy:
        return '😴';
      case WaifuMood.energetic:
        return '⚡';
      case WaifuMood.worried:
        return '😟';
      case WaifuMood.neutral:
        return '😐';
      case WaifuMood.possessive:
        return '💢';
      case WaifuMood.tsundere:
        return '😳';
      case WaifuMood.comforting:
        return '🤗';
    }
  }

  double get ttsPitchModifier {
    switch (this) {
      case WaifuMood.happy:
      case WaifuMood.playful:
      case WaifuMood.energetic:
        return 1.1;
      case WaifuMood.sad:
      case WaifuMood.comforting:
        return 0.95;
      case WaifuMood.angry:
      case WaifuMood.jealous:
      case WaifuMood.possessive:
        return 0.95;
      case WaifuMood.sleepy:
        return 0.9;
      default:
        return 1.0;
    }
  }
}
