part of '../app_theme.dart';

// Split from theme_models.dart — same library, no import changes.

class ThemeFlair {
  final Color scaffold;
  final Color card;
  final Color primary;
  final Color secondary;

  /// Colour applied to big "headline" numbers (DPS, Coolness, Curse).
  /// Kept separate from primary so Unicorn's pink stat doesn't clash
  /// with a pink card border.
  final Color headlineStat;

  /// Default colour for list bullet glyphs (used by [bulletGlyph]).
  final Color bulletColor;

  /// The glyph rendered in front of list items in themed contexts
  /// (e.g. `•`, `✦`, `—`, `·`).
  final String bulletGlyph;

  /// Whether a gold shimmer should sweep across themed headline
  /// numbers periodically (Coolmaxing signature).
  final bool shimmerHeadline;

  /// Whether headline numbers should be surrounded by tiny twinkling
  /// sparkles (Unicorn signature). Renders a few animated star glyphs
  /// that pulse and fade around the number.
  final bool sparkleNumbers;

  /// Optional glow colour for headline numbers. When non-null, numbers
  /// get a soft outer glow in this colour. Used by Unicorn palettes to
  /// make stats feel magical.
  final Color? numberGlowColor;

  /// Whether ✦ bullets should pulse opacity (Unicorn signature).
  final bool twinkleBullets;

  /// Whether the curse headline number should glow red, with glow
  /// intensity scaling with curse value (Curseblaster signature).
  final bool glowCurse;

  /// Whether headline numbers render with an embossed drop-shadow
  /// treatment (Winchester signature).
  final bool embossNumbers;

  /// Use `FontFeature.tabularFigures` so digit columns align — used by
  /// every theme except Unicorn (which prefers a softer proportional
  /// look to match the rounded display vibe).
  final bool tabularFigures;

  /// Size multiplier applied to themed headline numbers.
  final double numberSizeScale;

  /// Font weight applied to themed headline numbers.
  final FontWeight numberWeight;

  /// Italic slant for themed numbers (Unicorn leans a touch).
  final FontStyle numberStyle;

  /// Corner radius for themed chips (0–20).
  final double chipRadius;

  /// Corner radius for themed cards (0–30).
  final double cardRadius;

  /// Custom border color for cards (e.g. for winchester, minimalist).
  final Color? cardBorderColor;

  /// Custom border thickness for cards.
  final double cardBorderWidth;

  /// Whether themed chips render as filled pills (true) or just outline
  /// + underlined label (false — Minimalist Paper).
  final bool chipFilled;

  /// Divider colour for themed dividers/borders. Falls back to the
  /// Material default when null.
  final Color? dividerColor;

  /// Divider thickness for themed dividers/borders. 1.0 for hairline
  /// minimalist, up to ~1.4 for brass Winchester.
  final double dividerThickness;

  /// Tinted glow tones used by the always-on `_AmbientGlow` layer the
  /// overlay paints behind every theme (Bubblegum-style soft radial
  /// gradient that drifts gently). Picked per-theme so the glow reads
  /// as part of the palette rather than a generic pink wash.
  final Color glowPrimary;
  final Color glowSecondary;

  /// Per-theme ambient glow animation style. See [GlowStyle].
  final GlowStyle glowStyle;

  /// Animated border treatment for character avatars (see
  /// `widgets/avatar_aura.dart`). Defaults to `none` — opt in per
  /// theme so the picker preview can stay clean.
  final AvatarAuraStyle auraStyle;

  /// Optional glyph rendered in front of section titles (Effects,
  /// Notes, Synergies, Referenced By). Replaces the Material icon when
  /// non-null. Each theme picks a glyph that fits its identity:
  /// Coolmaxing ❖, Unicorn ♡, Curseblaster †, Winchester ★.
  final String? headerGlyph;

  /// Render section titles in ALL CAPS with extra letter-spacing and
  /// drop the leading icon. Minimalist signature.
  final bool headerAllCaps;

  /// Optional hairline rule painted directly underneath section titles.
  /// Per-theme accent so each detail page is recognisably "the gold
  /// theme" / "the blood theme" / "the brass theme" at a glance.
  final Color? headerUnderlineColor;

  /// Paint a 1px hairline frame around the viewport. Minimalist's
  /// "printed page" signature — every other theme leaves this false.
  final bool pageFrame;

  /// Optional per-stat-group accent colors for the gun detail screen.
  /// When null, [StatGroup] falls back to semantic defaults
  /// (Combat=red, Handling=cyan, Meta=amber). Themes opt in to
  /// palette-tied group colors by setting these.
  final Color? statGroupCombat;
  final Color? statGroupHandling;
  final Color? statGroupMeta;

  /// Per-theme default font. When non-null, switching to this theme
  /// applies this font. Users can still override via the font picker.
  /// When null, the global VisualPrefs font is used.
  final AppFont? font;

  const ThemeFlair({
    required this.scaffold,
    required this.card,
    required this.primary,
    required this.secondary,
    required this.headlineStat,
    required this.bulletColor,
    this.bulletGlyph = '•',
    this.shimmerHeadline = false,
    this.sparkleNumbers = false,
    this.numberGlowColor,
    this.twinkleBullets = false,
    this.glowCurse = false,
    this.embossNumbers = false,
    this.tabularFigures = true,
    this.numberSizeScale = 1.0,
    this.numberWeight = FontWeight.w700,
    this.numberStyle = FontStyle.normal,
    this.chipRadius = 10,
    this.cardRadius = 12,
    this.cardBorderColor,
    this.cardBorderWidth = 1.0,
    this.chipFilled = true,
    this.dividerColor,
    this.dividerThickness = 1.0,
    this.glowPrimary = const Color(0x22FFFFFF),
    this.glowSecondary = const Color(0x11FFFFFF),
    this.glowStyle = GlowStyle.orbit,
    this.auraStyle = AvatarAuraStyle.none,
    this.headerGlyph,
    this.headerAllCaps = false,
    this.headerUnderlineColor,
    this.pageFrame = false,
    this.statGroupCombat,
    this.statGroupHandling,
    this.statGroupMeta,
    this.font,
  });
}

