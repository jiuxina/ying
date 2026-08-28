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

