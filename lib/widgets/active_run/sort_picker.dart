import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/run_provider.dart';
import '../../models/gun.dart';
import '../../models/item.dart';
import '../../services/goop_talk_engine.dart';

enum GunSort { pickup, quality, name, dps }

enum ItemSort { pickup, quality, name, type }

/// How the per-player inventory is rendered. `grid` keeps the dense
/// periodic-tile layout we've had since the start; `list` switches to a
/// one-per-row compact list with a portrait icon, name, quality badge,
/// elemental indicators inline, and the same corner stat (DPS for guns,
/// recharge for items).
enum InvView { grid, list }

extension GunSortLabel on GunSort {
  String get label {
    switch (this) {
      case GunSort.pickup:
        return 'Pickup order';
      case GunSort.quality:
        return 'Quality';
      case GunSort.name:
        return 'Name (A→Z)';
      case GunSort.dps:
        return 'DPS (high→low)';
    }
  }

  IconData get icon {
    switch (this) {
      case GunSort.pickup:
        return Icons.history;
      case GunSort.quality:
        return Icons.workspace_premium;
      case GunSort.name:
        return Icons.sort_by_alpha;
      case GunSort.dps:
        return Icons.flash_on;
    }
  }
}

extension ItemSortLabel on ItemSort {
  String get label {
    switch (this) {
      case ItemSort.pickup:
        return 'Pickup order';
      case ItemSort.quality:
        return 'Quality';
      case ItemSort.name:
        return 'Name (A→Z)';
      case ItemSort.type:
        return 'Type';
    }
  }

  IconData get icon {
    switch (this) {
      case ItemSort.pickup:
        return Icons.history;
      case ItemSort.quality:
        return Icons.workspace_premium;
      case ItemSort.name:
        return Icons.sort_by_alpha;
      case ItemSort.type:
        return Icons.category_outlined;
    }
  }
}

/// Convert quality letter ('S' / '1S' / 'A' / 'B' / 'C' / 'D' / 'N' / '')
/// into a sortable rank — lower = appears first.
int _qualityRank(String q) {
  switch (q.toUpperCase()) {
    case 'S':
    case '1S':
      return 0;
    case 'A':
      return 1;
    case 'B':
      return 2;
    case 'C':
      return 3;
    case 'D':
      return 4;
    case 'N':
      return 5;
    default:
      return 6;
  }
}

/// Returns a sorted view of [src] according to [mode].
/// `GunSort.pickup` short-circuits and returns [src] unchanged — the
/// player's pickup order is the natural list order, so we avoid both
/// the allocation and the sort cost on every rebuild. Callers must not
/// mutate the returned list (they don't).
List<Gun> sortGuns(List<Gun> src, GunSort mode) {
  if (mode == GunSort.pickup) return src;
  final out = List.of(src);
  switch (mode) {
    case GunSort.quality:
      out.sort((a, b) {
        final r = _qualityRank(a.quality).compareTo(_qualityRank(b.quality));
        return r != 0 ? r : a.name.compareTo(b.name);
      });
      break;
    case GunSort.name:
      out.sort((a, b) =>
          a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      break;
    case GunSort.dps:
      out.sort((a, b) => b.dpsValue.compareTo(a.dpsValue));
      break;
    case GunSort.pickup:
      break;
  }
  return out;
}

List<Item> sortItems(List<Item> src, ItemSort mode) {
  if (mode == ItemSort.pickup) return src;
  final out = List.of(src);
  int typeRank(Item it) {
    if (it.isActive) return 0;
    if (it.isPassive) return 1;
    if (it.isCompanion) return 2;
    return 3;
  }

  switch (mode) {
    case ItemSort.quality:
      out.sort((a, b) {
        final r = _qualityRank(a.quality).compareTo(_qualityRank(b.quality));
        return r != 0 ? r : a.name.compareTo(b.name);
      });
      break;
    case ItemSort.name:
      out.sort((a, b) =>
          a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      break;
    case ItemSort.type:
      out.sort((a, b) {
        final r = typeRank(a).compareTo(typeRank(b));
        return r != 0 ? r : a.name.compareTo(b.name);
      });
      break;
    case ItemSort.pickup:
      break;
  }
  return out;
}

/// Bottom-sheet picker used by the inventory section headers. Generic
/// over any enum [T] so the same sheet handles guns and items.
class SortPickerSheet<T> extends StatelessWidget {
  final String title;
  final IconData titleIcon;
  final T current;
  final List<T> options;
  final String Function(T) labelOf;
  final IconData Function(T) iconOf;
  final ValueChanged<T> onPick;

  const SortPickerSheet({
    super.key,
    required this.title,
    required this.titleIcon,
    required this.current,
    required this.options,
    required this.labelOf,
    required this.iconOf,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
              child: Row(
                children: [
                  Icon(titleIcon, size: 18, color: Colors.amber),
                  const SizedBox(width: 8),
                  GoopText(
                    'Sort $title by',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
            for (final opt in options)
              ListTile(
                dense: true,
                leading: Icon(
                  iconOf(opt),
                  color: opt == current ? Colors.amber : Colors.white70,
                  size: 20,
                ),
                title: GoopText(
                  labelOf(opt),
                  style: TextStyle(
                    fontWeight:
                        opt == current ? FontWeight.w700 : FontWeight.w500,
                    color: opt == current ? Colors.amber : Colors.white,
                  ),
                ),
                trailing: opt == current
                    ? const Icon(Icons.check, color: Colors.amber, size: 18)
                    : null,
                onTap: () {
                  onPick(opt);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// Quick-actions sheet for solo-mode long-press on an inventory tile.
/// Three large tap targets — Open, Favourite, Remove — plus a passive
/// header that shows what tile we're acting on.
class TileActionsSheet extends StatelessWidget {
  final Gun? gun;
  final Item? item;
  final VoidCallback onOpen;
  final VoidCallback onToggleFavourite;
  final VoidCallback onRemove;
  final VoidCallback? onTransfer;
  final String? transferLabel;

  const TileActionsSheet({super.key, 
    this.gun,
    this.item,
    required this.onOpen,
    required this.onToggleFavourite,
    required this.onRemove,
    this.onTransfer,
    this.transferLabel,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final name = gun?.name ?? item!.name;
    final isFav = p.isFavourite(name);
    final subtitle = gun != null ? gun!.type : item!.type;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Row(
                children: [
                  Icon(
                    gun != null
                        ? Icons.gps_fixed
                        : Icons.inventory_2_outlined,
                    color: Colors.white70,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GoopText(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                        if (subtitle.isNotEmpty)
                          GoopText(
                            subtitle,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (onTransfer != null && transferLabel != null)
              ListTile(
                leading: const Icon(Icons.swap_horiz, color: Colors.amberAccent),
                title: GoopText(
                  transferLabel!,
                  style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold),
                ),
                onTap: onTransfer,
              ),
            ListTile(
              leading: const Icon(Icons.open_in_new,
                  color: Colors.lightBlueAccent),
              title: const GoopText('Open detail'),
              onTap: onOpen,
            ),
            ListTile(
              leading: Icon(
                isFav ? Icons.favorite : Icons.favorite_border,
                color: isFav ? Colors.pinkAccent : Colors.white70,
              ),
              title: GoopText(
                isFav ? 'Unfavourite' : 'Favourite',
              ),
              onTap: onToggleFavourite,
            ),
            ListTile(
              leading:
                  const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const GoopText(
                'Remove from run',
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}