/// Shift the hue of a [Color] by [degrees] in HSL space.
Color _hueShift(Color c, double degrees) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withHue((hsl.hue + degrees) % 360).toColor();
}

/// Return a copy of [f] with every [Color] field hue-shifted by [degrees].
ThemeFlair _hueShiftFlair(ThemeFlair f, double degrees) {
  if (degrees == 0) return f;
  return ThemeFlair(
    scaffold: _hueShift(f.scaffold, degrees),
    card: _hueShift(f.card, degrees),
    primary: _hueShift(f.primary, degrees),
    secondary: _hueShift(f.secondary, degrees),
    headlineStat: _hueShift(f.headlineStat, degrees),
    bulletColor: _hueShift(f.bulletColor, degrees),
    bulletGlyph: f.bulletGlyph,
    shimmerHeadline: f.shimmerHeadline,
    sparkleNumbers: f.sparkleNumbers,
    numberGlowColor:
        f.numberGlowColor != null
            ? _hueShift(f.numberGlowColor!, degrees)
            : null,
    twinkleBullets: f.twinkleBullets,
    glowCurse: f.glowCurse,
    embossNumbers: f.embossNumbers,
    tabularFigures: f.tabularFigures,
    numberSizeScale: f.numberSizeScale,
    numberWeight: f.numberWeight,
    numberStyle: f.numberStyle,
    chipRadius: f.chipRadius,
    cardRadius: f.cardRadius,
    cardBorderColor:
        f.cardBorderColor != null
            ? _hueShift(f.cardBorderColor!, degrees)
            : null,
    cardBorderWidth: f.cardBorderWidth,
    chipFilled: f.chipFilled,
    dividerColor:
        f.dividerColor != null ? _hueShift(f.dividerColor!, degrees) : null,
    dividerThickness: f.dividerThickness,
    glowPrimary: _hueShift(f.glowPrimary, degrees),
    glowSecondary: _hueShift(f.glowSecondary, degrees),
    glowStyle: f.glowStyle,
    auraStyle: f.auraStyle,
    headerGlyph: f.headerGlyph,
    headerAllCaps: f.headerAllCaps,
    headerUnderlineColor:
        f.headerUnderlineColor != null
            ? _hueShift(f.headerUnderlineColor!, degrees)
            : null,
    pageFrame: f.pageFrame,
    statGroupCombat:
        f.statGroupCombat != null
            ? _hueShift(f.statGroupCombat!, degrees)
            : null,
    statGroupHandling:
        f.statGroupHandling != null
            ? _hueShift(f.statGroupHandling!, degrees)
            : null,
    statGroupMeta:
        f.statGroupMeta != null ? _hueShift(f.statGroupMeta!, degrees) : null,
  );
}

/// A single remix variant. When [flair] is non-null it replaces the
/// theme's static flair entirely; otherwise [hueShift] is applied.

class VisualPrefs {
  /// Background glow intensity: 0.0 = off, 1.0 = full theme glow.
  /// Defaults to 0.0 — the out-of-box look is clean and unaffected.
  final double glowIntensity;

  /// Whether the particle system is enabled. Off by default.
  final bool particlesEnabled;

  /// Selected particle preset (replaces old CustomParticleType).
  final ParticlePreset particlePreset;

  /// Glow effect applied to particles.
  final GlowEffect particleGlowEffect;

  /// Whether to connect nearby particles with lines (particles.js style).
  final bool particleLineLinks;

  /// Whether particles bounce off edges instead of wrapping.
  final bool particleBounce;

  /// User-selected glow color for the ambient screen glow (12-color palette).
  final int glowColorIndex;

  /// Custom glow color as ARGB int; 0 = use the curated [glowColors] palette.
  final int glowCustomColor;

  /// User glow-style override: -1 = theme default, else [GlowStyle] index.
  final int glowStyleIndex;

  /// Font-weight bias applied globally on top of the active theme.
  /// Stored as FontWeight index steps (-2..+2 → thin..bold); consumed
  /// by GoopText as `weight.index + bias`.
  final int fontWeightBias;
  final int fontLetterSpacing; // ±steps ×0.5pt applied in GoopText

  /// Selected app-wide font. Defaults to Gungeon so the OOB look is
  /// recognisable to fans.
  final AppFont font;

  /// User-selected base font size (pt). Discrete steps for crisp UX.
  final double fontSize;

  /// Font size for inventory tiles specifically. Let users scale it independently.
  final double inventoryFontSize;

  /// Global display mode for inventory screens (grid variations).
  final InventoryDisplayMode inventoryDisplayMode;

  /// Custom Dice Settings
  final CustomDiceType customDiceType;
  final double particleSizeScale;
  final double particleOpacity;
  final int particleCount;

  /// Dialogue Settings
  final bool dialogueHapticsEnabled;
  final int dialogueTextSpeedMs;

  final bool isGoopianLanguage;
  final bool spongeActive;

  /// Whether the Effects panel accordion is shown on the active-run dashboard.
  final bool showEffectsPanel;

