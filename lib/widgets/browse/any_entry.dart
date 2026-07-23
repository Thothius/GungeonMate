import '../../models/gun.dart';
import '../../models/item.dart';

class AnyEntry {
  final Gun? gun;
  final Item? item;
  AnyEntry.gun(this.gun) : item = null;
  AnyEntry.item(this.item) : gun = null;

  String get name => gun?.name ?? item!.name;
  String get quality => gun?.quality ?? item!.quality;
}
