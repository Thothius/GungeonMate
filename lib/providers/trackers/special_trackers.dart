part of '../run_provider.dart';

// Extracted from run_provider.dart (Phase 4b) — same library, zero
// import churn. Abstract members are requirements on RunProvider.

mixin _SpecialTrackers on ChangeNotifier {
  int _gunderfuryLevel = 1;

  int _tripleGunForm = 1;

  int _evolverForm = 1;

  int _evolverKills = 0;

  int _spiceUsageCount = 0;

  int _shellegunMode = 1;

  int _chamberGunFloor = 0;

  int _platinumBulletsSeconds = 0;

  int _ironCoinUses = 3;

  int _polarisKills = 0;

  int _polarisDamageHits = 0;

  int _guntherFriendship = 0;

  bool _gunSoulActivated = false;

  int _sprunTriggerIndex = -1;

  Timer? _windgunnerTimer;

  int _windgunnerCountdown = 0;

  int _robotArmor = 6;

  int _robotJunk = 0;

  bool _robotGoldJunk = false;

  bool _robotLies = false;

  bool _fireplaceExtinguished = false;

  bool _batteryBulletsSynergy = false;

  bool _fuseDisarmer = false;

  int _huntressRoomClears = 0;

  bool _huntressInjured = false;

  int _metronomeKills = 0;

  int _boxingGloveStars = 0;

  int _cigarettesUses = 0;

  int get gunderfuryLevel => _gunderfuryLevel;

  int get tripleGunForm => _tripleGunForm;

  int get evolverForm => _evolverForm;

  int get evolverKills => _evolverKills;

  int get sprunTriggerIndex => _sprunTriggerIndex;

  int get windgunnerCountdown => _windgunnerCountdown;

  int get spiceUsageCount => _spiceUsageCount;

  int get shellegunMode => _shellegunMode;

  int get chamberGunFloor => _chamberGunFloor;

  int get platinumBulletsSeconds => _platinumBulletsSeconds;

  int get ironCoinUses => _ironCoinUses;

  int get polarisKills => _polarisKills;

  int get polarisDamageHits => _polarisDamageHits;

  int get guntherFriendship => _guntherFriendship;

  bool get gunSoulActivated => _gunSoulActivated;

  int get robotArmor => _robotArmor;

  int get robotJunk => _robotJunk;

  bool get robotGoldJunk => _robotGoldJunk;

  bool get robotLies => _robotLies;

  bool get fireplaceExtinguished => _fireplaceExtinguished;

  bool get batteryBulletsSynergy => _batteryBulletsSynergy;

  bool get fuseDisarmer => _fuseDisarmer;

  int get huntressRoomClears => _huntressRoomClears;

  bool get huntressInjured => _huntressInjured;

  int get metronomeKills => _metronomeKills;

  int get boxingGloveStars => _boxingGloveStars;

  int get cigarettesUses => _cigarettesUses;

  Future<void> _loadSpecialUpgrades() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _gunderfuryLevel = prefs.getInt('special.gunderfury.level') ?? 1;
      _tripleGunForm = prefs.getInt('special.triple_gun.form') ?? 1;
      _evolverForm = prefs.getInt('special.evolver.form') ?? 1;
      _evolverKills = prefs.getInt('special.evolver.kills') ?? 0;
      _sprunTriggerIndex = prefs.getInt('special.sprun.trigger') ?? -1;
      _spiceUsageCount = prefs.getInt('special.spice.count') ?? 0;
      _shellegunMode = prefs.getInt('special.shellegun.mode') ?? 1;
      _chamberGunFloor = prefs.getInt('special.chambergun.floor') ?? 0;
      _platinumBulletsSeconds = prefs.getInt('special.platinum.seconds') ?? 0;
      _ironCoinUses = prefs.getInt('special.ironcoin.uses') ?? 3;
      _polarisKills = prefs.getInt('special.polaris.kills') ?? 0;
      _polarisDamageHits = prefs.getInt('special.polaris.hits') ?? 0;
      _guntherFriendship = prefs.getInt('special.gunther.friendship') ?? 0;
      _gunSoulActivated = prefs.getBool('special.gunsoul.activated') ?? false;
      _metronomeKills = prefs.getInt('special.metronome.kills') ?? 0;
      _boxingGloveStars = prefs.getInt('special.boxingglove.stars') ?? 0;
      _cigarettesUses = prefs.getInt('special.cigarettes.uses') ?? 0;

      // Robot specific values
      _robotArmor = prefs.getInt('special.robot.armor') ?? 6;
      _robotJunk = prefs.getInt('special.robot.junk') ?? 0;
      _robotGoldJunk = prefs.getBool('special.robot.goldjunk') ?? false;
      _robotLies = prefs.getBool('special.robot.lies') ?? false;
      _fireplaceExtinguished =
          prefs.getBool('special.robot.fireplace') ?? false;
      _batteryBulletsSynergy = prefs.getBool('special.robot.battery') ?? false;
      _fuseDisarmer = prefs.getBool('special.robot.fusedisarmer') ?? false;

      // Huntress specific values
      _huntressRoomClears = prefs.getInt('special.huntress.roomclears') ?? 0;
      _huntressInjured = prefs.getBool('special.huntress.injured') ?? false;
    } catch (e) {
      debugPrint('[RunProvider] persistence error: $e');
    }
  }

  Future<void> setHuntressRoomClears(int clears) async {
    _huntressRoomClears = clears.clamp(0, 999);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('special.huntress.roomclears', _huntressRoomClears);
    } catch (e) {
      debugPrint('[RunProvider] persistence error: $e');
    }
    notifyListeners();
  }

  Future<void> setHuntressInjured(bool injured) async {
    _huntressInjured = injured;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('special.huntress.injured', _huntressInjured);
    } catch (e) {
      debugPrint('[RunProvider] persistence error: $e');
    }
    notifyListeners();
  }

  Future<void> setRobotArmor(int armor) async {
    _robotArmor = armor.clamp(0, 99);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('special.robot.armor', _robotArmor);
    } catch (e) {
      debugPrint('[RunProvider] persistence error: $e');
    }
    notifyListeners();
  }

  Future<void> setRobotJunk(int junk) async {
    _robotJunk = junk.clamp(0, 99);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('special.robot.junk', _robotJunk);
    } catch (e) {
      debugPrint('[RunProvider] persistence error: $e');
    }
    notifyListeners();
  }

  Future<void> setRobotGoldJunk(bool gold) async {
    _robotGoldJunk = gold;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('special.robot.goldjunk', _robotGoldJunk);
    } catch (e) {
      debugPrint('[RunProvider] persistence error: $e');
    }
    notifyListeners();
  }

  Future<void> setRobotLies(bool lies) async {
    _robotLies = lies;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('special.robot.lies', _robotLies);
    } catch (e) {
      debugPrint('[RunProvider] persistence error: $e');
    }
    notifyListeners();
  }

  Future<void> setFireplaceExtinguished(bool val) async {
    _fireplaceExtinguished = val;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('special.robot.fireplace', _fireplaceExtinguished);
    } catch (e) {
      debugPrint('[RunProvider] persistence error: $e');
    }
    notifyListeners();
  }

  Future<void> setBatteryBulletsSynergy(bool val) async {
    _batteryBulletsSynergy = val;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('special.robot.battery', _batteryBulletsSynergy);
    } catch (e) {
      debugPrint('[RunProvider] persistence error: $e');
    }
    notifyListeners();
  }

  Future<void> setFuseDisarmer(bool val) async {
    _fuseDisarmer = val;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('special.robot.fusedisarmer', _fuseDisarmer);
    } catch (e) {
      debugPrint('[RunProvider] persistence error: $e');
    }
    notifyListeners();
  }

  Future<void> setGunderfuryLevel(int lvl) async {
    _gunderfuryLevel = lvl.clamp(1, 60);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('special.gunderfury.level', _gunderfuryLevel);
    } catch (e) {
      debugPrint('[RunProvider] persistence error: $e');
    }
    notifyListeners();
  }

  Future<void> setTripleGunForm(int form) async {
    _tripleGunForm = form.clamp(1, 3);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('special.triple_gun.form', _tripleGunForm);
    } catch (e) {
      debugPrint('[RunProvider] persistence error: $e');
    }
    notifyListeners();
  }

  /// Records unique-enemy-type kills for the Evolver. Every 5 unique
  /// kills force-evolves the gun one stage (max stage 6 at 25 kills),
  /// so the form is derived and kept in sync here.
  Future<void> setEvolverKills(int kills) async {
    _evolverKills = kills.clamp(0, 25);
    _evolverForm = (1 + _evolverKills ~/ 5).clamp(1, 6);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('special.evolver.kills', _evolverKills);
      await prefs.setInt('special.evolver.form', _evolverForm);
    } catch (e) {
      debugPrint('[RunProvider] persistence error: $e');
    }
    notifyListeners();
  }

  /// Reveals (or re-rolls) the Sprun mystery trigger for this run.
  /// Pass -1 to reset to unrevealed.
  Future<void> setSprunTriggerIndex(int index) async {
    _sprunTriggerIndex = index.clamp(-1, 4);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('special.sprun.trigger', _sprunTriggerIndex);
    } catch (e) {
      debugPrint('[RunProvider] persistence error: $e');
    }
    notifyListeners();
  }

  void startWindgunnerCountdown() {
    _windgunnerTimer?.cancel();
    _windgunnerCountdown = 20;
    notifyListeners();
    _windgunnerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_windgunnerCountdown > 0) {
        _windgunnerCountdown--;
        notifyListeners();
      } else {
        timer.cancel();
      }
    });
  }

  void cancelWindgunnerCountdown() {
    _windgunnerTimer?.cancel();
    _windgunnerCountdown = 0;
    notifyListeners();
  }

  Future<void> setShellegunMode(int mode) async {
    _shellegunMode = mode.clamp(1, 3);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('special.shellegun.mode', _shellegunMode);
    } catch (e) {
      debugPrint('[RunProvider] persistence error: $e');
    }
    notifyListeners();
  }

  Future<void> setChamberGunFloor(int floor) async {
    _chamberGunFloor = floor.clamp(0, 9);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('special.chambergun.floor', _chamberGunFloor);
    } catch (e) {
      debugPrint('[RunProvider] persistence error: $e');
    }
    notifyListeners();
  }

  Future<void> setPlatinumBulletsSeconds(int seconds) async {
    _platinumBulletsSeconds = seconds.clamp(0, 999);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('special.platinum.seconds', _platinumBulletsSeconds);
    } catch (e) {
      debugPrint('[RunProvider] persistence error: $e');
    }
    notifyListeners();
  }

  Future<void> setIronCoinUses(int uses) async {
    _ironCoinUses = uses.clamp(0, 3);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('special.ironcoin.uses', _ironCoinUses);
    } catch (e) {
      debugPrint('[RunProvider] persistence error: $e');
    }
    notifyListeners();
  }

  Future<void> setPolarisKills(int kills) async {
    _polarisKills = kills.clamp(0, 999);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('special.polaris.kills', _polarisKills);
    } catch (e) {
      debugPrint('[RunProvider] persistence error: $e');
    }
    notifyListeners();
  }

  Future<void> setPolarisDamageHits(int hits) async {
    _polarisDamageHits = hits.clamp(0, 999);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('special.polaris.hits', _polarisDamageHits);
    } catch (e) {
      debugPrint('[RunProvider] persistence error: $e');
    }
    notifyListeners();
  }

  Future<void> setGuntherFriendship(int friendship) async {
    _guntherFriendship = friendship.clamp(0, 99);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('special.gunther.friendship', _guntherFriendship);
    } catch (e) {
      debugPrint('[RunProvider] persistence error: $e');
    }
    notifyListeners();
  }

  Future<void> setGunSoulActivated(bool activated) async {
    _gunSoulActivated = activated;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('special.gunsoul.activated', _gunSoulActivated);
    } catch (e) {
      debugPrint('[RunProvider] persistence error: $e');
    }
    notifyListeners();
  }

  Future<void> setEvolverForm(int form) async {
    _evolverForm = form.clamp(1, 6);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('special.evolver.form', _evolverForm);
    } catch (e) {
      debugPrint('[RunProvider] persistence error: $e');
    }
    notifyListeners();
  }

  Future<void> setSpiceUsageCount(int count) async {
    _spiceUsageCount = count.clamp(0, 100);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('special.spice.count', _spiceUsageCount);
    } catch (e) {
      debugPrint('[RunProvider] persistence error: $e');
    }
    notifyListeners();
  }

  void setMetronomeKills(int kills) {
    _metronomeKills = kills.clamp(0, 75);
    _persistSpecial('special.metronome.kills', kills);
    notifyListeners();
  }

  void setBoxingGloveStars(int stars) {
    _boxingGloveStars = stars.clamp(0, 3);
    _persistSpecial('special.boxingglove.stars', stars);
    notifyListeners();
  }

  void setCigarettesUses(int uses) {
    _cigarettesUses = uses.clamp(0, 999);
    _persistSpecial('special.cigarettes.uses', uses);
    notifyListeners();
  }

  /// Shared fire-and-forget prefs write for special-state fields —
  /// matches the per-setter pattern used by the older special fields.
  void _persistSpecial(String key, Object value) {
    SharedPreferences.getInstance()
        .then((prefs) {
          switch (value) {
            case int v:
              prefs.setInt(key, v);
            case bool v:
              prefs.setBool(key, v);
            case String v:
              prefs.setString(key, v);
            default:
          }
        })
        .catchError((Object _) {});
  }
}