  /// Whether the Shrine tracker panel is shown on the active-run dashboard.
  final bool showShrinePanel;

  /// Whether special-item/gun dashboards are shown on the active-run screen.
  final bool showDashboards;

  /// User-defined column count for the classic Periodic grid. 0 = Auto, or 2, 3, 4.
  final int periodicGridColumnCount;

  /// User-selected particle color schema (overrides preset colors).
  final ParticleColorSchema particleColorSchema;

  /// User-selected particle speed multiplier.
  final ParticleSpeed particleSpeed;

  /// Typed particle system — index into [ParticleType.values] (0 = dot).
  final int particleTypeIndex;

  /// Index into the active theme's 3 flavored color schemas (0-2).
  final int particleSchemaIndex;

  /// Chaotic motion toggle — organic turbulence on top of drift.
  final bool particleChaos;

  /// Touch/tilt-reactive toggle — particles respond to device tilt.
  final bool particleTouch;

  /// Whether ambient fragment shaders (Q3) are enabled. Off by default —
  /// shaders are GPU-intensive and opt-in. See [shaderPreset].
  final bool shaderEnabled;

  /// Which ambient shader to render when [shaderEnabled] is true.
  /// Defaults to [ShaderPreset.digitalRain].
  final ShaderPreset shaderPreset;

  /// Computed scale factor applied globally via MediaQuery.
  double get textScaleFactor => fontSize / 14.0;

  /// Discrete font-size steps the UI presents as chips.
  static const fontSizeSteps = [
    6.0,
    8.0,
    10.0,
    12.0,
    14.0,
    18.0,
    20.0,
    24.0,
    28.0,
    32.0,
  ];

  /// 36 deep, curated glow colors for the ambient screen glow.
  static const glowColors = [
    // Original 12
    Color(0xFF0D47A1), // Abyssal Blue
    Color(0xFFB71C1C), // Curse Crimson
    Color(0xFFE65100), // Forge Amber
    Color(0xFF006064), // Frost Cyan
    Color(0xFF1B5E20), // Toxic Green
    Color(0xFF4A148C), // Void Purple
    Color(0xFFBF8C00), // Gungeon Gold
    Color(0xFF1A237E), // Shadow Indigo
    Color(0xFF880E4F), // Blood Rose
    Color(0xFF004D40), // Ethereal Teal
    Color(0xFF6A1B9A), // Magenta Pulse
    Color(0xFF263238), // Obsidian Grey
    // 24 new curated colors
    Color(0xFF01579B), // Deep Ocean
    Color(0xFFD32F2F), // Ember Red
    Color(0xFFF57F17), // Sunfire
    Color(0xFF00838F), // Arctic Teal
    Color(0xFF2E7D32), // Forest
    Color(0xFF6A1B9A), // Royal Plum
    Color(0xFFF9A825), // Honey
    Color(0xFF283593), // Navy
    Color(0xFFAD1457), // Wine
    Color(0xFF00695C), // Peacock
    Color(0xFFAD1457), // Raspberry
    Color(0xFF37474F), // Slate
    Color(0xFF1565C0), // Sapphire
    Color(0xFFC62828), // Ruby
    Color(0xFFEF6C00), // Tangerine
    Color(0xFF00ACC1), // Aqua
    Color(0xFF558B2F), // Olive
    Color(0xFF4527A0), // Indigo Night
    Color(0xFFC17900), // Bronze
    Color(0xFF1A237E), // Midnight
    Color(0xFF6D214F), // Maroon
    Color(0xFF0D7377), // Lagoon
    Color(0xFF8E24AA), // Orchid
    Color(0xFF455A64), // Steel
    // 12 pinks & purples — the glow lab's neon side
    Color(0xFFEC407A), // Hot Pink
    Color(0xFFAB47BC), // Mauve Glow
    Color(0xFF7B1FA2), // Deep Purple
    Color(0xFFD81B60), // Raspberry
    Color(0xFF9C27B0), // Neon Violet
    Color(0xFFBA68C8), // Lilac
    Color(0xFFE91E63), // Magenta Blaze
    Color(0xFF8E24AA), // Amethyst
    Color(0xFFCE93D8), // Soft Orchid
    Color(0xFFF06292), // Bubblegum
    Color(0xFF5E35B1), // Ultraviolet
    Color(0xFFAD1457), // Deep Rose
  ];

  /// Resolved ambient glow color — custom picker color wins over the
  /// curated palette entry. Used by the ambient glow overlay.
  Color get glowColor =>
      glowCustomColor != 0
          ? Color(glowCustomColor)
          : glowColors[glowColorIndex.clamp(0, glowColors.length - 1)];

  /// User glow-style override; null means follow the theme's flair style.
  GlowStyle? get glowStyleOverride =>
      glowStyleIndex < 0 || glowStyleIndex >= GlowStyle.values.length
          ? null
          : GlowStyle.values[glowStyleIndex];

