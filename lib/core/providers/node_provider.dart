import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../shared/constants.dart';
import '../models/storage_node.dart';

class NodeNotifier extends StateNotifier<List<StorageNode>> {
  NodeNotifier() : super([]) {
    _loadNodes();
  }

  Future<void> _loadNodes() async {
    try {
      final box = Hive.box(AppConstants.nodesBox);
      final nodes = <StorageNode>[];
      for (final key in box.keys) {
        final data = box.get(key);
        if (data != null) {
          nodes.add(StorageNode.fromJson(data));
        }
      }
      nodes.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      state = nodes;
    } catch (e) {
      debugPrint('⚠️ 加载节点失败: $e');
      state = [];
    }
  }

  Future<void> addNode(StorageNode node) async {
    try {
      final box = Hive.box(AppConstants.nodesBox);
      await box.put(node.id, node.toJson());
      final updated = [...state, node]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      state = updated;
    } catch (e) {
      debugPrint('⚠️ 添加节点失败: $e');
    }
  }

  Future<void> removeNode(String id) async {
    final box = Hive.box(AppConstants.nodesBox);
    await box.delete(id);
    state = state.where((n) => n.id != id).toList();
  }

  Future<void> updateNode(StorageNode node) async {
    final box = Hive.box(AppConstants.nodesBox);
    await box.put(node.id, node.toJson());
    state = state.map((n) => n.id == node.id ? node : n).toList();
  }

  Future<void> togglePrivate(String id, bool isPrivate) async {
    final node = state.firstWhere((n) => n.id == id);
    final updated = node.copyWith(
      category: isPrivate ? NodeCategory.private : NodeCategory.normal,
    );
    await updateNode(updated);
  }

  List<StorageNode> getVisibleNodes(bool isUnlocked) {
    if (isUnlocked) return state;
    return state.where((n) => !n.isPrivate).toList();
  }
}

final nodeProvider = StateNotifierProvider<NodeNotifier, List<StorageNode>>((ref) {
  return NodeNotifier();
});

class FavoriteNotifier extends StateNotifier<List<FavoriteNode>> {
  FavoriteNotifier() : super([]) {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final box = Hive.box(AppConstants.favoritesBox);
      final favs = <FavoriteNode>[];
      for (final key in box.keys) {
        final data = box.get(key);
        if (data != null) {
          favs.add(FavoriteNode.fromJson(data));
        }
      }
      favs.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      state = favs;
    } catch (e) {
      debugPrint('⚠️ 加载收藏失败: $e');
      state = [];
    }
  }

  Future<void> addFavorite(FavoriteNode fav) async {
    final box = Hive.box(AppConstants.favoritesBox);
    await box.put(fav.id, fav.toJson());
    final updated = [...state, fav]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    state = updated;
  }

  Future<void> removeFavorite(String id) async {
    final box = Hive.box(AppConstants.favoritesBox);
    await box.delete(id);
    state = state.where((f) => f.id != id).toList();
  }

  Future<void> reorderFavorites(int oldIndex, int newIndex) async {
    final updated = [...state];
    if (oldIndex < newIndex) newIndex -= 1;
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);
    for (var i = 0; i < updated.length; i++) {
      updated[i] = updated[i].copyWith(sortOrder: i);
    }
    final box = Hive.box(AppConstants.favoritesBox);
    for (final fav in updated) {
      await box.put(fav.id, fav.toJson());
    }
    state = updated;
  }
}

final favoriteProvider = StateNotifierProvider<FavoriteNotifier, List<FavoriteNode>>((ref) {
  return FavoriteNotifier();
});
