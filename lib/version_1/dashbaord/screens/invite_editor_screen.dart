import 'dart:io';

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wedding_invite/version_1/outfit_inspo/screens/outfit_inspo_screen.dart';

class InviteEditorScreenSliver extends StatefulWidget {
  const InviteEditorScreenSliver({
    super.key,
    required this.cardAsset,
    required this.heroTag,
    required this.onBack,
  });

  final String cardAsset;
  final String heroTag;
  final VoidCallback onBack;

  @override
  State<InviteEditorScreenSliver> createState() =>
      _InviteEditorScreenSliverState();
}

class _InviteEditorScreenSliverState extends State<InviteEditorScreenSliver> {
  Future<void> _loadPalette() async {
    final imageProvider = AssetImage(widget.cardAsset);

    final palette = await PaletteGenerator.fromImageProvider(
      imageProvider,
      size: const Size(200, 300), // smaller = faster
      maximumColorCount: 16,
    );

    // Prefer dark vibrant → dominant → fallback
    final base =
        palette.darkVibrantColor?.color ??
        palette.dominantColor?.color ??
        const Color(0xFF2C1D1D);

    setState(() {
      _blurTint = _darken(base, 0.02);
    });
  }

  Color _darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  final _scrollController = ScrollController();
  Color _blurTint = const Color(0xFF2C1D1D);
  late AnimationController _sheetController;

  final _name1 = TextEditingController();
  final _name2 = TextEditingController();