  const VisualPrefs({
    this.glowIntensity = 0.0,
    this.particlesEnabled = true,
    this.particlePreset = ParticlePreset.gungeonDust,
    this.particleGlowEffect = GlowEffect.none,
    this.particleLineLinks = false,
    this.particleBounce = false,
    this.glowColorIndex = 0,
    this.glowCustomColor = 0,
    this.glowStyleIndex = -1,
    this.fontWeightBias = 0,
    this.fontLetterSpacing = 0,
    this.font = AppFont.gungeon,
    this.fontSize = 12.0,
    this.inventoryFontSize = 12.0,
    this.inventoryDisplayMode = InventoryDisplayMode.classicPeriodic,
    this.customDiceType = CustomDiceType.themeDefault,
    this.particleSizeScale = 1.0,
    this.particleOpacity = 0.55,
    this.particleCount = 32,
    this.dialogueHapticsEnabled = true,
    this.dialogueTextSpeedMs = 30,
    this.isGoopianLanguage = false,
    this.spongeActive = false,
    this.showEffectsPanel = false,
    this.showShrinePanel = false,
    this.showDashboards = true,
    this.periodicGridColumnCount = 0,
    this.particleColorSchema = ParticleColorSchema.presetDefault,
    this.particleSpeed = ParticleSpeed.normal,
    this.particleTypeIndex = 0,
    this.particleSchemaIndex = 0,
    this.particleChaos = false,
    this.particleTouch = true,
    this.shaderEnabled = false,
    this.shaderPreset = ShaderPreset.digitalRain,
  });

  static const _kGlow = 'vp.glow_v1';
  static const _kParticles = 'vp.particles_v2'; // v2: default on (was v1=false)
  static const _kSpacing = 'visual.font.spacing';
  static const _kWeight = 'vp.weight_v1';
  static const _kFont = 'vp.font_v1';
  static const _kFontSize = 'vp.font_size_v1';
  static const _kInventoryFontSize = 'vp.inventory_font_size_v1';
  static const _kInventoryDisplayMode = 'vp.inventory_display_mode_v1';
  static const _kScaleLegacy = 'vp.scale_v1'; // migrated to _kFontSize

  static const _kParticlePreset = 'vp.particle_preset_v3';
  static const _kParticleGlowEffect = 'vp.particle_glow_effect_v1';
  static const _kParticleLineLinks = 'vp.particle_line_links_v1';
  static const _kParticleBounce = 'vp.particle_bounce_v1';
  static const _kGlowColorIndex = 'vp.glow_color_index_v1';
  static const _kGlowCustom = 'vp.glow_custom_v1';
  static const _kGlowStyleIndex = 'vp.glow_style_index_v1';
  static const _kCustomDiceType = 'vp.custom_dice_type_v1';
  static const _kParticleSizeScale = 'vp.particle_size_scale_v2';
  static const _kParticleOpacity = 'vp.particle_opacity_v1';
  static const _kParticleCount = 'vp.particle_count_v1';

  static const _kDialogueHaptics = 'vp.dialogue_haptics_v1';
  static const _kDialogueTextSpeed = 'vp.dialogue_text_speed_v1';
  static const _kGoopianLanguage = 'vp.goopian_language_v1';
  static const _kSpongeActive = 'vp.sponge_active_v1';
  static const _kShowEffectsPanel = 'vp.show_effects_panel_v1';
  static const _kShowShrinePanel = 'vp.show_shrine_panel_v1';
  static const _kShowDashboards = 'vp.show_dashboards_v1';
  static const _kPeriodicGridColumnCount = 'vp.periodic_grid_column_count_v1';
  static const _kParticleColorSchema = 'vp.particle_color_schema_v1';
  static const _kParticleSpeed = 'vp.particle_speed_v1';
  static const _kParticleTypeIdx = 'vp.particle_type_v1';
  static const _kParticleSchemaIdx = 'vp.particle_schema_idx_v1';
  static const _kParticleChaos = 'vp.particle_chaos_v1';
  static const _kParticleTouch = 'vp.particle_touch_v1';
  static const _kShaderEnabled = 'vp.shader_enabled_v1';
  static const _kShaderPreset = 'vp.shader_preset_v1';

  static final ValueNotifier<VisualPrefs> notifier = ValueNotifier(
    const VisualPrefs(),
  );

  /// Hydrate from disk. Call from `main()` before `runApp`.
  static double _snapToStep(double v) {
    return fontSizeSteps.reduce(
      (a, b) => (v - a).abs() < (v - b).abs() ? a : b,
    );
  }

