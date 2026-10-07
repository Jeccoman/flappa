import 'package:flutter/material.dart';

enum DeviceKind { none, iphone, android, tablet, laptop, monitor }

enum DeviceFinish { graphite, silver, blue }

class CanvasDevice {
  const CanvasDevice(this.id, this.label, this.kind, this.viewport);
  final String id, label;
  final DeviceKind kind;
  final Size viewport;
  bool get canRotate =>
      [DeviceKind.iphone, DeviceKind.android, DeviceKind.tablet].contains(kind);
  Size screenSize(bool landscape) =>
      landscape && canRotate ? Size(viewport.height, viewport.width) : viewport;
  EdgeInsets get bezel => switch (kind) {
    DeviceKind.none => EdgeInsets.zero,
    DeviceKind.iphone || DeviceKind.android => const EdgeInsets.all(12),
    DeviceKind.tablet => const EdgeInsets.all(20),
    DeviceKind.laptop => const EdgeInsets.fromLTRB(18, 24, 18, 44),
    DeviceKind.monitor => const EdgeInsets.fromLTRB(18, 18, 18, 110),
  };
  double get radius => switch (kind) {
    DeviceKind.iphone => 50,
    DeviceKind.android => 38,
    DeviceKind.tablet => 32,
    DeviceKind.laptop || DeviceKind.monitor => 22,
    DeviceKind.none => 0,
  };
  EdgeInsets safeArea(bool landscape) => switch (kind) {
    DeviceKind.iphone =>
      landscape
          ? const EdgeInsets.fromLTRB(54, 0, 24, 21)
          : const EdgeInsets.only(top: 54, bottom: 34),
    DeviceKind.android =>
      landscape
          ? const EdgeInsets.fromLTRB(32, 0, 0, 24)
          : const EdgeInsets.only(top: 32, bottom: 24),
    DeviceKind.tablet => const EdgeInsets.only(top: 24, bottom: 20),
    _ => EdgeInsets.zero,
  };
  Size frameSize(Size screen) =>
      Size(screen.width + bezel.horizontal, screen.height + bezel.vertical);

  static const all = [
    CanvasDevice('none', 'No device frame', DeviceKind.none, Size(390, 844)),
    CanvasDevice(
      'iphone',
      'iPhone-style phone',
      DeviceKind.iphone,
      Size(390, 844),
    ),
    CanvasDevice(
      'android',
      'Android phone',
      DeviceKind.android,
      Size(412, 915),
    ),
    CanvasDevice('tablet', 'Tablet', DeviceKind.tablet, Size(834, 1194)),
    CanvasDevice('laptop', 'Laptop', DeviceKind.laptop, Size(1280, 800)),
    CanvasDevice(
      'monitor',
      'Desktop monitor',
      DeviceKind.monitor,
      Size(1440, 900),
    ),
  ];
  static CanvasDevice? find(String id) =>
      all.where((device) => device.id == id).firstOrNull;
}

class DeviceFrame extends StatelessWidget {
  const DeviceFrame({
    super.key,
    required this.device,
    required this.screenSize,
    required this.child,
    this.landscape = false,
    this.finish = DeviceFinish.graphite,
    this.dark = false,
  });
  final CanvasDevice device;
  final Size screenSize;
  final Widget child;
  final bool landscape, dark;
  final DeviceFinish finish;

