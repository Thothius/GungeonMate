import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/run_provider.dart';
import '../../models/gun.dart';
import '../../models/item.dart';
import '../../models/player.dart';
import '../../services/app_theme.dart';
import '../../services/multiplayer_session.dart';
import '../../services/goop_talk_engine.dart';
import '../../utils/fast_route.dart';
import '../../screens/item_detail_screen.dart';
import 'sort_picker.dart' show TileActionsSheet;

// =============================================================================
// Shared helpers for the active-run display modes (Codex / Compact / Signature).
//
// Extracted verbatim from `PlayerPageState` so each mode widget can drive the
// same MP/transfer/sort/undo flows without triplicating ~300 lines. Every
// function takes the owning [PlayerSlot] explicitly — modes are stateless
// w.r.t. slot identity.
// =============================================================================

/// Effective DPS for a gun, accounting for Gunderfury's dynamic scaling.
double effectiveDps(Gun g, RunProvider p) {
  if (g.name.toLowerCase() == 'gunderfury') {
    return g.getDynamicDps(gunderLevel: p.gunderfuryLevel);
  }
  return g.dpsValue;
}

/// (name, dps) of the highest-DPS gun in [player]'s loadout, or
/// `('', 0.0)` when empty. Used by every mode to surface the "hero" gun.
({String name, double dps}) topDpsInfo(Player player, RunProvider p) {
  if (player.guns.isEmpty) return (name: '', dps: 0.0);
  var top = player.guns.first;
  var topVal = effectiveDps(top, p);
  for (final g in player.guns.skip(1)) {
    final v = effectiveDps(g, p);
    if (v > topVal) {
      top = g;
      topVal = v;
    }
  }
  return (name: top.name, dps: topVal);
}

/// Synergy glow color map (lowercased name → Color) for the active run.
/// Thin wrapper so mode widgets don't each reach into the provider.
Map<String, Color> synergyGlowColors(RunProvider p) =>
    p.activeSynergyGlowColors;

/// Inline snackbar toast — mirrors `PlayerPageState._toast`.
void toast(BuildContext c, String msg) {
  final m = ScaffoldMessenger.maybeOf(c);
  if (m == null) return;
  m.hideCurrentSnackBar();
  m.showSnackBar(SnackBar(
    content: GoopText(msg),
    duration: const Duration(milliseconds: 1500),
  ));
}

/// Remove [g] from the loadout with a 5-second UNDO snackbar. Captures
/// [slot] so UNDO stays valid if the user navigates away before timeout.
void removeGunWithUndo(BuildContext c, Gun g, PlayerSlot slot) {
  final p = c.read<RunProvider>();
  p.removeGun(g, slot: slot);
  final messenger = ScaffoldMessenger.of(c);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(
    content: GoopText('Removed ${g.name}',
        maxLines: 1, overflow: TextOverflow.ellipsis),
    duration: const Duration(seconds: 5),
    action: SnackBarAction(
      label: 'UNDO',
      onPressed: () => p.addGun(g, slot: slot),
    ),
  ));
}

/// Remove [it] from the loadout with a 5-second UNDO snackbar.
void removeItemWithUndo(BuildContext c, Item it, PlayerSlot slot) {
  final p = c.read<RunProvider>();
  p.removeItem(it, slot: slot);
  final messenger = ScaffoldMessenger.of(c);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(
    content: GoopText('Removed ${it.name}',
        maxLines: 1, overflow: TextOverflow.ellipsis),
    duration: const Duration(seconds: 5),
    action: SnackBarAction(
      label: 'UNDO',
      onPressed: () => p.addItem(it, slot: slot),
    ),
  ));
}

/// MP-aware transfer prompt for a gun. Decides send-vs-request based on
/// whether [slot] is the local user's inventory in an active MP session.
void promptTransferGun(BuildContext c, Gun g, PlayerSlot slot) {
  final p = c.read<RunProvider>();
  final session = c.read<MultiplayerSession>();
  final mpActive = session.isActive;
  final isMyInv =
      !mpActive || session.isSimulated || session.mySlot == slot;
  final peerName = mpActive
      ? (session.peerNickname ?? 'Peer')
      : (slot == PlayerSlot.main
          ? (p.runState.coop?.character?.name ?? 'Player 2')
          : p.runState.main.character!.name);

  final title = mpActive && !isMyInv ? 'Request ${g.name}?' : 'Transfer ${g.name}?';
  final subtitle =
      mpActive && !isMyInv ? 'Ask $peerName to send it to you' : 'Send to $peerName';
  final icon = mpActive && !isMyInv ? Icons.front_hand : Icons.swap_horiz;

  showModalBottomSheet(
    context: c,
    builder: (bc) => TransferSheet(
      title: title,
      subtitle: subtitle,
      icon: icon,
      onConfirm: () async {
        Navigator.pop(bc);
        if (mpActive) {
          if (isMyInv) {
            await session.sendGift(kind: 'gun', name: g.name);
            if (c.mounted) toast(c, '${g.name} → $peerName');
          } else {
            final reqId = await session.sendRequest(kind: 'gun', name: g.name);
            if (!c.mounted) return;
            toast(c, reqId != null
                ? 'Asked $peerName for ${g.name}…'
                : 'Could not send request — check connection.');
          }
        } else {
          final ok = p.transferGun(g, slot);
          if (c.mounted) {
            toast(c, ok ? '${g.name} → $peerName' : '$peerName already has ${g.name}');
          }
        }
      },
    ),
  );
}