  static Future<void> init() async {
    try {
      final p = await SharedPreferences.getInstance();
      final fontIdx = p.getInt(_kFont);
      final font =
          (fontIdx != null && fontIdx >= 0 && fontIdx < AppFont.values.length)
              ? AppFont.values[fontIdx]
              : AppFont.gungeon;

      // Migrate from old scale key if present.
      double fontSize;
      final savedSize = p.getDouble(_kFontSize);
      if (savedSize != null) {
        fontSize = _snapToStep(savedSize.clamp(6.0, 20.0));
      } else {
        final legacyScale = p.getDouble(_kScaleLegacy);
        if (legacyScale != null) {
          fontSize = _snapToStep((legacyScale * 14.0).clamp(6.0, 20.0));
          // Best-effort cleanup of legacy key.
          unawaited(p.remove(_kScaleLegacy));
          unawaited(p.setDouble(_kFontSize, fontSize));
        } else {
          fontSize = 14.0;
        }
      }

      final particlePresetIdx = p.getInt(_kParticlePreset) ?? 0;
      final particlePreset =
          ParticlePreset.values[particlePresetIdx.clamp(
            0,
            ParticlePreset.values.length - 1,
          )];
      final particleGlowIdx = p.getInt(_kParticleGlowEffect) ?? 0;
      final particleGlowEffect =
          GlowEffect.values[particleGlowIdx.clamp(
            0,
            GlowEffect.values.length - 1,
          )];
      final particleLineLinks = p.getBool(_kParticleLineLinks) ?? false;
      final particleBounce = p.getBool(_kParticleBounce) ?? false;
      final glowColorIndex = p.getInt(_kGlowColorIndex) ?? 0;
      final glowCustomColor = p.getInt(_kGlowCustom) ?? 0;
      final glowStyleIndex = p.getInt(_kGlowStyleIndex) ?? -1;

      final customDiceTypeIdx = p.getInt(_kCustomDiceType) ?? 0;
      final customDiceType =
          CustomDiceType.values[customDiceTypeIdx.clamp(
            0,
            CustomDiceType.values.length - 1,
          )];

      final inventoryFontSize = p.getDouble(_kInventoryFontSize) ?? 12.0;
      final displayModeIdx = p.getInt(_kInventoryDisplayMode) ?? 0;
      final inventoryDisplayMode =
          InventoryDisplayMode.values[displayModeIdx.clamp(
            0,
            InventoryDisplayMode.values.length - 1,
          )];

      final isGoopian = p.getBool(_kGoopianLanguage) ?? false;
      final spongeActive = p.getBool(_kSpongeActive) ?? false;
      final showEffectsPanel = p.getBool(_kShowEffectsPanel) ?? false;
      final showShrinePanel = p.getBool(_kShowShrinePanel) ?? false;
      final showDashboards = p.getBool(_kShowDashboards) ?? true;
      final periodicGridColumnCount = p.getInt(_kPeriodicGridColumnCount) ?? 0;
      final particleColorSchemaIdx = p.getInt(_kParticleColorSchema) ?? 0;
      final particleColorSchema =
          ParticleColorSchema.values[particleColorSchemaIdx.clamp(
            0,
            ParticleColorSchema.values.length - 1,
          )];
      final particleSpeedIdx = p.getInt(_kParticleSpeed) ?? 2;
      final particleSpeed =
          ParticleSpeed.values[particleSpeedIdx.clamp(
            0,
            ParticleSpeed.values.length - 1,
          )];

      final shaderEnabled = p.getBool(_kShaderEnabled) ?? false;
      final shaderPresetIdx = p.getInt(_kShaderPreset) ?? 0;
      final shaderPreset =
          ShaderPreset.values[shaderPresetIdx.clamp(
            0,
            ShaderPreset.values.length - 1,
          )];

      notifier.value = VisualPrefs(
        glowIntensity: p.getDouble(_kGlow) ?? 0.0,
        particlesEnabled: p.getBool(_kParticles) ?? true,
        particlePreset: particlePreset,
        particleGlowEffect: particleGlowEffect,
        particleLineLinks: particleLineLinks,
        particleBounce: particleBounce,
        glowColorIndex: glowColorIndex,
        glowCustomColor: glowCustomColor,
        glowStyleIndex: glowStyleIndex,
        fontWeightBias: p.getInt(_kWeight) ?? 0,
        fontLetterSpacing: p.getInt(_kSpacing) ?? 0,
        font: font,
        fontSize: fontSize,
        inventoryFontSize: inventoryFontSize,
        inventoryDisplayMode: inventoryDisplayMode,
        customDiceType: customDiceType,
        particleSizeScale: p.getDouble(_kParticleSizeScale) ?? 1.0,
        particleOpacity: p.getDouble(_kParticleOpacity) ?? 0.55,
        particleCount: p.getInt(_kParticleCount) ?? 32,
        dialogueHapticsEnabled: p.getBool(_kDialogueHaptics) ?? true,
        dialogueTextSpeedMs: p.getInt(_kDialogueTextSpeed) ?? 30,
        isGoopianLanguage: isGoopian,
        spongeActive: spongeActive,
        showEffectsPanel: showEffectsPanel,
        showShrinePanel: showShrinePanel,
        showDashboards: showDashboards,
        periodicGridColumnCount: periodicGridColumnCount,
        particleColorSchema: particleColorSchema,
        particleSpeed: particleSpeed,
        particleTypeIndex: (p.getInt(_kParticleTypeIdx) ?? 0).clamp(
          0,
          ParticleType.values.length - 1,
        ),
        particleSchemaIndex: (p.getInt(_kParticleSchemaIdx) ?? 0).clamp(0, 2),
        particleChaos: p.getBool(_kParticleChaos) ?? false,
        particleTouch: p.getBool(_kParticleTouch) ?? true,
        shaderEnabled: shaderEnabled,
        shaderPreset: shaderPreset,
      );
    } catch (e) {
      debugPrint('[AppTheme] prefs error: $e');
    }
  }

  static Future<void> setGlow(double v) async {
    notifier.value = notifier.value._with(glowIntensity: v.clamp(0.0, 1.0));
    _persist();
  }

  static Future<void> setParticles(bool v) async {
    notifier.value = notifier.value._with(particlesEnabled: v);
    _persist();
  }

  static Future<void> setFontWeightBias(int v) async {
    notifier.value = notifier.value._with(fontWeightBias: v.clamp(-800, 800));
  }

  static void setFontLetterSpacing(int v) {
    notifier.value = notifier.value._with(fontLetterSpacing: v.clamp(-2, 2));
    _persist();
  }

  static Future<void> setFont(AppFont f) async {
    notifier.value = notifier.value._with(font: f);
    _persist();
  }

  static Future<void> setFontSize(double v) async {
    final clamped = v.clamp(6.0, 20.0);
    notifier.value = notifier.value._with(fontSize: clamped);
    _persist();
  }

  static Future<void> setInventoryFontSize(double v) async {
    final clamped = v.clamp(10.0, 18.0);
    notifier.value = notifier.value._with(inventoryFontSize: clamped);
    _persist();
  }

  static Future<void> setInventoryDisplayMode(InventoryDisplayMode mode) async {
    notifier.value = notifier.value._with(inventoryDisplayMode: mode);
    _persist();
  }