  @override
  Widget build(BuildContext context) {
    if (device.kind == DeviceKind.none) return child;
    final outer = device.frameSize(screenSize);
    final bezel = device.bezel;
    final colors = switch (finish) {
      DeviceFinish.graphite => const [
        Color(0xFF707277),
        Color(0xFF202125),
        Color(0xFF4B4D52),
      ],
      DeviceFinish.silver => const [
        Color(0xFFE4E5E7),
        Color(0xFF8D9096),
        Color(0xFFD9DADE),
      ],
      DeviceFinish.blue => const [
        Color(0xFF899AAE),
        Color(0xFF354355),
        Color(0xFF65778E),
      ],
    };
    final desktop =
        device.kind == DeviceKind.laptop || device.kind == DeviceKind.monitor;
    final phone =
        device.kind == DeviceKind.iphone || device.kind == DeviceKind.android;
    final radius = device.radius;
    final safe = device.safeArea(landscape);
    final ink = dark ? Colors.white : const Color(0xFF17171A);
    final shellHeight = device.kind == DeviceKind.monitor
        ? outer.height - 90
        : device.kind == DeviceKind.laptop
        ? outer.height - 24
        : outer.height;
    final frame = Stack(
      clipBehavior: Clip.none,
      children: [
        if (device.kind == DeviceKind.monitor) ...[
          Positioned(
            bottom: 10,
            left: outer.width / 2 - 38,
            width: 76,
            height: 96,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: outer.width / 2 - 120,
            width: 240,
            height: 14,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors),
                borderRadius: BorderRadius.circular(7),
              ),
            ),
          ),
        ],
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: shellHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
              border: Border.all(color: colors.first, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .18),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 4,
          right: 4,
          top: 4,
          height: shellHeight - 8,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF090A0B),
              borderRadius: BorderRadius.circular(radius - 4),
            ),
          ),
        ),
        if (phone) ...[
          Positioned(
            left: -3,
            top: shellHeight * .2,
            width: 3,
            height: 28,
            child: _Hardware(color: colors[1]),
          ),
          Positioned(
            left: -3,
            top: shellHeight * .28,
            width: 3,
            height: 54,
            child: _Hardware(color: colors[1]),
          ),
          Positioned(
            right: -3,
            top: shellHeight * .3,
            width: 3,
            height: 68,
            child: _Hardware(color: colors[1]),
          ),
        ],
        Positioned(
          left: bezel.left,
          top: bezel.top,
          width: screenSize.width,
          height: screenSize.height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(desktop ? 6 : radius - 12),
            child: Stack(
              children: [
                Positioned.fill(
                  child: MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      size: screenSize,
                      padding: safe,
                      viewPadding: safe,
                      viewInsets: EdgeInsets.zero,
                    ),
                    child: child,
                  ),
                ),
                if (!desktop)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ExcludeSemantics(
                        child: Stack(
                          children: [
                            if (!landscape || device.kind == DeviceKind.tablet)
                              Positioned(
                                left: 24,
                                right: 22,
                                top: device.kind == DeviceKind.iphone ? 16 : 7,
                                child: Row(
                                  children: [
                                    Text(
                                      '9:41',
                                      style: TextStyle(
                                        fontFamily: 'sans-serif',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: ink,
                                      ),
                                    ),
                                    const Spacer(),
                                    Icon(
                                      Icons.signal_cellular_alt,
                                      size: 14,
                                      color: ink,
                                    ),
                                    const SizedBox(width: 5),
                                    Icon(Icons.wifi, size: 14, color: ink),
                                    const SizedBox(width: 5),
                                    Icon(
                                      Icons.battery_full,
                                      size: 16,
                                      color: ink,
                                    ),
                                  ],
                                ),
                              ),
                            if (device.kind == DeviceKind.iphone ||
                                device.kind == DeviceKind.android)
                              Positioned(
                                left: landscape ? 10 : null,
                                top: landscape
                                    ? screenSize.height / 2 -
                                          (device.kind == DeviceKind.iphone
                                              ? 52
                                              : 6)
                                    : 10,
                                right: landscape ? null : 0,
                                width: landscape
                                    ? (device.kind == DeviceKind.iphone
                                          ? 30
                                          : 12)
                                    : screenSize.width,
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: Container(
                                    width: device.kind == DeviceKind.iphone
                                        ? (landscape ? 30 : 104)
                                        : 12,
                                    height: device.kind == DeviceKind.iphone
                                        ? (landscape ? 104 : 30)
                                        : 12,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF090A0B),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: device.kind == DeviceKind.iphone
                                        ? Align(
                                            alignment: landscape
                                                ? Alignment.bottomCenter
                                                : Alignment.centerRight,
                                            child: Padding(
                                              padding: const EdgeInsets.all(8),
                                              child: Container(
                                                width: 8,
                                                height: 8,
                                                decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Color(0xFF172230),
                                                ),
                                              ),
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                            Positioned(
                              bottom: 8,
                              left: screenSize.width / 2 - 60,
                              width: 120,
                              height: 4,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: ink,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (desktop || device.kind == DeviceKind.tablet)
          Positioned(
            top: desktop ? 8 : 6,
            left: outer.width / 2 - 3,
            width: 6,
            height: 6,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF203547),
              ),
            ),
          ),
        if (device.kind == DeviceKind.laptop) ...[
          Positioned(
            bottom: 4,
            left: 0,
            right: 0,
            height: 24,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: colors,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(3),
                  bottom: Radius.circular(16),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 19,
            left: outer.width / 2 - 65,
            width: 130,
            height: 9,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors[1],
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ],
    );
    return SizedBox(width: outer.width, height: outer.height, child: frame);
  }
}

class _Hardware extends StatelessWidget {
  const _Hardware({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(2),
    ),
  );
}
