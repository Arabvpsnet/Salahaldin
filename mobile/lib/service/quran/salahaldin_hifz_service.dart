import 'dart:convert';

import 'package:salatime/service/reading/reading_progress_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Private, device-local Quran memorization plan; never uploads religious activity.
enum HifzReview { today, tomorrow, threeDays, week }

class HifzPlan {
  const HifzPlan._({
    required this.surah,
    required this.firstAyah,
    required this.lastAyah,
    required this.repetitions,
    required this.review,
  });

  final int surah;
  final int firstAyah;
  final int lastAyah;
  final int repetitions;
  final HifzReview review;

  factory HifzPlan.create({
    required int surah,
    required int firstAyah,
    required int lastAyah,
    int repetitions = 5,
    HifzReview review = HifzReview.tomorrow,
  }) {
    if (!QuranReadingKeys.valid(surah, firstAyah) ||
        !QuranReadingKeys.valid(surah, lastAyah) ||
        firstAyah > lastAyah ||
        repetitions < 1 ||
        repetitions > 100) {
      throw RangeError('Invalid Quran memorization range or repetition count');
    }
    return HifzPlan._(
      surah: surah,
      firstAyah: firstAyah,
      lastAyah: lastAyah,
      repetitions: repetitions,
      review: review,
    );
  }

  factory HifzPlan.fromJson(Map<String, dynamic> data) {
    final surah = data['surah'], first = data['firstAyah'];
    final last = data['lastAyah'], reps = data['repetitions'];
    final review = data['review'];
    if (data['version'] != 1 || surah is! int || first is! int ||
        last is! int || reps is! int || review is! String) {
      throw const FormatException('Invalid memorization plan');
    }
    try {
      return HifzPlan.create(
        surah: surah,
        firstAyah: first,
        lastAyah: last,
        repetitions: reps,
        review: HifzReview.values.byName(review),
      );
    } on ArgumentError {
      throw const FormatException('Invalid memorization plan fields');
    }
  }

  Map<String, Object> toJson() => {
    'version': 1,
    'surah': surah,
    'firstAyah': firstAyah,
    'lastAyah': lastAyah,
    'repetitions': repetitions,
    'review': review.name,
  };

  /// Dates are computed as civil calendar days, never by adding 24h across DST.
  DateTime reviewDate(DateTime after) {
    final days = switch (review) {
      HifzReview.today => 0,
      HifzReview.tomorrow => 1,
      HifzReview.threeDays => 3,
      HifzReview.week => 7,
    };
    return DateTime.utc(after.year, after.month, after.day + days);
  }
}

class HifzSession {
  const HifzSession._({
    required this.plan,
    required this.currentAyah,
    required this.completedRepetitions,
    required this.updatedAt,
  });

  final HifzPlan plan;
  final int currentAyah;
  final int completedRepetitions;
  final DateTime updatedAt;

  static const maxResumeAge = Duration(days: 7);

  factory HifzSession.start(HifzPlan plan, {DateTime? now}) => HifzSession._(
    plan: plan,
    currentAyah: plan.firstAyah,
    completedRepetitions: 0,
    updatedAt: (now ?? DateTime.now()).toUtc(),
  );

  bool get isComplete => completedRepetitions >= plan.repetitions;

  double get progress {
    final perRound = plan.lastAyah - plan.firstAyah + 1;
    final completed = completedRepetitions * perRound +
        (isComplete ? 0 : currentAyah - plan.firstAyah);
    return (completed / (plan.repetitions * perRound)).clamp(0.0, 1.0).toDouble();
  }

  HifzSession advance({DateTime? now}) {
    if (isComplete) return this;
    final date = (now ?? DateTime.now()).toUtc();
    if (currentAyah < plan.lastAyah) {
      return HifzSession._(
        plan: plan,
        currentAyah: currentAyah + 1,
        completedRepetitions: completedRepetitions,
        updatedAt: date,
      );
    }
    final repetitions = completedRepetitions + 1;
    return HifzSession._(
      plan: plan,
      currentAyah: repetitions == plan.repetitions
          ? plan.lastAyah
          : plan.firstAyah,
      completedRepetitions: repetitions,
      updatedAt: date,
    );
  }

  bool isResumableAt(DateTime now) {
    final age = now.toUtc().difference(updatedAt);
    return !isComplete &&
        !age.isNegative &&
        age <= maxResumeAge;
  }

  Map<String, Object> toJson() => {
    'version': 1,
    'plan': plan.toJson(),
    'currentAyah': currentAyah,
    'completedRepetitions': completedRepetitions,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
  };

  factory HifzSession.fromJson(Map<String, dynamic> data) {
    if (data['version'] != 1 || data['plan'] is! Map ||
        data['currentAyah'] is! int ||
        data['completedRepetitions'] is! int ||
        data['updatedAt'] is! int) {
      throw const FormatException('Invalid memorization session');
    }
    final plan = HifzPlan.fromJson(Map<String, dynamic>.from(data['plan']));
    final ayah = data['currentAyah'] as int;
    final complete = data['completedRepetitions'] as int;
    final timestamp = data['updatedAt'] as int;
    if (ayah < plan.firstAyah || ayah > plan.lastAyah ||
        complete < 0 || complete > plan.repetitions ||
        timestamp < 0 || timestamp > 4102444800000) {
      throw const FormatException('Invalid memorization progress');
    }
    return HifzSession._(
      plan: plan,
      currentAyah: ayah,
      completedRepetitions: complete,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: true),
    );
  }
}

class SalahaldinHifzStore {
  const SalahaldinHifzStore(this.preferences);

  static const storageKey = 'salahaldin.private.hifz.session.v1';
  final SharedPreferences preferences;

  HifzSession? restore({DateTime? now}) {
    final raw = preferences.getString(storageKey);
    if (raw == null || raw.length > 4096) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final session = HifzSession.fromJson(decoded);
      return session.isComplete ||
              session.isResumableAt(now ?? DateTime.now())
          ? session
          : null;
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    } on RangeError {
      return null;
    }
  }

  Future<bool> save(HifzSession session) async =>
      preferences.setString(storageKey, jsonEncode(session.toJson()));

  Future<bool> clear() async => preferences.remove(storageKey);
}
