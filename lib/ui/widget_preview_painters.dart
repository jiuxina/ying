part of 'widget_preview_section.dart';

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({
    required this.progress,
    required this.size,
    required this.color,
    required this.track,
  });

  final double progress;
  final double size;
  final Color color;
  final Color track;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _RingPainter(progress: progress, color: color, track: track),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
  });

  final double progress;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - 6) / 2;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = track;
    canvas.drawCircle(center, radius, stroke);
    stroke.color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -0.5 * 3.141592653589793,
      6.283185307179586 * progress.clamp(0.0, 1.0),
      false,
      stroke,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.track != track;
}

class _PixelHealthBar extends StatelessWidget {
  const _PixelHealthBar({
    required this.progress,
    required this.accent,
    required this.track,
  });

  final double progress;
  final Color accent;
  final Color track;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 82,
      height: 14,
      child: CustomPaint(
        painter: _PixelBarPainter(
          progress: progress,
          accent: accent,
          track: track,
        ),
      ),
    );
  }
}

class _PixelBarPainter extends CustomPainter {
  const _PixelBarPainter({
    required this.progress,
    required this.accent,
    required this.track,
  });

  final double progress;
  final Color accent;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const segments = 12;
    final gap = 2.0;
    final segmentWidth = (size.width - gap * (segments - 1)) / segments;
    final filled = (progress.clamp(0.0, 1.0) * segments).ceil();
    final background = Paint()..color = track;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        const Radius.circular(2),
      ),
      background,
    );
    final fill = Paint()..color = accent;
    for (var index = 0; index < filled; index++) {
      final left = index * (segmentWidth + gap);
      canvas.drawRect(
        Rect.fromLTWH(left, 1, segmentWidth, size.height - 2),
        fill,
      );
    }
  }

  @override
  bool shouldRepaint(_PixelBarPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.accent != accent ||
      oldDelegate.track != track;
}

class _PreviewBackdrop extends StatelessWidget {
  const _PreviewBackdrop({
    required this.style,
    required this.color,
    required this.accent,
    required this.imageProvider,
  });

  final WidgetStyle style;
  final Color color;
  final Color accent;
  final ImageProvider? imageProvider;

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case WidgetStyle.card:
        return ColoredBox(color: color);
      case WidgetStyle.sticker:
      case WidgetStyle.minimal:
        return const SizedBox.shrink();
      case WidgetStyle.photo:
        final image = imageProvider;
        if (image != null) {
          return Image(
            image: image,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _photoPlaceholder(accent),
          );
        }
        return _photoPlaceholder(accent);
      case WidgetStyle.glass:
        return ColoredBox(color: Colors.white.withValues(alpha: 0.72));
      case WidgetStyle.polaroid:
        return Column(
          children: [
            const Expanded(child: ColoredBox(color: Colors.white)),
            ColoredBox(
              color: const Color(0xFFF0EDE6),
              child: const SizedBox(height: 30),
            ),
          ],
        );
      case WidgetStyle.neon:
        return ColoredBox(color: const Color(0xFF0A0F1E));
      case WidgetStyle.pixel:
        return ColoredBox(color: const Color(0xFF141414));
      case WidgetStyle.envelope:
        return const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF4A2B2B), Color(0xFF2A1717)],
            ),
          ),
        );
      case WidgetStyle.capsule:
        return const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF24453F), Color(0xFFC58A4B)],
            ),
          ),
        );
      case WidgetStyle.crt:
        return CustomPaint(painter: _CrtPainter(accent: accent));
      case WidgetStyle.neonSign:
        return CustomPaint(painter: _NeonSignPainter(accent: accent));
      case WidgetStyle.pixelHealth:
        return CustomPaint(painter: _PixelBackdropPainter(accent: accent));
      case WidgetStyle.mirror:
        return CustomPaint(painter: _MirrorBackdropPainter(accent: accent));
    }
  }

  Widget _photoPlaceholder(Color accent) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent.withValues(alpha: 0.55), accent.withValues(alpha: 0.3)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.photo_outlined,
          color: Colors.white.withValues(alpha: 0.85),
          size: 30,
        ),
      ),
    );
  }
}

