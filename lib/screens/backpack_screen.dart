import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/gun.dart';
import '../models/item.dart';
import '../models/player.dart';
import '../providers/run_provider.dart';
import '../services/app_theme.dart';
import '../services/goop_talk_engine.dart';
import '../services/haptics.dart';
import '../services/mp_session.dart';
import '../theme/tokens.dart';
import '../utils/asset_paths.dart';
import '../utils/fast_route.dart';
import '../utils/responsive.dart';
import '../widgets/game_icon.dart';
import '../widgets/scale_button.dart';
import 'item_detail_screen.dart';

/// The Backpack — per-player storage for stashed guns/items. Stashed
/// gear still counts toward synergies, passives, DPS and coolness;
/// this screen is purely the "out of sight" view.
///
/// Opened by tapping the Backpack item in the ITEMS grid (or the
/// ITEMS-header shortcut). Tap a stored tile for its full detail
/// view; long-press for TAKE OUT / SEND / DELETE.
class BackpackScreen extends StatelessWidget {
  final PlayerSlot slot;
  const BackpackScreen({super.key, required this.slot});

  Player? _player(RunProvider p) =>
      slot == PlayerSlot.main ? p.runState.main : p.runState.coop;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final player = _player(p);
    final f = AppTheme.flair;
    final sf = Responsive.factor(context);

    if (player == null) {
      return Scaffold(
        backgroundColor: f.scaffold,
        appBar: AppBar(title: const GoopText('Backpack')),
        body: const Center(child: GoopText('No player')),
      );
    }

    final entries = p.backpackEntries(slot);
    final stored = entries.length;
    final free = RunProvider.kBackpackCapacity - stored;
    final guns = entries.where((e) => e.gun != null).toList();
    final items = entries.where((e) => e.item != null).toList();