  static Future<void> setParticlePreset(ParticlePreset v) async {
    notifier.value = notifier.value._with(particlePreset: v);
    _persist();
  }

  static Future<void> setParticleGlowEffect(GlowEffect v) async {
    notifier.value = notifier.value._with(particleGlowEffect: v);
    _persist();
  }

  static Future<void> setParticleLineLinks(bool v) async {
    notifier.value = notifier.value._with(particleLineLinks: v);
    _persist();
  }

  static Future<void> setParticleBounce(bool v) async {
    notifier.value = notifier.value._with(particleBounce: v);
    _persist();
  }

  static Future<void> setGlowColorIndex(int v) async {
    notifier.value = notifier.value._with(
      glowColorIndex: v.clamp(0, glowColors.length - 1),
      glowCustomColor: 0,
    );
    _persist();
  }

  /// Set a custom glow color straight from the color picker — bypasses
  /// the curated palette. Resolved by [VisualPrefs.glowColor].
  static Future<void> setGlowColor(Color c) async {
    notifier.value = notifier.value._with(glowCustomColor: c.toARGB32());
    _persist();
  }

  /// User glow-style override: -1 follows the theme's flair style.
  static Future<void> setGlowStyleIndex(int v) async {
    notifier.value = notifier.value._with(
      glowStyleIndex: v.clamp(-1, GlowStyle.values.length - 1),
    );
    _persist();
  }

  static Future<void> setParticleSizeScale(double v) async {
    notifier.value = notifier.value._with(particleSizeScale: v.clamp(0.3, 2.0));
    _persist();
  }

  static Future<void> setParticleOpacity(double v) async {
    notifier.value = notifier.value._with(particleOpacity: v.clamp(0.0, 1.0));
    _persist();
  }

  static Future<void> setParticleCount(int v) async {
    notifier.value = notifier.value._with(particleCount: v.clamp(1, 200));
    _persist();
  }

  static Future<void> setCustomDiceType(CustomDiceType type) async {
    notifier.value = notifier.value._with(customDiceType: type);
    _persist();
  }

  static Future<void> setDialogueHapticsEnabled(bool v) async {
    notifier.value = notifier.value._with(dialogueHapticsEnabled: v);
    _persist();
  }

  static Future<void> setDialogueTextSpeedMs(int v) async {
    notifier.value = notifier.value._with(dialogueTextSpeedMs: v);
    _persist();
  }

  static Future<void> setIsGoopianLanguage(bool v) async {
    notifier.value = notifier.value._with(isGoopianLanguage: v);
    _persist();
  }

  static Future<void> setSpongeActive(bool v) async {
    notifier.value = notifier.value._with(spongeActive: v);
    _persist();
  }

  static Future<void> setShowEffectsPanel(bool v) async {
    notifier.value = notifier.value._with(showEffectsPanel: v);
    _persist();
  }

  static Future<void> setShowShrinePanel(bool v) async {
    notifier.value = notifier.value._with(showShrinePanel: v);
    _persist();
  }

  static Future<void> setShowDashboards(bool v) async {
    notifier.value = notifier.value._with(showDashboards: v);
    _persist();
  }

  static Future<void> setPeriodicGridColumnCount(int v) async {
    notifier.value = notifier.value._with(
      periodicGridColumnCount: v.clamp(0, 4),
    );
    _persist();
  }

  static Future<void> setParticleColorSchema(ParticleColorSchema v) async {
    notifier.value = notifier.value._with(particleColorSchema: v);
    _persist();
  }

  static Future<void> setParticleTypeIndex(int v) async {
    notifier.value = notifier.value._with(
      particleTypeIndex: v.clamp(0, ParticleType.values.length - 1),
    );
    _persist();
  }

  static Future<void> setParticleSchemaIndex(int v) async {
    notifier.value = notifier.value._with(particleSchemaIndex: v.clamp(0, 2));
    _persist();
  }

  static Future<void> setParticleChaos(bool v) async {
    notifier.value = notifier.value._with(particleChaos: v);
    _persist();
  }

  static Future<void> setParticleTouch(bool v) async {
    notifier.value = notifier.value._with(particleTouch: v);
    _persist();
  }

  static Future<void> setParticleSpeed(ParticleSpeed v) async {
    notifier.value = notifier.value._with(particleSpeed: v);
    _persist();
  }

  static Future<void> setShaderEnabled(bool v) async {
    notifier.value = notifier.value._with(shaderEnabled: v);
    _persist();
  }

  /// Apply a full set of curated visual settings at once (used when
  /// selecting a premade theme).
  static Future<void> applyCuration(ThemeCuration c) async {
    notifier.value = notifier.value._with(
      particlePreset: c.particlePreset,
      particleColorSchema: c.colorSchema,
      particleGlowEffect: c.glowEffect,
      particleSpeed: c.speed,
      particleCount: c.particleCount,
      particleSizeScale: c.particleSizeScale,
      particleOpacity: c.particleOpacity,
      particleLineLinks: c.particleLineLinks,
      particleBounce: c.particleBounce,
      glowColorIndex: c.glowColorIndex,
      glowIntensity: c.glowIntensity,
      shaderEnabled: c.shaderEnabled,
      shaderPreset: c.shaderPreset ?? notifier.value.shaderPreset,
      particlesEnabled: true,
    );
    _persist();
  }

  static Future<void> setShaderPreset(ShaderPreset v) async {
    notifier.value = notifier.value._with(shaderPreset: v);
    _persist();
  }

  /// Replace the entire VisualPrefs state and persist to disk.
  /// Used when restoring a saved custom theme's preferences.
  static Future<void> replaceAndPersist(VisualPrefs prefs) async {
    notifier.value = prefs;
    await _persist();
  }