class _EnvelopeCover extends StatelessWidget {
  const _EnvelopeCover();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5B3330), Color(0xFF2C1917)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.mail_outline,
              color: Color(0xFFFFE3C2),
              size: 44,
            ),
            SizedBox(height: 8),
            Text(
              '神秘信封',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                shadows: [
                  Shadow(color: Colors.black54, blurRadius: 5),
                ],
              ),
            ),
            SizedBox(height: 4),
            Text(
              '点击查看事件',
              style: TextStyle(
                color: Color(0xCCFFFFFF),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CrtPainter extends CustomPainter {
  const _CrtPainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0A120C));
    final line = Paint()
      ..color = const Color(0x33000000)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
    final border = Paint()
      ..color = accent.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        const Radius.circular(8),
      ),
      border,
    );
  }

  @override
  bool shouldRepaint(_CrtPainter oldDelegate) =>
      oldDelegate.accent != accent;
}

class _NeonSignPainter extends CustomPainter {
  const _NeonSignPainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0A0F1E));
    final bounds = Rect.fromLTWH(3, 3, size.width - 6, size.height - 6);
    for (var index = 4; index >= 1; index--) {
      final glow = Paint()
        ..color = accent.withValues(alpha: 0.06 * index)
        ..style = PaintingStyle.stroke
        ..strokeWidth = index * 3;
      canvas.drawRRect(
        RRect.fromRectAndRadius(bounds, const Radius.circular(8)),
        glow,
      );
    }
    final border = Paint()
      ..color = accent.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, const Radius.circular(8)),
      border,
    );
  }

  @override
  bool shouldRepaint(_NeonSignPainter oldDelegate) =>
      oldDelegate.accent != accent;
}

class _PixelBackdropPainter extends CustomPainter {
  const _PixelBackdropPainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF101418));
    final grid = Paint()
      ..color = accent.withValues(alpha: 0.14)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 16) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += 16) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final block = Paint()..color = accent.withValues(alpha: 0.75);
    canvas.drawRect(const Rect.fromLTWH(12, 14, 10, 10), block);
    canvas.drawRect(const Rect.fromLTWH(34, 30, 10, 10), block);
    canvas.drawRect(
      Rect.fromLTWH(size.width - 40, size.height - 36, 14, 14),
      block,
    );
  }

  @override
  bool shouldRepaint(_PixelBackdropPainter oldDelegate) =>
      oldDelegate.accent != accent;
}

class _MirrorBackdropPainter extends CustomPainter {
  const _MirrorBackdropPainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF312E81), Color(0xFF9D174D)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint);
    final stripe = Paint()
      ..color = accent.withValues(alpha: 0.22)
      ..strokeWidth = 10;
    for (double x = -size.height; x < size.width; x += 34) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        stripe,
      );
    }
  }

  @override
  bool shouldRepaint(_MirrorBackdropPainter oldDelegate) =>
      oldDelegate.accent != accent;
}

class _HolidayBadge extends StatelessWidget {
  const _HolidayBadge({
    required this.holiday,
    required this.accent,
    this.weight = 0,
  });

  final WidgetHoliday holiday;
  final Color accent;
  final int weight;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.55)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          holiday.label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: weight <= 0
                ? FontWeight.w700
                : FontWeight.values[((weight ~/ 100) - 1).clamp(0, 8)],
            shadows: const [
              Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 1)),
            ],
          ),
        ),
      ),
    );
  }
}

Color? _holidayAccent(WidgetHoliday holiday) {
  switch (holiday) {
    case WidgetHoliday.newYear:
      return const Color(0xFFE11D48);
    case WidgetHoliday.christmas:
      return const Color(0xFF16A34A);
    case WidgetHoliday.midAutumn:
      return const Color(0xFFD97706);
    case WidgetHoliday.birthday:
      return const Color(0xFFEC4899);
    case WidgetHoliday.none:
      return null;
  }
}