    return Scaffold(
      backgroundColor: f.scaffold,
      appBar: AppBar(
        backgroundColor: f.card,
        title: GoopText(
          'BACKPACK',
          style: TextStyle(
            fontSize: FontSizes.bodyMedium * sf,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
        actions: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 14),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF8D6E63).withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF8D6E63).withValues(alpha: 0.55),
                ),
              ),
              child: GoopText(
                '$stored/${RunProvider.kBackpackCapacity}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFBCAAA4),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 32),
          children: [
            // ── Owner strip ────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF8D6E63).withValues(alpha: 0.18),
                    border: Border.all(
                      color: const Color(0xFF8D6E63).withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.backpack_rounded,
                    size: 24,
                    color: Color(0xFFBCAAA4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GoopText(
                        (player.character?.name ?? 'Player').toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15 * sf,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const GoopText(
                        'Everything inside still counts',
                        style: TextStyle(fontSize: 10, color: Colors.white38),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── The bag ────────────────────────────────────────────
            _BagPanel(
              freeSlots: free,
              child:
                  stored == 0
                      ? _EmptyBagHint()
                      : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (guns.isNotEmpty) ...[
                            _BagSectionLabel('GUNS', guns.length),
                            _BagWrap(
                              children: [
                                for (final e in guns)
                                  _BagTile(
                                    gun: e.gun!,
                                    onTap: () => _openDetail(context, e.gun),
                                    onLongPress:
                                        () => _promptActions(
                                          context,
                                          e.gun,
                                          null,
                                        ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                          ],
                          if (items.isNotEmpty) ...[
                            _BagSectionLabel('ITEMS', items.length),
                            _BagWrap(
                              children: [
                                for (final e in items)
                                  _BagTile(
                                    item: e.item!,
                                    onTap:
                                        () =>
                                            _openDetail(context, null, e.item),
                                    onLongPress:
                                        () => _promptActions(
                                          context,
                                          null,
                                          e.item,
                                        ),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, Gun? gun, [Item? item]) {
    Navigator.push(
      context,
      fastRoute(ItemDetailScreen(gun: gun, item: item, ownerSlot: slot)),
    );
  }

  /// TAKE OUT / SEND / DELETE pill for a stored entry — same armed-tap
  /// SEND pattern as the open-inventory pill.
  void _promptActions(BuildContext context, Gun? gun, Item? item) {
    final p = context.read<RunProvider>();
    final session = context.read<MpSession>();
    final hasCoop = p.runState.hasCoop;
    final isMpActive = session.phase != MpPhase.idle;
    final canTransfer = hasCoop && (!isMpActive || session.isConnected);
    var armed = false;

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (dlgCtx) {
        return Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.flair.card,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: AppTheme.flair.primary.withValues(alpha: 0.25),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 16,
                ),
              ],
            ),
            child: StatefulBuilder(
              builder: (_, setArmed) {
                final name = gun?.name ?? item?.name ?? '';
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name caption — bag tiles are icon-dense, so the
                    // pill names the entry before you commit an action.
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      // Fixed width so long names ellipsize instead of
                      // stretching the pill past narrow viewports.
                      child: SizedBox(
                        width: 230,
                        child: GoopText(
                          name.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _BagPillBtn(
                          icon: Icons.inventory_2_outlined,
                          color: AppTheme.flair.primary,
                          label: 'TAKE OUT',
                          onTap: () {
                            Navigator.pop(dlgCtx);
                            _takeOut(context, gun, item);
                          },
                        ),
                        if (canTransfer) ...[
                          const SizedBox(width: 12),
                          _BagPillBtn(
                            icon:
                                armed
                                    ? Icons.check_rounded
                                    : Icons.swap_horiz_rounded,
                            color: armed ? Colors.orangeAccent : Colors.white70,
                            label: armed ? 'SURE?' : 'SEND',
                            onTap: () {
                              if (!armed) {
                                setArmed(() => armed = true);
                                return;
                              }
                              Navigator.pop(dlgCtx);
                              _sendToPeer(context, gun, item);
                            },
                          ),
                        ],
                        const SizedBox(width: 12),
                        _BagPillBtn(
                          icon: Icons.delete_outline_rounded,
                          color: Colors.redAccent,
                          label: 'DELETE',
                          onTap: () {
                            Navigator.pop(dlgCtx);
                            _deleteWithUndo(context, gun, item);
                          },
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _takeOut(BuildContext context, Gun? gun, Item? item) {
    final p = context.read<RunProvider>();
    final name = gun?.name ?? item?.name ?? '';
    if (gun != null) {
      p.unstashGun(gun, slot: slot);
    } else {
      p.unstashItem(item!, slot: slot);
    }
    _toast(context, '$name back in inventory');
    Haptics.medium();
  }

  /// Same transfer semantics as the open-inventory pill: MP ships a
  /// gift/request, local co-op moves the item between slots. The
  /// receiver always gets it in their OPEN inventory.
  void _sendToPeer(BuildContext context, Gun? gun, Item? item) {
    final p = context.read<RunProvider>();
    final session = context.read<MpSession>();
    final name = gun?.name ?? item?.name ?? '';
    final peerName = session.peerNickname ?? 'Player 2';
    if (session.isActive && session.isConnected) {
      final isMyInv = session.mySlot == slot;
      if (isMyInv) {
        unawaited(
          session.sendGift(kind: gun != null ? 'gun' : 'item', name: name),
        );
      } else {
        unawaited(
          session.sendRequest(kind: gun != null ? 'gun' : 'item', name: name),
        );
      }
    } else {
      final ok =
          gun != null ? p.transferGun(gun, slot) : p.transferItem(item!, slot);
      if (context.mounted) {
        _toast(
          context,
          ok ? '$name → $peerName' : '$peerName already has $name',
        );
      }
    }
    Haptics.medium();
  }

  /// Delete a stored entry. UNDO re-adds it AND re-stashes it, so the
  /// bag state round-trips cleanly.
  void _deleteWithUndo(BuildContext context, Gun? gun, Item? item) {
    final p = context.read<RunProvider>();
    final name = gun?.name ?? item?.name ?? '';
    final messenger = ScaffoldMessenger.of(context);
    if (gun != null) {
      p.removeGun(gun, slot: slot);
    } else {
      p.removeItem(item!, slot: slot);
    }
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: GoopText(
          'Deleted $name',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            if (gun != null) {
              p.addGun(gun, slot: slot);
              p.stashGun(gun, slot: slot);
            } else {
              p.addItem(item!, slot: slot);
              p.stashItem(item, slot: slot);
            }
          },
        ),
      ),
    );
  }

  void _toast(BuildContext context, String msg) {
    final m = ScaffoldMessenger.maybeOf(context);
    if (m == null) return;
    m.hideCurrentSnackBar();
    m.showSnackBar(
      SnackBar(
        content: GoopText(msg),
        duration: const Duration(milliseconds: 1500),
      ),
    );
  }
}

/// Stitched-leather bag panel — double border + dashed inner frame
/// sells the "pack" without needing bespoke artwork.
class _BagPanel extends StatelessWidget {
  final int freeSlots;
  final Widget child;
  const _BagPanel({required this.freeSlots, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF3A2E28),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF8D6E63).withValues(alpha: 0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFF8D6E63).withValues(alpha: 0.35),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            child,
            if (freeSlots > 0) ...[
              const SizedBox(height: 10),
              _FreeSlotsRow(count: freeSlots),
            ],
          ],
        ),
      ),
    );
  }
}

class _FreeSlotsRow extends StatelessWidget {
  final int count;
  const _FreeSlotsRow({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < count && i < 12; i++) ...[
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
          ),
          if (i < count - 1 && i < 11) const SizedBox(width: 3),
        ],
        const SizedBox(width: 8),
        Flexible(
          child: GoopText(
            '$count free',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: Colors.white38),
          ),
        ),
      ],
    );
  }
}

class _BagSectionLabel extends StatelessWidget {
  final String text;
  final int count;
  const _BagSectionLabel(this.text, this.count);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          GoopText(
            text,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: Color(0xFFBCAAA4),
            ),
          ),
          const SizedBox(width: 6),
          GoopText(
            '$count',
            style: const TextStyle(fontSize: 10, color: Colors.white38),
          ),
        ],
      ),
    );
  }
}

