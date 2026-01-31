import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../utils/route_observer.dart';

/// 粒子模型
class Particle {
  double x;
  double y;
  double size;
  double speedX;
  double speedY;
  double opacity;
  Color color;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speedX,
    required this.speedY,
    required this.opacity,
    required this.color,
  });
}

/// 粒子动画背景组件
class ParticleBackground extends StatefulWidget {
  final bool enabled;
  final Widget child;
  final Color? particleColor;

  const ParticleBackground({
    super.key,
    this.enabled = true,
    required this.child,
    this.particleColor,
  });

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];
  final Random _random = Random();
  Size _size = Size.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _controller.addListener(_updateParticles);
  }

  @override
  void dispose() {
    _controller.removeListener(_updateParticles);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    
    // 如果未启用，直接返回 child
    if (!settings.particleEnabled) {
      return widget.child;
    }

    return ValueListenableBuilder<String?>(
      valueListenable: globalRouteObserver.currentRouteNameNotifier,
      builder: (context, currentRouteName, child) {
        // 如果 global 为 false，且当前路由是 editor，则隐藏粒子
        // 注意：settings.particleGlobal 为 true 表示全局显示
        // 为 false 表示 "仅非编辑区显示" (即 editor 不显示)
        final isEditor = currentRouteName == 'editor';
        final shouldShow = settings.particleGlobal || !isEditor;

        if (!shouldShow) {
          return widget.child;
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final newSize = Size(constraints.maxWidth, constraints.maxHeight);
            if (_size != newSize) {
              _size = newSize;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _initParticles();
              });
            }

            return Stack(
              children: [
                widget.child,
                // 使用 RepaintBoundary 隔离粒子动画的重绘区域，
                // 避免粒子动画导致整个 Widget 树重绘
                Positioned.fill(
                  child: RepaintBoundary(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: ParticlePainter(particles: _particles),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
      child: widget.child,
    );
  }

  void _initParticles() {
    _particles.clear();
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    
    // 根据类型调整粒子数量
    int particleCount;
    switch (settings.particleType) {
      case 'rain':
        particleCount = (_size.width * _size.height / 5000).clamp(50, 200).toInt();
        break;
      case 'firefly':
        particleCount = (_size.width * _size.height / 30000).clamp(10, 40).toInt();
        break;
      default:
        particleCount = (_size.width * _size.height / 20000).clamp(20, 60).toInt();
    }

    for (var i = 0; i < particleCount; i++) {
        _particles.add(_createParticle());
    }
  }

  Particle _createParticle({double? x, double? y}) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final type = settings.particleType;
    
    late Color color;
    late double size;
    late double speedX;
    late double speedY;
    late double opacity;

    final random = _random;

    switch (type) {
      case 'sakura':
        color = Colors.pinkAccent.withAlpha(150);
        size = random.nextDouble() * 4 + 2;
        speedX = (random.nextDouble() - 0.5) * 1.5;
        speedY = random.nextDouble() * 1.5 + 0.5;
        opacity = random.nextDouble() * 0.5 + 0.3;
        break;
      case 'rain':
        color = Colors.blueAccent.withAlpha(150);
        size = random.nextDouble() * 1 + 1; // 细长雨滴通常用线条绘制，这里简单用小圆点
        speedX = (random.nextDouble() - 0.5) * 0.2;
        speedY = random.nextDouble() * 5 + 5; // 快速下落
        opacity = random.nextDouble() * 0.3 + 0.3;
        break;
      case 'firefly':
        color = Colors.lightGreenAccent.withAlpha(150);
        size = random.nextDouble() * 3 + 1;
        speedX = (random.nextDouble() - 0.5) * 0.8;
        speedY = (random.nextDouble() - 0.5) * 0.8; // 随机漂浮
        opacity = random.nextDouble() * 0.8 + 0.2; // 闪烁效果在update处理
        break;
      case 'snow':
        color = Colors.white;
        size = random.nextDouble() * 3 + 2;
        speedX = (random.nextDouble() - 0.5) * 1.0;
        speedY = random.nextDouble() * 1.0 + 0.5;
        opacity = random.nextDouble() * 0.4 + 0.4;
        break;
      default: // none or fallback
        color = Theme.of(context).colorScheme.primary.withAlpha(100);
        size = random.nextDouble() * 3 + 1;
        speedX = (random.nextDouble() - 0.5) * 0.5;
        speedY = (random.nextDouble() - 0.5) * 0.5;
        opacity = random.nextDouble() * 0.5 + 0.2;
    }

    // 应用用户自定义颜色（如果有）
    if (widget.particleColor != null) {
      color = widget.particleColor!;
    }

    return Particle(
      x: x ?? random.nextDouble() * _size.width,
      y: y ?? random.nextDouble() * _size.height,
      size: size,
      speedX: speedX,
      speedY: speedY,
      opacity: opacity,
      color: color,
    );
  }

  void _updateParticles() {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    if (!settings.particleEnabled || _size == Size.zero) return;

    final type = settings.particleType;
    final speedMultiplier = settings.particleSpeed * 2.0; // 0.1-1.0 -> 0.2-2.0

    for (var particle in _particles) {
      particle.x += particle.speedX * speedMultiplier;
      particle.y += particle.speedY * speedMultiplier;

      // 特殊效果逻辑
      if (type == 'firefly') {
        // 萤火虫闪烁
        particle.opacity += (_random.nextDouble() - 0.5) * 0.05;
        particle.opacity = particle.opacity.clamp(0.0, 1.0);
        // 随机改变方向
        if (_random.nextDouble() < 0.05) {
          particle.speedX = (_random.nextDouble() - 0.5) * 0.8;
          particle.speedY = (_random.nextDouble() - 0.5) * 0.8;
        }
      } else if (type == 'sakura' || type == 'snow') {
        // 飘落摆动
        particle.x += sin(particle.y * 0.05) * 0.5 * speedMultiplier;
      }

      // 边界检测，循环出现
      if (particle.x < -10) particle.x = _size.width + 10;
      if (particle.x > _size.width + 10) particle.x = -10;
      if (particle.y < -10) particle.y = _size.height + 10;
      if (particle.y > _size.height + 10) particle.y = -10;
    }

    if (mounted) setState(() {});
  }
}

/// 粒子绘制器
/// 
/// 负责将粒子列表绘制到画布上
class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  
  /// 缓存 Paint 对象以减少对象创建开销
  final Paint _paint = Paint()..style = PaintingStyle.fill;

  ParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      _paint.color = particle.color.withAlpha((particle.opacity * 255).toInt());
      canvas.drawCircle(
        Offset(particle.x, particle.y),
        particle.size,
        _paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) {
    // 粒子动画需要持续重绘
    return true;
  }
}
