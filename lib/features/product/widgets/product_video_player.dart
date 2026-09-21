import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/route_observer.dart';

/// Inline player for a product's video.
///
/// It stays lightweight until the shopper actually wants to watch: the network
/// controller is created and initialised only on the first tap, so opening a
/// product page never downloads the video. Before that it shows the thumbnail
/// (or a dark poster) with a play button; after that a real [VideoPlayer] with
/// a scrubber and a tap-to-toggle play/pause overlay.
class ProductVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String? thumbnailUrl;

  /// Corner rounding of the player. Square in the header gallery, where the
  /// video is just another full-bleed slide next to the photos.
  final BorderRadius borderRadius;

  /// How the poster fills the frame before playback starts. Matches the
  /// gallery's `BoxFit.contain` so swiping from a photo to the video does not
  /// change how the garment is framed.
  final BoxFit posterFit;

  /// When true the player fills its parent instead of sizing itself to the
  /// video's aspect ratio — used inside the fixed-height gallery.
  final bool expand;

  /// False while this slide is scrolled off in the gallery. Playback stops the
  /// moment it goes false, so a video never keeps talking from a slide the
  /// shopper has swiped past.
  final bool isVisible;

  const ProductVideoPlayer({
    super.key,
    required this.videoUrl,
    this.thumbnailUrl,
    this.borderRadius = const BorderRadius.all(Radius.circular(14)),
    this.posterFit = BoxFit.cover,
    this.expand = false,
    this.isVisible = true,
  });

  @override
  State<ProductVideoPlayer> createState() => _ProductVideoPlayerState();
}

class _ProductVideoPlayerState extends State<ProductVideoPlayer>
    with RouteAware, WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _initializing = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pushing another screen leaves the product page alive underneath, so
    // nothing here is disposed and the video would play on unseen. Subscribing
    // to the navigator's observer is the only way to be told about it.
    final route = ModalRoute.of(context);
    if (route is ModalRoute<void>) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didUpdateWidget(ProductVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isVisible && !widget.isVisible) _pause();
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    super.dispose();
  }

  /// Another screen was pushed on top of the product page.
  @override
  void didPushNext() => _pause();

  /// The app was backgrounded, or a call/notification took the foreground.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _pause();
  }

  /// Stops playback without tearing the controller down, so coming back to the
  /// page resumes from where the shopper left off rather than reloading.
  void _pause() {
    final controller = _controller;
    if (controller == null || !controller.value.isPlaying) return;
    controller.pause();
    if (mounted) setState(() {});
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  Future<void> _startPlayback() async {
    // Second and later taps just toggle play/pause on the live controller.
    final existing = _controller;
    if (_initialized && existing != null) {
      setState(() {
        existing.value.isPlaying ? existing.pause() : existing.play();
      });
      return;
    }
    if (_initializing) return;

    setState(() {
      _initializing = true;
      _error = false;
    });
    try {
      final controller =
          VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      _controller = controller;
      await controller.initialize();
      controller.setLooping(false);
      controller.addListener(_onTick);
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _initialized = true;
        _initializing = false;
      });
      // The shopper may have swiped on or left the page while the video was
      // still loading; don't start talking into an empty room.
      if (widget.isVisible) controller.play();
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = true;
          _initializing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final aspect = (_initialized && controller != null)
        ? controller.value.aspectRatio
        : 16 / 9;

    final frame = GestureDetector(
      onTap: _startPlayback,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_initialized && controller != null)
            // Letterboxed so a portrait reel is never cropped, exactly like the
            // contained product photos it sits beside.
            Center(
              child: AspectRatio(
                aspectRatio: aspect <= 0 ? 16 / 9 : aspect,
                child: VideoPlayer(controller),
              ),
            )
          else
            _poster(),
          if (_initialized && controller != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: VideoProgressIndicator(
                controller,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: AppColors.primary,
                  bufferedColor: Colors.white54,
                  backgroundColor: Colors.white24,
                ),
              ),
            ),
          _overlay(controller),
        ],
      ),
    );

    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: widget.expand
          ? SizedBox.expand(child: frame)
          : AspectRatio(
              aspectRatio: aspect <= 0 ? 16 / 9 : aspect,
              child: frame,
            ),
    );
  }

  Widget _poster() {
    final thumb = widget.thumbnailUrl;
    if (thumb != null && thumb.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: thumb,
        fit: widget.posterFit,
        placeholder: (_, __) => Container(color: AppColors.black),
        errorWidget: (_, __, ___) => Container(color: AppColors.black),
      );
    }
    return Container(color: AppColors.black);
  }

  Widget _overlay(VideoPlayerController? controller) {
    if (_error) {
      return Container(
        color: Colors.black54,
        alignment: Alignment.center,
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Video could not be played',
            style: TextStyle(color: Colors.white, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (_initializing) {
      return Container(
        color: Colors.black26,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: Colors.white),
      );
    }
    // Show the big play button before playback starts and whenever the video is
    // paused; hide it while it is playing so it doesn't cover the picture.
    final playing = _initialized && (controller?.value.isPlaying ?? false);
    if (playing) return const SizedBox.shrink();
    return Center(
      child: Container(
        width: 58,
        height: 58,
        decoration: const BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40),
      ),
    );
  }
}
