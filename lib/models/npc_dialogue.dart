import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Represents a branching dialogue node for an NPC in GungeonMate.
class DialogueNode {
  final String id;
  final String type; // "intro", "random_tip", "chamber_specific", "storyline"
  final String prompt;
  final List<PlayerResponse> responses;

  DialogueNode({
    required this.id,
    required this.type,
    required this.prompt,
    required this.responses,
  });

  String get npcId => id.split('_')[0];

  factory DialogueNode.fromJson(Map<String, dynamic> json) {
    return DialogueNode(
      id: json['id'] as String,
      type: json['type'] as String,
      prompt: json['prompt'] as String,
      responses: (json['responses'] as List<dynamic>?)
              ?.map((r) => PlayerResponse.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Represents a Gungeoneer branching choice response and the NPC's specific reaction.
class PlayerResponse {
  final String tone; // "PEP" (Peppy), "TOUGH" (Tough), "DEMENTED" (Unhinged)
  final String text;
  final String reply;

  // Custom secret GungeonMate App rewards!
  final String? rewardItemName;
  final String? rewardItemDesc;
  final String? rewardItemIcon;

  PlayerResponse({
    required this.tone,
    required this.text,
    required this.reply,
    this.rewardItemName,
    this.rewardItemDesc,
    this.rewardItemIcon,
  });

  factory PlayerResponse.fromJson(Map<String, dynamic> json) {
    return PlayerResponse(
      tone: json['tone'] as String,
      text: json['text'] as String,
      reply: json['reply'] as String,
      rewardItemName: json['rewardItemName'] as String?,
      rewardItemDesc: json['rewardItemDesc'] as String?,
      rewardItemIcon: json['rewardItemIcon'] as String?,
    );
  }
}

/// The state machine orchestrator that manages dialogue loading, met tracking, and dynamic injection.
class NpcNarrativeService {
  NpcNarrativeService._();

  static List<DialogueNode> _allNodes = [];
  static bool _loaded = false;

  /// Loads the compiled dialogue data from the merged JSON asset
  static Future<void> loadDialogues() async {
    if (_loaded) return;
    try {
      final jsonString = await rootBundle.loadString('assets/data/npc_dialogues.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      _allNodes = jsonList.map((j) => DialogueNode.fromJson(j as Map<String, dynamic>)).toList();
      _loaded = true;
    } catch (e) {
      // Fallback in case of asset read issue
      _allNodes = [];
    }
  }

  /// Check if the user has met this NPC before.
  static Future<bool> hasMetNpc(String npcId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('hasMet_$npcId') ?? false;
  }

  /// Mark that the user has met this NPC, enabling tips.
  static Future<void> markNpcAsMet(String npcId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasMet_$npcId', true);
  }

  /// Get the next dialogue node based on First Encounter, Chamber Specificity, or Random pools.
  static Future<DialogueNode?> getDialogue({
    required String npcId,
    required int chamberIndex, // 1 to 5
  }) async {
    await loadDialogues();

    final idClean = npcId.toLowerCase().trim();

    // 0. Check if Bello is talking and detects a curio delivery!
    if (idClean == 'bello') {
      final prefs = await SharedPreferences.getInstance();

      // Check Flynt's sprocket
      final hasSprocket = prefs.getBool('npc.quest.completed.flynt') ?? false;
      final deliveredSprocket = prefs.getBool('npc.quest.completed.flynt_delivered') ?? false;
      if (hasSprocket && !deliveredSprocket) {
        return _getBelloDeliveryNode('flynt');
      }

      // Check Vampire's nugget
      final hasNugget = prefs.getBool('npc.quest.completed.vampire') ?? false;
      final deliveredNugget = prefs.getBool('npc.quest.completed.vampire_delivered') ?? false;
      if (hasNugget && !deliveredNugget) {
        return _getBelloDeliveryNode('vampire');
      }

      // Check Goopton's mushroom
      final hasMushroom = prefs.getBool('npc.quest.completed.goopton') ?? false;
      final deliveredMushroom = prefs.getBool('npc.quest.completed.goopton_delivered') ?? false;
      if (hasMushroom && !deliveredMushroom) {
        return _getBelloDeliveryNode('goopton');
      }
    }

    // 1. Check if the NPC is an Annex NPC and has an active delivery quest!
    final annexNpcs = ['flynt', 'vampire', 'sell creep', 'sell_creep', 'goopton', 'professor goopton', 'cursula'];
    if (annexNpcs.contains(idClean)) {
      final prefs = await SharedPreferences.getInstance();
      final questKey = 'npc.quest.completed.$idClean';
      final completed = prefs.getBool(questKey) ?? false;

      if (!completed) {
        // Force trigger the delivery quest node!
        return _getQuestNode(idClean);
      }
    }

    // 2. Check First Encounter (Intro dialogue)
    final met = await hasMetNpc(npcId);
    if (!met) {
      final introNode = _allNodes.firstWhere(
        (n) => n.npcId == npcId && n.type == 'intro',
        orElse: () => _allNodes.firstWhere((n) => n.npcId == npcId, orElse: () => _fallbackNode(idClean)),
      );
      return introNode;
    }

    // 3. Collect ALL valid dialog nodes (chamber-specific AND random tips) to ensure high randomness and variety!
    final List<DialogueNode> candidates = [];
    
    // Grab chamber-specific nodes
    final chamberNodes = _allNodes.where((n) => n.npcId == npcId && n.type == 'chamber_specific' && n.id.contains('chamber_$chamberIndex')).toList();
    candidates.addAll(chamberNodes);
    
    // Grab indexed matches
    final indexNodes = _allNodes.where((n) => n.npcId == npcId && n.id.contains('_0$chamberIndex')).toList();
    candidates.addAll(indexNodes);
    
    // Grab general tips
    final tips = _allNodes.where((n) => n.npcId == npcId && n.type == 'random_tip').toList();
    candidates.addAll(tips);
    
    if (candidates.isNotEmpty) {
      final rand = math.Random();
      return candidates[rand.nextInt(candidates.length)];
    }

    // 4. Ultimate generic fallback
    final npcAll = _allNodes.where((n) => n.npcId == npcId).toList();
    if (npcAll.isNotEmpty) {
      final rand = math.Random();
      return npcAll[rand.nextInt(npcAll.length)];
    }

    return _fallbackNode(idClean);
  }

  static DialogueNode _getQuestNode(String npcId) {
    String prompt = "Keep moving forward, Gungeoneer. The depths wait for no one.";
    List<PlayerResponse> responses = [];

    if (npcId == 'flynt') {
      prompt = "Bello sent over a heavy iron lock-box, but his grease is too thin! I need some thick, gold-infused tallow. Did you bring the jar?";
      responses = [
        PlayerResponse(
          tone: 'PEP',
          text: "Yes, I brought it! It's super slippery!",
          reply: "Aha! Look at that gold sheen! The tumblers are finally clicking without a squeak! Take this... a golden sprocket from my secret locker. Hand handle with care!",
          rewardItemName: "Chrono-Trigger Sprocket",
          rewardItemDesc: "A masterfully crafted golden cog salvaged from the great clockwork engine of the Dragun's pedestal. It ticks at 60 temporal warp units per second, whispering fragments of past runs. Bello would lose his mind to get this!",
          rewardItemIcon: "settings_suggest_rounded",
        ),
        PlayerResponse(
          tone: 'TOUGH',
          text: "Take the grease. Give me my lock-breaking tools.",
          reply: "Fine. Straight to business. My keys are sharp, but this grease is sharper. Here, take this heavy golden gear.",
          rewardItemName: "Chrono-Trigger Sprocket",
          rewardItemDesc: "A masterfully crafted golden cog salvaged from the great clockwork engine of the Dragun's pedestal. It ticks at 60 temporal warp units per second, whispering fragments of past runs. Bello would lose his mind to get this!",
          rewardItemIcon: "settings_suggest_rounded",
        ),
        PlayerResponse(
          tone: 'DEMENTED',
          text: "I boiled my keys in Bello's soup and now they won't stop crying!",
          reply: "You've been sniffing too much copper dust. But this grease is divine. Take this star-cog, keep it away from your crying keyholes.",
          rewardItemName: "Chrono-Trigger Sprocket",
          rewardItemDesc: "A masterfully crafted golden cog salvaged from the great clockwork engine of the Dragun's pedestal. It ticks at 60 temporal warp units per second, whispering fragments of past runs. Bello would lose his mind to get this!",
          rewardItemIcon: "settings_suggest_rounded",
        ),
      ];
    } else if (npcId == 'vampire') {
      prompt = "Ah... Bello's delivery of Ammoconda soup is still warm. But it lacks a certain... metallic bite. Did you bring the iron flakes to sprinkle in?";
      responses = [
        PlayerResponse(
          tone: 'PEP',
          text: "I found some shiny shell-shavings! Sprinkle them on!",
          reply: "Mmm... *slurp*... Ah, the copper iron rushing through my veins! Quite exquisite, sweet heart. Take this solid chunk of pure heavy aurum!",
          rewardItemName: "Aurum Ammo-Nugget",
          rewardItemDesc: "A dense clump of crystallized gold-sulfur, formed when gold casing coins are smelted by high-velocity friction in the Hollow. It is so heavy it warp-curves local gravitational fields. A rare anomaly!",
          rewardItemIcon: "widgets_rounded",
        ),
        PlayerResponse(
          tone: 'TOUGH',
          text: "Here's the scrap metal. Eat it or drink it, I don't care.",
          reply: "Gruff and heavy... I like a stout supplier. It adds flavor to the vintage. Take this heavy gold-clump as payment.",
          rewardItemName: "Aurum Ammo-Nugget",
          rewardItemDesc: "A dense clump of crystallized gold-sulfur, formed when gold casing coins are smelted by high-velocity friction in the Hollow. It is so heavy it warp-curves local gravitational fields. A rare anomaly!",
          rewardItemIcon: "widgets_rounded",
        ),
        PlayerResponse(
          tone: 'DEMENTED',
          text: "The iron maidens are bleeding orange juice in my dreams!",
          reply: "You have a wonderfully chaotic neural pulse. Quite intoxicating... Here, take this heavy gold anomaly before your dreams freeze over.",
          rewardItemName: "Aurum Ammo-Nugget",
          rewardItemDesc: "A dense clump of crystallized gold-sulfur, formed when gold casing coins are smelted by high-velocity friction in the Hollow. It is so heavy it warp-curves local gravitational fields. A rare anomaly!",
          rewardItemIcon: "widgets_rounded",
        ),
      ];
    } else if (npcId == 'sell creep' || npcId == 'sell_creep') {
      prompt = "Sss... Bello promised to slide a crate of rusted iron nails down my sewer grate. Did you carry them down? Sss... I need the crunch...";
      responses = [
        PlayerResponse(
          tone: 'PEP',
          text: "I dragged the whole box of rusty nails down! Crunch away!",
          reply: "*crunch crunch*... Ahhh... the delicious, scratchy sulfur taste, sss... Here, take this ancient token I pulled from the sludge...",
          rewardItemName: "The Rusty Grate Token",
          rewardItemDesc: "A heavy sewer coin inscribed with ancient bullet runes. \"It smells faintly of wet gunpowder and iron.\"",
          rewardItemIcon: "token_rounded",
        ),
        PlayerResponse(
          tone: 'TOUGH',
          text: "I kicked the heavy crate down the shaft. Don't choke on them.",
          reply: "Sss... rude but efficient. My teeth can handle any caliber. Take this rusty seal, it carries weight down here.",
          rewardItemName: "The Rusty Grate Token",
          rewardItemDesc: "A heavy sewer coin inscribed with ancient bullet runes. \"It smells faintly of wet gunpowder and iron.\"",
          rewardItemIcon: "token_rounded",
        ),
        PlayerResponse(
          tone: 'DEMENTED',
          text: "The nails are tiny copper soldiers marching into my belly!",
          reply: "Sss... even I wouldn't eat them whole like that, crazy child. Take this token, go find some water, sss...",
          rewardItemName: "The Rusty Grate Token",
          rewardItemDesc: "A heavy sewer coin inscribed with ancient bullet runes. \"It smells faintly of wet gunpowder and iron.\"",
          rewardItemIcon: "token_rounded",
        ),
      ];
    } else if (npcId == 'goopton' || npcId == 'professor goopton' || npcId == 'professor_goopton') {
      prompt = "Blub! *splish splash* My toxic slide experiments are stalled! Bello was supposed to ship a jar of cryogenic liquid sulfur. Did you bring the blue jar?!";
      responses = [
        PlayerResponse(
          tone: 'PEP',
          text: "Yes! It's glowing blue and super freezing! Be careful!",
          reply: "Gloop! *fizz fizz* Magnificent reactant! The viscosity is reaching 100% trajectory potential! Take this glowing fungal specimen, sparky!",
          rewardItemName: "Myconid Blank-Cap",
          rewardItemDesc: "This rare spore-cap grows in damp, abandoned gunpowder barrels in the Mines. It absorbs raw kinetic shockwaves, releasing silent micro-blanks when tapped. Handle carefully!",
          rewardItemIcon: "nature_rounded",
        ),
        PlayerResponse(
          tone: 'TOUGH',
          text: "Here's the freezing gas. Don't spill it on my boots.",
          reply: "Gloop. Understood. Chemical safety is for casualties. Take this glowing blank-absorbing mushroom.",
          rewardItemName: "Myconid Blank-Cap",
          rewardItemDesc: "This rare spore-cap grows in damp, abandoned gunpowder barrels in the Mines. It absorbs raw kinetic shockwaves, releasing silent micro-blanks when tapped. Handle carefully!",
          rewardItemIcon: "nature_rounded",
        ),
        PlayerResponse(
          tone: 'DEMENTED',
          text: "I drank the blue gas and now my tongue is a slide for ice angels!",
          reply: "Blob blub! That's highly toxic! Here, hold this blank mushroom, its neutral frequencies should settle your neural waves!",
          rewardItemName: "Myconid Blank-Cap",
          rewardItemDesc: "This rare spore-cap grows in damp, abandoned gunpowder barrels in the Mines. It absorbs raw kinetic shockwaves, releasing silent micro-blanks when tapped. Handle carefully!",
          rewardItemIcon: "nature_rounded",
        ),
      ];
    } else if (npcId == 'cursula') {
      prompt = "Is that a handsome Gungeoneer slide-rolling into my shadow-embrace? *giggles* Bello promised me a jar of Jammed squid ink... Did you bring it to help paint my nails?";
      responses = [
        PlayerResponse(
          tone: 'PEP',
          text: "I brought the thickest, purple ink just for you, Cursula!",
          reply: "Ah, so dark and thick... just like my affection for you. *giggles and winks with three eyes* Take this heart-shaped bullet, keep it close to your chest.",
          rewardItemName: "Cursula's Heart Bullet",
          rewardItemDesc: "A pulsing purple-tinted hollow-point bullet that beats like a heart. \"Curse +1. Coolness +3. It whispers sweet, chaotic things into your ear.\"",
          rewardItemIcon: "favorite_rounded",
        ),
        PlayerResponse(
          tone: 'TOUGH',
          text: "Here's the black ink. I don't do makeup, Cursula.",
          reply: "Ooh, a serious warrior... I love when you get impatient. It makes your pulse race. Take this warm bullet, let it shield your cold armor.",
          rewardItemName: "Cursula's Heart Bullet",
          rewardItemDesc: "A pulsing purple-tinted hollow-point bullet that beats like a heart. \"Curse +1. Coolness +3. It whispers sweet, chaotic things into your ear.\"",
          rewardItemIcon: "favorite_rounded",
        ),
        PlayerResponse(
          tone: 'DEMENTED',
          text: "I painted my eyes purple so I can see your shadow-angels!",
          reply: "You have the most delightful, delirious mind! Let us bind our shadow matrices forever. Take this bullet, let it dance inside your weapon chamber.",
          rewardItemName: "Cursula's Heart Bullet",
          rewardItemDesc: "A pulsing purple-tinted hollow-point bullet that beats like a heart. \"Curse +1. Coolness +3. It whispers sweet, chaotic things into your ear.\"",
          rewardItemIcon: "favorite_rounded",
        ),
      ];
    }

    return DialogueNode(
      id: '${npcId}_quest',
      type: 'storyline',
      prompt: prompt,
      responses: responses,
    );
  }

  static DialogueNode _getBelloDeliveryNode(String sourceNpcId) {
    String prompt = "";
    List<PlayerResponse> responses = [];

    if (sourceNpcId == 'flynt') {
      prompt = "Holy lead-slugs! *whispers* Keep your voice down, kid! Is that... is that the Chrono-Trigger Sprocket in your pocket?! The golden gear from the Dragun's pedestal?! Hand it over and I'll drop my prices permanently!";
      responses = [
        PlayerResponse(
          tone: 'PEP',
          text: "Here it is! It ticks so nicely!",
          reply: "Oh, look at those perfect teeth mesh! A mechanical masterpiece! *giggles unhinged* Straight to my secret cabinet! Enjoy your 10% discount, kid!",
          rewardItemName: "Curio Delivered: Chrono-Trigger Sprocket",
          rewardItemDesc: "Delivered to Bello's secret cabinet. You unlocked a permanent 10% shop discount on all Bello items!",
          rewardItemIcon: "settings_suggest_rounded",
        ),
        PlayerResponse(
          tone: 'TOUGH',
          text: "Fine. Give me my discount.",
          reply: "Quiet and efficient... I respect that. Look at that golden sheen under my lantern! This completes my machinery shelf! You got a deal.",
          rewardItemName: "Curio Delivered: Chrono-Trigger Sprocket",
          rewardItemDesc: "Delivered to Bello's secret cabinet. You unlocked a permanent 10% shop discount on all Bello items!",
          rewardItemIcon: "settings_suggest_rounded",
        ),
        PlayerResponse(
          tone: 'DEMENTED',
          text: "The golden gear told me Bello has a heart of clockwork!",
          reply: "Haha! Maybe I do, kid, maybe I do! It ticks when I see such rare beauty! Take your discount, let me drool over this gear in peace!",
          rewardItemName: "Curio Delivered: Chrono-Trigger Sprocket",
          rewardItemDesc: "Delivered to Bello's secret cabinet. You unlocked a permanent 10% shop discount on all Bello items!",
          rewardItemIcon: "settings_suggest_rounded",
        ),
      ];
    } else if (sourceNpcId == 'vampire') {
      prompt = "By the Great Gun! *eyes bulge* That glow... it's the Aurum Ammo-Nugget! Heavy, hot-sulfur gold crystallized in the Hollow depths! Oh, my collection has been crying for this! Please, let me buy it off you!";
      responses = [
        PlayerResponse(
          tone: 'PEP',
          text: "Sure! Happy to help complete your collection!",
          reply: "Magnificent! It's so heavy it literally warp-curves my display shelf! Splendid! I'm marking down all my prices by another 10% for you!",
          rewardItemName: "Curio Delivered: Aurum Ammo-Nugget",
          rewardItemDesc: "Delivered to Bello's secret cabinet. You unlocked a permanent 10% shop discount on all Bello items!",
          rewardItemIcon: "widgets_rounded",
        ),
        PlayerResponse(
          tone: 'TOUGH',
          text: "Take it. I want my shop discount.",
          reply: "Cold hard commerce! Here is your permanent discount sticker. Now let me lock this golden sulfur beauty in my heavy lead safe!",
          rewardItemName: "Curio Delivered: Aurum Ammo-Nugget",
          rewardItemDesc: "Delivered to Bello's secret cabinet. You unlocked a permanent 10% shop discount on all Bello items!",
          rewardItemIcon: "widgets_rounded",
        ),
        PlayerResponse(
          tone: 'DEMENTED',
          text: "The gold clump is a frozen star that wants to sleep in your cash register!",
          reply: "Yes! *cackles* It will keep my coins warm! A shining anomaly of pure wealth! Thank you, unhinged customer, thank you!",
          rewardItemName: "Curio Delivered: Aurum Ammo-Nugget",
          rewardItemDesc: "Delivered to Bello's secret cabinet. You unlocked a permanent 10% shop discount on all Bello items!",
          rewardItemIcon: "widgets_rounded",
        ),
      ];
    } else if (sourceNpcId == 'goopton') {
      prompt = "Sweet merciful trigger-guards! *gasps* The Myconid Blank-Cap! The extremely rare kinetic mushroom from the damp gunpowder Mines! *whispers* I have wanted to add this fungal beauty to my curios forever! Trade it to me!";
      responses = [
        PlayerResponse(
          tone: 'PEP',
          text: "I brought it carefully by the stem! Here!",
          reply: "Incredible! Look at those red blank-spots! It's absorbing my loud chatter in real-time! Exquisite! Take a permanent 10% discount on all shop prices!",
          rewardItemName: "Curio Delivered: Myconid Blank-Cap",
          rewardItemDesc: "Delivered to Bello's secret cabinet. You unlocked a permanent 10% shop discount on all Bello items!",
          rewardItemIcon: "nature_rounded",
        ),
        PlayerResponse(
          tone: 'TOUGH',
          text: "Don't touch the cap. Just apply my discount.",
          reply: "A seasoned scavenger! I will handle it with silk-padded tweezers. Yes, yes... your discount is locked in! Outstanding!",
          rewardItemName: "Curio Delivered: Myconid Blank-Cap",
          rewardItemDesc: "Delivered to Bello's secret cabinet. You unlocked a permanent 10% shop discount on all Bello items!",
          rewardItemIcon: "nature_rounded",
        ),
        PlayerResponse(
          tone: 'DEMENTED',
          text: "The red mushroom wants to eat your face and turn you into a shopkeeper mushroom!",
          reply: "Haha! I am already a Gungeon entity, kid! This blank-absorbing spore is too pure to infect me. Take your 10% discount, go conquer the Hollow!",
          rewardItemName: "Curio Delivered: Myconid Blank-Cap",
          rewardItemDesc: "Delivered to Bello's secret cabinet. You unlocked a permanent 10% shop discount on all Bello items!",
          rewardItemIcon: "nature_rounded",
        ),
      ];
    }

    return DialogueNode(
      id: 'bello_delivery_$sourceNpcId',
      type: 'storyline',
      prompt: prompt,
      responses: responses,
    );
  }

  static DialogueNode _fallbackNode(String npcId) {
    String prompt = "Keep moving forward, Gungeoneer. The depths wait for no one.";
    List<PlayerResponse> responses = [
      PlayerResponse(tone: 'PEP', text: "Let's do this! High energy!", reply: "That energy will get you far. Stay focused."),
      PlayerResponse(tone: 'TOUGH', text: "Just stay out of my way.", reply: "Fine by me. My inventory is ready when you are."),
      PlayerResponse(tone: 'DEMENTED', text: "The shell casing god sings in my ear!", reply: "I've heard unhinged things, but you take the cake."),
    ];

    final idClean = npcId.toLowerCase().trim();

    if (idClean == 'muncher') {
      prompt = "Crunch, munch... Put in two firearms, and I will cough out a new, random death-dealer. What are you feeding me?";
      responses = [
        PlayerResponse(tone: 'PEP', text: "I have two shiny pistols! Take them!", reply: "Excellent... crunch crunch... Here, take this shiny automatic! Enjoy the recoil!"),
        PlayerResponse(tone: 'TOUGH', text: "I'm throwing in trash to get a real gun.", reply: "Munch munch... trash in, treasure out. Do not insult my digestive tract."),
        PlayerResponse(tone: 'DEMENTED', text: "Do my guns scream when you chew them?", reply: "They release their temporal kinetic potential directly into my stomach. It tastes like copper."),
      ];
    } else if (idClean == 'sell creep' || idClean == 'sell_creep') {
      final rand = math.Random().nextInt(3);
      if (rand == 0) {
        prompt = "Ssss... feed me guns, feed me items, and I will spit out casings. Keep the waste coming, sss...";
      } else if (rand == 1) {
        prompt = "Sss... do you eat the bullets because they whisper secrets? They taste of sulfur and failed ambitions.";
      } else {
        prompt = "Ssss... clean your pockets, line my grate. Casings for iron.";
      }
      responses = [
        PlayerResponse(tone: 'PEP', text: "Yay, spring cleaning! Let's trade!", reply: "Yes, sss... keep the waste flowing down the sewers, sss..."),
        PlayerResponse(tone: 'TOUGH', text: "Here, buy this junk. Give me my coins.", reply: "Fair deal, sss. Business is business, even in the sewers."),
        PlayerResponse(tone: 'DEMENTED', text: "The shell casing god demands a blood sacrifice of copper nails!", reply: "Sss... that's too heavy even for my digestive system. Stick to casings, sss..."),
      ];
    } else if (idClean == 'vampire') {
      final rand = math.Random().nextInt(3);
      if (rand == 0) {
        prompt = "Ah, a mortal pulse... Give me your precious red blood cells, and I will reward you with cold, hard shell casings. Do we have a deal, sweet heart?";
      } else if (rand == 1) {
        prompt = "Ah... did you know the red blood cells of Gungeoneers are rich in sulfur and copper? It adds flavor.";
      } else {
        prompt = "Mmm, so warm... a stout pulse. Are you here to bleed for casings, sweet heart?";
      }
      responses = [
        PlayerResponse(tone: 'PEP', text: "I can spare a little blood for science!", reply: "Ah, so warm... slurp... Here are your shiny casings. Come back when you're feeling plump!"),
        PlayerResponse(tone: 'TOUGH', text: "Take it. I don't need red hearts to beat the boss.", reply: "A cold warrior... I respect the grit. Keep bleeding, I'll keep paying."),
        PlayerResponse(tone: 'DEMENTED', text: "The crimson river runs backwards into the moon!", reply: "You have very... exotic neural currents. Let's see if they taste of lead."),
      ];
    } else if (idClean == 'old red' || idClean == 'old_red') {
      final rand = math.Random().nextInt(3);
      if (rand == 0) {
        prompt = "May the blank be with you. I deal in protective seals and kinetic barriers. Do you wish to shield your path?";
      } else if (rand == 1) {
        prompt = "Blanks are the ultimate shield. Blanks restock to 2 for free on every new floor chamber. Do not hoard them.";
      } else {
        prompt = "The secret walls down here hold hollow cavities. Tap them with any firearm, then blow them open with a blank.";
      }
      responses = [
        PlayerResponse(tone: 'PEP', text: "I love safety! Shield me, please!", reply: "Safety is the ultimate bullet-seal. Guard your heart, child."),
        PlayerResponse(tone: 'TOUGH', text: "Just sell me the blanks. No sermon.", reply: "A simple transaction. Use them wisely when the bullet wall closes in."),
        PlayerResponse(tone: 'DEMENTED', text: "I want to paint the walls in beautiful blank-energy white!", reply: "An unhinged artistic vision... but blank waves carry profound stillness. May you find peace."),
      ];
    } else if (idClean == 'cursula') {
      final rand = math.Random().nextInt(3);
      if (rand == 0) {
        prompt = "Is that a handsome Gungeoneer slide-rolling into my shadow-embrace? *giggles* Need a dark bargain, sweetie?";
      } else if (rand == 1) {
        prompt = "My items carry a violet tint because they are kissed by the Jammed. Curse increases damage, but the reapers are watching... *giggles*";
      } else {
        prompt = "If you carry the Sixth Chamber, your coolness is amplified by your curse level. A magnificent synergy for dark souls, just like you.";
      }
      responses = [
        PlayerResponse(tone: 'PEP', text: "Ooh, dark magic! Let's bind our shadows together!", reply: "An adventurous spirit... Your violet aura grows stronger. Embrace the ink, sweetie."),
        PlayerResponse(tone: 'TOUGH', text: "I'll take the damage boost. I'm not afraid of the Jammed.", reply: "Fierce... but when the red-eyed reapers stalk you through the walls, remember who sold you the blade."),
        PlayerResponse(tone: 'DEMENTED', text: "Is that a Master Round in your pocket, or are you just excited to roll into my void?", reply: "Oh my, you have the most delightful, delirious mind! I love when you get unhinged! *winks with three eyes*"),
      ];
    } else if (idClean == 'flynt') {
      final rand = math.Random().nextInt(3);
      if (rand == 0) {
        prompt = "My lockpick teeth are itching. Do you carry the golden keys to unlock my chest of secrets? Or is your iron resolve locked shut?";
      } else if (rand == 1) {
        prompt = "See a chest with a tiny lock licking its lips? That is a mimic. Throw a liquid splash, or shoot it once before using a key.";
      } else {
        prompt = "If you have the Akey-47 and the Sheathed Key, your ammunition is infinite and every lock collapses on sight.";
      }
      responses = [
        PlayerResponse(tone: 'PEP', text: "I have a key! Let's open some chests!", reply: "Clack clack! I love the sound of turning tumblers. Here's a high-grade treasure for your collection!"),
        PlayerResponse(tone: 'TOUGH', text: "Keys are meant to be spent. Hand over the loot.", reply: "Efficient. No sentimentality for the iron. Buy or move along."),
        PlayerResponse(tone: 'DEMENTED', text: "My teeth are keys that unlock the doors of the sky!", reply: "That's... structurally concerning. Keep your teeth away from my keyholes."),
      ];
    } else if (idClean == 'professor goopton' || idClean == 'professor_goopton' || idClean == 'goopton') {
      final rand = math.Random().nextInt(3);
      if (rand == 0) {
        prompt = "Gloop... blub... splash... My liquid science is highly reactive. Stand back, unless you're prepared to get coated in chemical chaos!";
      } else if (rand == 1) {
        prompt = "The liquid elements down here react beautifully. Green poison trail melts organic flesh kin, while blue ice freezes their speed loops.";
      } else {
        prompt = "If you buy the Sponge or the Hazmat Suit, you are immune to my chemical spills. Stand on sludge with confidence!";
      }
      responses = [
        PlayerResponse(tone: 'PEP', text: "Yay, science experiments! Make it splat!", reply: "Blub! *splish splash* Reactants activated! Enjoy the toxic trail!"),
        PlayerResponse(tone: 'TOUGH', text: "Just give me the status immunity items.", reply: "Gloop. Boring but practical. Protect yourself from the fire and poison matrices."),
        PlayerResponse(tone: 'DEMENTED', text: "I want to swim in the green slime of the temporal sea!", reply: "Blob blub! That will dissolve your outer epidermal layers, but the trajectory would be magnificent!"),
      ];
    } else if (idClean == 'evil_muncher' || idClean == 'evil muncher') {
      prompt = "Grrr... crunch... I only chew the finest, rarest firearms. Give me your masterworks, or leave my dark altar.";
      responses = [
        PlayerResponse(tone: 'PEP', text: "I have a shiny A-Tier shotgun! Here!", reply: "Munch... crunch... DELICIOUS! Take this high-ordnance relic! Go cause havoc!"),
        PlayerResponse(tone: 'TOUGH', text: "Here are my primary weapons. Give me something lethal.", reply: "Grr... crunch. Acceptable sacrifice. Do not disappoint me with your aim."),
        PlayerResponse(tone: 'DEMENTED', text: "I fed my shadow to a regular muncher and it turned into you!", reply: "We are born from the gluttony of fallen guns. Chew on that, mortal."),
      ];
    } else if (idClean == 'tailor') {
      prompt = "Ah, the elevator shafts need maintenance. Do you carry the steel grid plates and casings required to anchor the floor lines?";
      responses = [
        PlayerResponse(tone: 'PEP', text: "I've got three Master Rounds and 180 casings!", reply: "Astounding! With these anchor structures, I can build an elevator shortcut to Chamber 3! Watch my wrench!"),
        PlayerResponse(tone: 'TOUGH', text: "Take the materials. Make the shaft work.", reply: "I like a hands-on foreman. Stand back, let me weld this cable."),
        PlayerResponse(tone: 'DEMENTED', text: "The elevator doesn't descend, the floor flies upwards into our hearts!", reply: "A fascinating... physical model. But we still need steel ropes to hold it, kid."),
      ];
    }

    return DialogueNode(
      id: 'fallback_$npcId',
      type: 'random_tip',
      prompt: prompt,
      responses: responses,
    );
  }
}
