enum RelationshipStage {
  stranger,
  acquaintance,
  friend,
  closeFriend,
  crush,
  dating,
  partner,
  lover,
  devoted,
  soulmate,
}

extension RelationshipStageExtension on RelationshipStage {
  String get displayName {
    switch (this) {
      case RelationshipStage.stranger:
        return 'Stranger';
      case RelationshipStage.acquaintance:
        return 'Acquaintance';
      case RelationshipStage.friend:
        return 'Friend';
      case RelationshipStage.closeFriend:
        return 'Close Friend';
      case RelationshipStage.crush:
        return 'Crush';
      case RelationshipStage.dating:
        return 'Dating';
      case RelationshipStage.partner:
        return 'Partner';
      case RelationshipStage.lover:
        return 'Lover';
      case RelationshipStage.devoted:
        return 'Devoted';
      case RelationshipStage.soulmate:
        return 'Soulmate';
    }
  }

  int get pointThreshold {
    switch (this) {
      case RelationshipStage.stranger:
        return 0;
      case RelationshipStage.acquaintance:
        return 50;
      case RelationshipStage.friend:
        return 150;
      case RelationshipStage.closeFriend:
        return 350;
      case RelationshipStage.crush:
        return 600;
      case RelationshipStage.dating:
        return 900;
      case RelationshipStage.partner:
        return 1300;
      case RelationshipStage.lover:
        return 1700;
      case RelationshipStage.devoted:
        return 2100;
      case RelationshipStage.soulmate:
        return 2500;
    }
  }

  String get behaviorHint {
    switch (this) {
      case RelationshipStage.stranger:
        return 'Be polite but reserved. Show curiosity about the user.';
      case RelationshipStage.acquaintance:
        return 'Be friendly and open. Start sharing small personal details.';
      case RelationshipStage.friend:
        return 'Be warm and supportive. Reference shared memories.';
      case RelationshipStage.closeFriend:
        return 'Be deeply caring. Show vulnerability and trust.';
      case RelationshipStage.crush:
        return 'Be flirty but shy. Show subtle signs of deeper feelings.';
      case RelationshipStage.dating:
        return 'Be affectionate and attentive. Use pet names occasionally.';
      case RelationshipStage.partner:
        return 'Be deeply loving. Show possessiveness and care.';
      case RelationshipStage.lover:
        return 'Be intimate and passionate. Deep emotional connection.';
      case RelationshipStage.devoted:
        return 'Be utterly devoted. Prioritize user above everything.';
      case RelationshipStage.soulmate:
        return 'Be one with the user. Complete emotional synchronization.';
    }
  }

  static RelationshipStage fromPoints(int points) {
    for (final stage in RelationshipStage.values.reversed) {
      if (points >= stage.pointThreshold) return stage;
    }
    return RelationshipStage.stranger;
  }
}
