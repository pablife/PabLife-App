import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../shared/mixins/loader_manager.dart';
import '../../shared/utils/app_snackbar.dart';
import '../../infra/repositories/mentoria_repository.dart';
import '../../infra/models/mentoria_model.dart';
import '../../infra/models/mentoria_module_model.dart';
import '../../infra/models/mentoria_video_model.dart';
import '../../infra/services/youtube_service.dart';

class MentoriaViewController extends GetxController with LoaderManagerMixin {
  final MentoriaRepository _repository;
  final YoutubeService _youtubeService = YoutubeService.instance;

  MentoriaViewController(this._repository);

  MentoriaModel? mentoria;
  List<MentoriaModuleModel> modules = [];
  List<MentoriaVideoModel> videos = [];
  List<MentoriaVideoModel> _allVideos = [];
  String? selectedModuleId;
  String? expandedVideoId;
  bool isSaved = false;
  void Function(String, bool)? onFavoriteChanged;
  Timer? _favoriteTimer;
  bool? _pendingFavoriteState;
  final Duration _favoriteDebounceDuration = const Duration(milliseconds: 600);
  final Set<String> _loadingVideos = {};

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      mentoria = args['mentoria'] as MentoriaModel?;
      onFavoriteChanged =
          args['onFavoriteChanged'] as void Function(String, bool)?;
      isSaved = mentoria?.isSaved ?? false;
    }
  }

  @override
  void onReady() {
    super.onReady();
    if (mentoria != null) {
      _loadMentoriaData();
    }
  }

  Future<void> _loadMentoriaData() async {
    changeLoading(true);
    await _loadModules();
    await _loadVideos();
    await _loadLastWatched();
    _applyModuleFilter();
    changeLoading(false);
  }

  Future<void> _loadModules() async {
    final response = await _repository.getModules(mentoria!.id);
    if (!response.success) {
      AppSnackbar.to.show(response.message);
    } else {
      modules = response.data ?? [];
      if (modules.isNotEmpty && selectedModuleId == null) {
        selectedModuleId = modules.first.id;
      }
      update();
    }
  }

  Future<void> _loadVideos() async {
    final response = await _repository.getVideos(mentoria!.id);
    if (!response.success) {
      AppSnackbar.to.show(response.message);
    } else {
      _allVideos = response.data ?? [];
    }
  }

  bool isVideoLoading(String videoId) {
    return _loadingVideos.contains(videoId);
  }

  Future<void> _loadLastWatched() async {
    final response = await _repository.getLastWatchedVideo(mentoria!.id);
    if (response.success && response.data != null) {
      final lastWatched = _findVideoById(response.data!);
      if (lastWatched != null) {
        selectedModuleId = lastWatched.moduleId;
        expandedVideoId = lastWatched.id;

        final url = lastWatched.videoUrl.toLowerCase();
        final isYoutubeVideo =
            url.contains('youtube.com') || url.contains('youtu.be');

        if (isYoutubeVideo &&
            (lastWatched.thumbnailUrl?.isEmpty != false ||
                lastWatched.durationSeconds == 0)) {
          await _enrichVideoWithYoutubeInfo(lastWatched.id);
        }
      }
    }

    if (selectedModuleId == null && modules.isNotEmpty) {
      selectedModuleId = modules.first.id;
    }
  }

  Future<void> toggleVideoExpansion(String videoId) async {
    if (expandedVideoId == videoId) {
      expandedVideoId = null;
      update();
      return;
    }

    expandedVideoId = videoId;
    update();

    final video = _findVideoById(videoId);
    if (video == null) return;

    final url = video.videoUrl.toLowerCase();
    final isYoutubeVideo =
        url.contains('youtube.com') || url.contains('youtu.be');

    if (isYoutubeVideo &&
        (video.thumbnailUrl?.isEmpty != false || video.durationSeconds == 0)) {
      await _enrichVideoWithYoutubeInfo(videoId);
    }
  }

  Future<void> _enrichVideoWithYoutubeInfo(String videoId) async {
    final video = _findVideoById(videoId);
    if (video == null) return;

    if (_loadingVideos.contains(videoId)) return;

    _loadingVideos.add(videoId);
    update();

    try {
      debugPrint(
        '[MentoriaViewController] Buscando info do YouTube para: ${video.videoUrl}',
      );
      final youtubeInfo = await _youtubeService.getVideoInfo(video.videoUrl);

      if (youtubeInfo != null) {
        final index = _allVideos.indexWhere((v) => v.id == videoId);
        if (index != -1) {
          final updatedVideo = _allVideos[index].copyWith(
            title: _allVideos[index].title.isEmpty
                ? youtubeInfo.title
                : _allVideos[index].title,
            thumbnailUrl: _allVideos[index].thumbnailUrl?.isEmpty != false
                ? youtubeInfo.thumbnailUrl
                : _allVideos[index].thumbnailUrl,
            durationSeconds: _allVideos[index].durationSeconds == 0
                ? youtubeInfo.durationSeconds
                : _allVideos[index].durationSeconds,
          );

          debugPrint(
            '[MentoriaViewController] Thumbnail atualizada: ${updatedVideo.thumbnailUrl}',
          );
          debugPrint(
            '[MentoriaViewController] resolvedThumbnailUrl: ${updatedVideo.resolvedThumbnailUrl}',
          );

          _allVideos[index] = updatedVideo;
          _applyModuleFilter();
          debugPrint(
            '[MentoriaViewController] Vídeo na lista videos: ${videos.firstWhere((v) => v.id == videoId, orElse: () => _allVideos[index]).resolvedThumbnailUrl}',
          );
        }
      }
    } catch (e) {
      debugPrint('[MentoriaViewController] Erro ao enriquecer vídeo: $e');
    } finally {
      _loadingVideos.remove(videoId);
      update();
    }
  }

  void selectModule(String moduleId) {
    if (selectedModuleId == moduleId) return;

    selectedModuleId = moduleId;
    expandedVideoId = null;
    _applyModuleFilter();
  }

  Future<void> toggleSave() async {
    if (mentoria == null) return;

    final desired = !isSaved;
    _setLocalFavorite(desired);
    _pendingFavoriteState = desired;

    _favoriteTimer?.cancel();
    _favoriteTimer = Timer(_favoriteDebounceDuration, () async {
      final targetState = _pendingFavoriteState;
      if (targetState == null) return;

      final response = await _repository.setFavoriteStatus(
        mentoria!.id,
        targetState,
      );

      if (!response.success) {
        AppSnackbar.to.show(response.message);
        _setLocalFavorite(!targetState);
      } else {
        final finalState = response.data ?? targetState;
        _setLocalFavorite(finalState);
      }

      _pendingFavoriteState = null;
    });
  }

  void playVideo(MentoriaVideoModel video) {
    Get.toNamed(
      '/mentoria/youtube-player',
      arguments: {'videoUrl': video.videoUrl, 'videoTitle': video.title},
    );
  }

  void _applyModuleFilter() {
    if (_allVideos.isEmpty) {
      videos = [];
    } else if (selectedModuleId == null) {
      videos = List<MentoriaVideoModel>.from(_allVideos);
    } else {
      videos = _allVideos
          .where((video) => video.moduleId == selectedModuleId)
          .toList();
    }

    final hasExpanded = videos.any((video) => video.id == expandedVideoId);
    if (!hasExpanded) {
      expandedVideoId = videos.isNotEmpty ? videos.first.id : null;
    }

    update();
  }

  MentoriaVideoModel? _findVideoById(String videoId) {
    for (final video in _allVideos) {
      if (video.id == videoId) {
        return video;
      }
    }
    return null;
  }

  void _setLocalFavorite(bool value) {
    isSaved = value;
    if (mentoria != null) {
      mentoria = mentoria!.copyWith(isSaved: value);
      onFavoriteChanged?.call(mentoria!.id, value);
    }
    update();
  }

  @override
  void onClose() {
    _favoriteTimer?.cancel();
    super.onClose();
  }
}