/// MP-aware transfer prompt for an item. Mirrors [promptTransferGun].
void promptTransferItem(BuildContext c, Item it, PlayerSlot slot) {
  final p = c.read<RunProvider>();
  final session = c.read<MultiplayerSession>();
  final mpActive = session.isActive;
  final isMyInv =
      !mpActive || session.isSimulated || session.mySlot == slot;
  final peerName = mpActive
      ? (session.peerNickname ?? 'Peer')
      : (slot == PlayerSlot.main
          ? (p.runState.coop?.character?.name ?? 'Player 2')
          : p.runState.main.character!.name);

  final title = mpActive && !isMyInv ? 'Request ${it.name}?' : 'Transfer ${it.name}?';
  final subtitle =
      mpActive && !isMyInv ? 'Ask $peerName to send it to you' : 'Send to $peerName';
  final icon = mpActive && !isMyInv ? Icons.front_hand : Icons.swap_horiz;

  showModalBottomSheet(
    context: c,
    builder: (bc) => TransferSheet(
      title: title,
      subtitle: subtitle,
      icon: icon,
      onConfirm: () async {
        Navigator.pop(bc);
        if (mpActive) {
          if (isMyInv) {
            await session.sendGift(kind: 'item', name: it.name);
            if (c.mounted) toast(c, '${it.name} → $peerName');
          } else {
            final reqId = await session.sendRequest(kind: 'item', name: it.name);
            if (!c.mounted) return;
            toast(c, reqId != null
                ? 'Asked $peerName for ${it.name}…'
                : 'Could not send request — check connection.');
          }
        } else {
          final ok = p.transferItem(it, slot);
          if (c.mounted) {
            toast(c, ok ? '${it.name} → $peerName' : '$peerName already has ${it.name}');
          }
        }
      },
    ),
  );
}

/// Solo-mode quick-actions sheet shown on long-press. Surfaces
/// Open / Favourite / Remove (+ Transfer when coop/MP is active).
/// Exactly one of [gun]/[item] must be non-null.
void promptTileActions(
  BuildContext c, {
  required PlayerSlot slot,
  Gun? gun,
  Item? item,
}) {
  assert((gun == null) != (item == null), 'Pass exactly one of gun/item');
  final p = c.read<RunProvider>();
  final mpSession = c.read<MultiplayerSession>();
  final hasCoop = p.runState.hasCoop;
  final isMpActive = mpSession.status != MpStatus.idle;
  final canTransfer = hasCoop && (!isMpActive || mpSession.isConnected);

  showModalBottomSheet<void>(
    context: c,
    backgroundColor: const Color(0xFF1E1E1E),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (sheetCtx) {
      VoidCallback? onTransfer;
      String? transferLabel;
      if (canTransfer) {
        final isMyInv =
            !isMpActive || mpSession.isSimulated || mpSession.mySlot == slot;
        final peerName =
            isMpActive ? (mpSession.peerNickname ?? 'Peer') : 'Player 2';
        transferLabel =
            isMyInv ? 'Transfer to $peerName' : 'Request from $peerName';
        if (gun != null) {
          onTransfer = () {
            Navigator.pop(sheetCtx);
            promptTransferGun(c, gun, slot);
          };
        } else if (item != null) {
          onTransfer = () {
            Navigator.pop(sheetCtx);
            promptTransferItem(c, item, slot);
          };
        }
      }

      return TileActionsSheet(
        gun: gun,
        item: item,
        onTransfer: onTransfer,
        transferLabel: transferLabel,
        onOpen: () {
          Navigator.pop(sheetCtx);
          Navigator.push(
            c,
            fastRoute(ItemDetailScreen(gun: gun, item: item, ownerSlot: slot)),
          );
        },
        onToggleFavourite: () {
          final p = c.read<RunProvider>();
          final name = gun?.name ?? item!.name;
          final nowFav = p.toggleFavourite(name);
          Navigator.pop(sheetCtx);
          ScaffoldMessenger.of(c).showSnackBar(SnackBar(
            content: GoopText(
                nowFav ? '$name added to favourites' : '$name unfavourited'),
            duration: const Duration(milliseconds: 1400),
          ));
        },
        onRemove: () {
          Navigator.pop(sheetCtx);
          if (gun != null) {
            removeGunWithUndo(c, gun, slot);
          } else {
            removeItemWithUndo(c, item!, slot);
          }
        },
      );
    },
  );
}

/// Grid delegate for the inventory tile grid. Mirrors
/// `PlayerPageState._tileGrid` — same breakpoints, same aspect ratios.
SliverGridDelegate tileGridDelegate(BuildContext context) {
  final w = MediaQuery.of(context).size.width;
  final displayMode = VisualPrefs.notifier.value.inventoryDisplayMode;

  int cross;
  double ratio;

  switch (displayMode) {
    case InventoryDisplayMode.classicPeriodic:
      final savedColCount = VisualPrefs.notifier.value.periodicGridColumnCount;
      cross = (savedColCount > 0) ? savedColCount : (w < 360 ? 3 : w < 600 ? 4 : 6);
      ratio = 0.75; // BUG-035: bumped from 0.80 to fit type subtitle + RANGE
      break;
    case InventoryDisplayMode.tacticalStats:
      cross = w < 500 ? 2 : w < 850 ? 3 : 4;
      ratio = 0.95;
      break;
  }

  return SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: cross,
    mainAxisSpacing: 8,
    crossAxisSpacing: 8,
    childAspectRatio: ratio,
  );
}

// =============================================================================
// TransferSheet — relocated from player_page.dart so mode_helpers (and thus
// all 3 mode widgets) can reference it without a circular import. Verbatim
// copy; player_page.dart re-exports it for backward compatibility.
// =============================================================================

class TransferSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onConfirm;
  const TransferSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: Colors.amber),
            const SizedBox(height: 10),
            GoopText(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            GoopText(subtitle,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const GoopText('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.check),
                    label: const GoopText('Transfer'),
                    onPressed: onConfirm,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