  String _inviteType = "Save the date";
  DateTime? _date;
  bool _sharing = false;
  final GlobalKey _previewKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadPalette();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _name1.dispose();
    _name2.dispose();
    super.dispose();
  }

  Future<File> _capturePreviewToFile() async {
    final boundary =
        _previewKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

    // Higher pixelRatio = sharper output (2.5–4 is good)
    final ui.Image image = await boundary.toImage(pixelRatio: 3.5);

    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    final dir = await getTemporaryDirectory();
    final file = File(
      "${dir.path}/invite_${DateTime.now().millisecondsSinceEpoch}.png",
    );

    await file.writeAsBytes(pngBytes, flush: true);
    return file;
  }

  Future<void> _shareInvite() async {
    setState(() => _sharing = true);
    try {
      final file = await _capturePreviewToFile();
      await Share.shareXFiles([XFile(file.path)], text: "Save the date 💌");
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const pinkBg = Color(0xffFFECF6);
    const primaryMaroon = Color(0xFF771549);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: pinkBg,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1) TOP PREVIEW HERO SECTION
          SliverToBoxAdapter(
            child: Column(
              children: [
                ClipPath(
                  clipper: TripleWaveBottomClipper(
                    waveHeight: 24.h,
                    amplitude: 18.h,
                  ),
                  child: Container(
                    height: 651.h,
                    width: double.infinity,
                    // decoration: const BoxDecoration(
                    //   gradient: LinearGradient(
                    //     begin: Alignment.topCenter,
                    //     end: Alignment.bottomCenter,
                    //     colors: [Color(0xFF2C1D1D), Color(0xFF6B4B4B)],
                    //   ),
                    // ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  _blurTint.withOpacity(0.85),
                                  _blurTint.withOpacity(0.65),
                                ],
                              ),
                            ),
                          ),
                        ),

                        SafeArea(
                          child: Column(
                            children: [
                              // The big invite preview card
                              Align(
                                alignment: Alignment.topLeft,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: IconButton(
                                    onPressed: () async {
                                      // slide sheet down if already animated in
                                      try {
                                        _sheetController.reverse();
                                        await Future.delayed(260.ms);
                                      } catch (_) {}
                                      widget.onBack();
                                    },
                                    icon: const Icon(
                                      Icons.arrow_back,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.center,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 26.w,
                                  ),
                                  child: Hero(
                                    tag: widget.heroTag,
                                    flightShuttleBuilder:
                                        (
                                          flightContext,
                                          animation,
                                          flightDirection,
                                          fromHeroContext,
                                          toHeroContext,
                                        ) {
                                          return FadeTransition(
                                            opacity: CurvedAnimation(
                                              parent: animation,
                                              curve: Curves.easeOut,
                                            ),
                                            child: toHeroContext.widget,
                                          );
                                        },
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        top: 10.h,
                                        bottom: 0,
                                      ),
                                      child: RepaintBoundary(
                                        key: _previewKey,
                                        child: _InvitePreviewCard(
                                          cardAsset: widget.cardAsset,
                                          title: _inviteType,
                                          name1: _name1.text.isEmpty
                                              ? "Jane"
                                              : _name1.text,
                                          name2: _name2.text.isEmpty
                                              ? "Joe"
                                              : _name2.text,
                                          dateText: _date == null
                                              ? _formattedToday()
                                              : _formatDate(_date!),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Back button overlay (like your inspo)
              ],
            ),
          ),

          // 2) WAVY SHEET CONTENT (FORM)
          SliverToBoxAdapter(
            child: Stack(
              children: [
                Container(
                      width: double.infinity,
                      color: Color(0xffFFECF6),
                      padding: EdgeInsets.fromLTRB(22.w, 28.w, 22.w, 26.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Invite details",
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w400,
                              color: primaryMaroon,
                              fontFamily: "Montage",
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Name fields
                          Row(
                            children: [
                              Expanded(
                                child: _LabeledTextField(
                                  label: "Name 1",
                                  controller: _name1,
                                  hint: "Add name",
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _LabeledTextField(
                                  label: "Name 2",
                                  controller: _name2,
                                  hint: "Add name",
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 37),

                          // Invite type dropdown
                          _LabeledDropdown(
                            label: "Invite type",
                            valueText: _inviteType,
                            onTap: () async {
                              final selected =
                                  await showModalBottomSheet<String>(
                                    context: context,
                                    backgroundColor: Colors.white,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(18),
                                      ),
                                    ),
                                    builder: (context) {
                                      return SafeArea(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const SizedBox(height: 10),
                                            _SheetTile(
                                              title: "Save the date",
                                              onTap: () => Navigator.pop(
                                                context,
                                                "Save the date",
                                              ),
                                            ),
                                            _SheetTile(
                                              title: "Wedding invite",
                                              onTap: () => Navigator.pop(
                                                context,
                                                "Wedding invite",
                                              ),
                                            ),
                                            _SheetTile(
                                              title: "Reception invite",
                                              onTap: () => Navigator.pop(
                                                context,
                                                "Reception invite",
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                          ],
                                        ),
                                      );
                                    },
                                  );

                              if (selected != null) {
                                setState(() => _inviteType = selected);
                              }
                            },
                          ),

                          const SizedBox(height: 37),

                          // Date picker field
                          _LabeledPickerField(
                            label: "Date",
                            valueText: _date == null
                                ? "Date"
                                : _formatDate(_date!),
                            icon: Icons.calendar_month,
                            onTap: () async {
                              final now = DateTime.now();
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _date ?? now,
                                firstDate: DateTime(now.year - 1),
                                lastDate: DateTime(now.year + 5),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: primaryMaroon,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );

                              if (picked != null) {
                                setState(() => _date = picked);
                              }
                            },
                          ),

                          const SizedBox(height: 59),

                          // Share button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () {
                                _shareInvite();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryMaroon,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                              child: _sharing
                                  ? SizedBox(
                                      width: 50,
                                      child: LoadingIndicator(
                                        indicatorType: Indicator
                                            .ballScaleMultiple, // Soft pulsing circles
                                        colors: [
                                          const Color(
                                            0xFF06471D,
                                          ), // Your deep green
                                          const Color(
                                            0xFF8B2B57,
                                          ), // Your badge pink
                                        ],
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      "Share",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: "SFPRO",
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 107),
                        ],
                      ),
                    )
                    .animate(onInit: (c) => _sheetController = c)
                    .fadeIn(duration: 400.ms, delay: 220.ms)
                    .slideY(
                      begin: 0.35,
                      end: 0,
                      duration: 800.ms,
                      curve: Curves.easeOutCubic,
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formattedToday() {
    final now = DateTime.now();
    return "${now.day.toString().padLeft(2, '0')}."
        "${now.month.toString().padLeft(2, '0')}."
        "${now.year}";
  }

  String _formatDate(DateTime d) {
    return "${d.day.toString().padLeft(2, '0')}."
        "${d.month.toString().padLeft(2, '0')}."
        "${d.year}";
  }
}

// -------------------- PREVIEW CARD WIDGET --------------------

class _InvitePreviewCard extends StatelessWidget {
  const _InvitePreviewCard({
    required this.cardAsset,
    required this.title,
    required this.name1,
    required this.name2,
    required this.dateText,
  });

  final String cardAsset;
  final String title;
  final String name1;
  final String name2;
  final String dateText;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        height: 469.h,
        width: 390.w,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                cardAsset,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

            // Center template text
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w400,
                        fontFamily: "Montage",
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      "$name1\n&\n$name2",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 37,
                        height: 1.12,
                        fontWeight: FontWeight.w400,
                        fontFamily: "Montage",
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      dateText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                        fontFamily: "SFPRO",
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------- FORM FIELD HELPERS --------------------

class _LabeledTextField extends StatelessWidget {
  const _LabeledTextField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475467),
            fontFamily: "Inter",
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFF6D164B),
                width: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LabeledDropdown extends StatelessWidget {
  const _LabeledDropdown({
    required this.label,
    required this.valueText,
    required this.onTap,
  });

  final String label;
  final String valueText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _LabeledPickerField(
      label: label,
      valueText: valueText,
      icon: Icons.keyboard_arrow_down,
      onTap: onTap,
    );
  }
}

class _LabeledPickerField extends StatelessWidget {
  const _LabeledPickerField({
    required this.label,
    required this.valueText,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String valueText;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475467),
            fontFamily: "Inter",
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black.withOpacity(0.08)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      valueText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B6B6B),
                        fontFamily: "SFPRO",
                      ),
                    ),
                  ),
                  Icon(icon, color: Colors.black.withOpacity(0.55)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SheetTile extends StatelessWidget {
  const _SheetTile({required this.title, required this.onTap});
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: "SFPRO",

          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}
