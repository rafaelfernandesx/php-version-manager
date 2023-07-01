import 'state_manager.dart';

class PhpVersion {
  String name;
  String downloadLink;
  String releaseDate;
  String size;
  StateManager stateManager = StateManager();
  bool downloaded;
  bool isGlobal;
  PhpVersion({
    required this.name,
    required this.downloadLink,
    required this.releaseDate,
    required this.size,
    this.downloaded = false,
    this.isGlobal = false,
  });
}
