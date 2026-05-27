import 'package:flutter/foundation.dart';
import '../models/group.dart';
import '../models/local_track.dart';
import 'database_service.dart';

class GroupProvider extends ChangeNotifier {
  List<Group> _groups = [];
  final Map<int, Set<String>> _groupTrackIds = {};

  List<Group> get groups => List.unmodifiable(_groups);

  Set<String> getTrackIds(int groupId) => _groupTrackIds[groupId] ?? {};

  Future<void> load() async {
    try {
      _groups = await DatabaseService.getGroups();
      _groupTrackIds.clear();
      await Future.wait(_groups.map((g) async {
        final ids = await DatabaseService.getGroupTrackIds(g.id);
        _groupTrackIds[g.id] = ids;
      }));
    } catch (_) {
      _groups = [];
      _groupTrackIds.clear();
    }
    notifyListeners();
  }

  Future<void> create(String name) async {
    try {
      await DatabaseService.createGroup(name);
      await load();
    } catch (e) {
      debugPrint('GroupProvider.create failed: $e');
      rethrow;
    }
  }

  Future<void> rename(int id, String name) async {
    await DatabaseService.renameGroup(id, name);
    await load();
  }

  Future<void> delete(int id) async {
    await DatabaseService.deleteGroup(id);
    await load();
  }

  Future<void> addTrack(int groupId, LocalTrack track) async {
    await DatabaseService.addTrackToGroup(groupId, track);
    await load();
  }

  Future<void> removeTrack(int groupId, String trackId) async {
    await DatabaseService.removeTrackFromGroup(groupId, trackId);
    await load();
  }

  Future<List<LocalTrack>> getTracks(int groupId) async {
    return DatabaseService.getGroupTracks(groupId);
  }
}