  static Future<void> _persist() async {
    try {
      final p = await SharedPreferences.getInstance();
      final v = notifier.value;
      await p.setDouble(_kGlow, v.glowIntensity);
      await p.setBool(_kParticles, v.particlesEnabled);
      await p.setInt(_kWeight, v.fontWeightBias);
      await p.setInt(_kSpacing, v.fontLetterSpacing);
      await p.setInt(_kFont, v.font.index);
      await p.setDouble(_kFontSize, v.fontSize);
      await p.setDouble(_kInventoryFontSize, v.inventoryFontSize);
      await p.setInt(_kInventoryDisplayMode, v.inventoryDisplayMode.index);

      await p.setInt(_kParticlePreset, v.particlePreset.index);
      await p.setInt(_kParticleGlowEffect, v.particleGlowEffect.index);
      await p.setBool(_kParticleLineLinks, v.particleLineLinks);
      await p.setBool(_kParticleBounce, v.particleBounce);
      await p.setInt(_kGlowColorIndex, v.glowColorIndex);
      await p.setInt(_kGlowCustom, v.glowCustomColor);
      await p.setInt(_kGlowStyleIndex, v.glowStyleIndex);
      await p.setInt(_kCustomDiceType, v.customDiceType.index);
      await p.setDouble(_kParticleSizeScale, v.particleSizeScale);
      await p.setDouble(_kParticleOpacity, v.particleOpacity);
      await p.setInt(_kParticleCount, v.particleCount);
      await p.setBool(_kDialogueHaptics, v.dialogueHapticsEnabled);
      await p.setInt(_kDialogueTextSpeed, v.dialogueTextSpeedMs);
      await p.setBool(_kGoopianLanguage, v.isGoopianLanguage);
      await p.setBool(_kSpongeActive, v.spongeActive);
      await p.setBool(_kShowEffectsPanel, v.showEffectsPanel);
      await p.setBool(_kShowShrinePanel, v.showShrinePanel);
      await p.setBool(_kShowDashboards, v.showDashboards);
      await p.setInt(_kPeriodicGridColumnCount, v.periodicGridColumnCount);
      await p.setInt(_kParticleColorSchema, v.particleColorSchema.index);
      await p.setInt(_kParticleSpeed, v.particleSpeed.index);
      await p.setInt(_kParticleTypeIdx, v.particleTypeIndex);
      await p.setInt(_kParticleSchemaIdx, v.particleSchemaIndex);
      await p.setBool(_kParticleChaos, v.particleChaos);
      await p.setBool(_kParticleTouch, v.particleTouch);
      await p.setBool(_kShaderEnabled, v.shaderEnabled);
      await p.setInt(_kShaderPreset, v.shaderPreset.index);
    } catch (e) {
      debugPrint('[AppTheme] prefs error: $e');
    }
  }

  VisualPrefs _with({
    double? glowIntensity,
    bool? particlesEnabled,
    int? fontWeightBias,
    int? fontLetterSpacing,
    AppFont? font,
    double? fontSize,
    double? inventoryFontSize,
    InventoryDisplayMode? inventoryDisplayMode,
    ParticlePreset? particlePreset,
    GlowEffect? particleGlowEffect,
    bool? particleLineLinks,
    bool? particleBounce,
    int? glowColorIndex,
    int? glowCustomColor,
    int? glowStyleIndex,
    CustomDiceType? customDiceType,
    double? particleSizeScale,
    double? particleOpacity,
    int? particleCount,
    bool? dialogueHapticsEnabled,
    int? dialogueTextSpeedMs,
    bool? isGoopianLanguage,
    bool? spongeActive,
    bool? showEffectsPanel,
    bool? showShrinePanel,
    bool? showDashboards,
    int? periodicGridColumnCount,
    ParticleColorSchema? particleColorSchema,
    ParticleSpeed? particleSpeed,
    int? particleTypeIndex,
    int? particleSchemaIndex,
    bool? particleChaos,
    bool? particleTouch,
    bool? shaderEnabled,
    ShaderPreset? shaderPreset,
  }) => VisualPrefs(
    glowIntensity: glowIntensity ?? this.glowIntensity,
    particlesEnabled: particlesEnabled ?? this.particlesEnabled,
    fontWeightBias: fontWeightBias ?? this.fontWeightBias,
    fontLetterSpacing: fontLetterSpacing ?? this.fontLetterSpacing,
    font: font ?? this.font,
    fontSize: fontSize ?? this.fontSize,
    inventoryFontSize: inventoryFontSize ?? this.inventoryFontSize,
    inventoryDisplayMode: inventoryDisplayMode ?? this.inventoryDisplayMode,
    particlePreset: particlePreset ?? this.particlePreset,
    particleGlowEffect: particleGlowEffect ?? this.particleGlowEffect,
    particleLineLinks: particleLineLinks ?? this.particleLineLinks,
    particleBounce: particleBounce ?? this.particleBounce,
    glowColorIndex: glowColorIndex ?? this.glowColorIndex,
    customDiceType: customDiceType ?? this.customDiceType,
    particleSizeScale: particleSizeScale ?? this.particleSizeScale,
    particleOpacity: particleOpacity ?? this.particleOpacity,
    particleCount: particleCount ?? this.particleCount,
    dialogueHapticsEnabled:
        dialogueHapticsEnabled ?? this.dialogueHapticsEnabled,
    dialogueTextSpeedMs: dialogueTextSpeedMs ?? this.dialogueTextSpeedMs,
    isGoopianLanguage: isGoopianLanguage ?? this.isGoopianLanguage,
    spongeActive: spongeActive ?? this.spongeActive,
    showEffectsPanel: showEffectsPanel ?? this.showEffectsPanel,
    showShrinePanel: showShrinePanel ?? this.showShrinePanel,
    showDashboards: showDashboards ?? this.showDashboards,
    periodicGridColumnCount:
        periodicGridColumnCount ?? this.periodicGridColumnCount,
    particleColorSchema: particleColorSchema ?? this.particleColorSchema,
    particleSpeed: particleSpeed ?? this.particleSpeed,
    particleTypeIndex: particleTypeIndex ?? this.particleTypeIndex,
    particleSchemaIndex: particleSchemaIndex ?? this.particleSchemaIndex,
    particleChaos: particleChaos ?? this.particleChaos,
    particleTouch: particleTouch ?? this.particleTouch,
    shaderEnabled: shaderEnabled ?? this.shaderEnabled,
    shaderPreset: shaderPreset ?? this.shaderPreset,
  );