class _BagWrap extends StatelessWidget {
  final List<Widget> children;
  const _BagWrap({required this.children});

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 8, runSpacing: 8, children: children);
  }
}

class _EmptyBagHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 8),
      child: Column(
        children: [
          Icon(
            Icons.backpack_outlined,
            size: 40,
            color: Colors.white.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 10),
          const GoopText(
            "Bag's empty",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          const GoopText(
            'Long-press gear in your inventory and hit STASH',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.white38),
          ),
        ],
      ),
    );
  }
}

/// One stored entry — GameIcon + name, ~64px cell. Tap opens the full
/// detail view; long-press opens the action pill.
class _BagTile extends StatelessWidget {
  final Gun? gun;
  final Item? item;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  const _BagTile({
    this.gun,
    this.item,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final name = gun?.name ?? item?.name ?? '';
    final quality = gun?.quality ?? item?.quality ?? '';
    final path =
        gun != null
            ? (gun!.icon.isNotEmpty ? gun!.icon : localGunIcon(gun!.name))
            : (item!.icon.isNotEmpty ? item!.icon : localItemIcon(item!.name));
    return Tooltip(
      message: name,
      child: ScaleButton(
        onTap: onTap,
        onLongPress: onLongPress,
        child: SizedBox(
          width: 68,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GameIcon(
                assetPath: path,
                fallback:
                    gun != null
                        ? Icons.gps_fixed
                        : item!.name == RunProvider.kBackpackItemName
                        ? Icons.backpack_outlined
                        : Icons.inventory_2_outlined,
                quality: quality,
                size: 52,
                semanticLabel: '$name, quality $quality',
              ),
              const SizedBox(height: 3),
              GoopText(
                name.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Labeled circular pill button for the in-bag action sheet — matches
/// the open-inventory pill's look (icon + caption).
class _BagPillBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  const _BagPillBtn({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleButton(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: 0.65),
                width: 1.6,
              ),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 4),
          GoopText(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: color.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}