  /// Serialize to JSON for custom theme persistence.
  Map<String, dynamic> toJson() => {
    'glowIntensity': glowIntensity,
    'particlesEnabled': particlesEnabled,
    'fontWeightBias': fontWeightBias,
    'font': font.index,
    'fontSize': fontSize,
    'inventoryFontSize': inventoryFontSize,
    'inventoryDisplayMode': inventoryDisplayMode.index,
    'particlePreset': particlePreset.index,
    'particleGlowEffect': particleGlowEffect.index,
    'particleLineLinks': particleLineLinks,
    'particleBounce': particleBounce,
    'glowColorIndex': glowColorIndex,
    'glowCustomColor': glowCustomColor,
    'glowStyleIndex': glowStyleIndex,
    'customDiceType': customDiceType.index,
    'particleSizeScale': particleSizeScale,
    'particleOpacity': particleOpacity,
    'particleCount': particleCount,
    'dialogueHapticsEnabled': dialogueHapticsEnabled,
    'dialogueTextSpeedMs': dialogueTextSpeedMs,
    'isGoopianLanguage': isGoopianLanguage,
    'spongeActive': spongeActive,
    'showEffectsPanel': showEffectsPanel,
    'showShrinePanel': showShrinePanel,
    'showDashboards': showDashboards,
    'periodicGridColumnCount': periodicGridColumnCount,
    'particleColorSchema': particleColorSchema.index,
    'particleSpeed': particleSpeed.index,
    'shaderEnabled': shaderEnabled,
    'shaderPreset': shaderPreset.index,
  };

  /// Deserialize from JSON for custom theme restoration.
  factory VisualPrefs.fromJson(Map<String, dynamic> j) {
    return VisualPrefs(
      glowIntensity: (j['glowIntensity'] as num?)?.toDouble() ?? 0.0,
      particlesEnabled: j['particlesEnabled'] as bool? ?? false,
      fontWeightBias: j['fontWeightBias'] as int? ?? 0,
      font: AppFont.values[(j['font'] as int?) ?? 0],
      fontSize: (j['fontSize'] as num?)?.toDouble() ?? 12.0,
      inventoryFontSize: (j['inventoryFontSize'] as num?)?.toDouble() ?? 11.0,
      inventoryDisplayMode:
          InventoryDisplayMode.values[(j['inventoryDisplayMode'] as int?) ?? 0],
      particlePreset: ParticlePreset.values[(j['particlePreset'] as int?) ?? 0],
      particleGlowEffect:
          GlowEffect.values[(j['particleGlowEffect'] as int?) ?? 0],
      particleLineLinks: j['particleLineLinks'] as bool? ?? false,
      particleBounce: j['particleBounce'] as bool? ?? false,
      glowColorIndex: j['glowColorIndex'] as int? ?? 0,
      glowCustomColor: j['glowCustomColor'] as int? ?? 0,
      glowStyleIndex: j['glowStyleIndex'] as int? ?? -1,
      customDiceType: CustomDiceType.values[(j['customDiceType'] as int?) ?? 0],
      particleSizeScale: (j['particleSizeScale'] as num?)?.toDouble() ?? 1.0,
      particleOpacity: (j['particleOpacity'] as num?)?.toDouble() ?? 0.8,
      particleCount: j['particleCount'] as int? ?? 16,
      dialogueHapticsEnabled: j['dialogueHapticsEnabled'] as bool? ?? true,
      dialogueTextSpeedMs: j['dialogueTextSpeedMs'] as int? ?? 30,
      isGoopianLanguage: j['isGoopianLanguage'] as bool? ?? false,
      spongeActive: j['spongeActive'] as bool? ?? false,
      showEffectsPanel: j['showEffectsPanel'] as bool? ?? true,
      showShrinePanel: j['showShrinePanel'] as bool? ?? true,
      showDashboards: j['showDashboards'] as bool? ?? true,
      periodicGridColumnCount: j['periodicGridColumnCount'] as int? ?? 0,
      particleColorSchema:
          ParticleColorSchema.values[(j['particleColorSchema'] as int?) ?? 0],
      particleSpeed: ParticleSpeed.values[(j['particleSpeed'] as int?) ?? 2],
      shaderEnabled: j['shaderEnabled'] as bool? ?? false,
      shaderPreset: ShaderPreset.values[(j['shaderPreset'] as int?) ?? 0],
    );
  }
}

/// A saved custom theme — captures the full visual state (base theme
/// palette + all VisualPrefs) so it can be restored and displayed in
/// the theme picker alongside the premades.
