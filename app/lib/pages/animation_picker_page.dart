import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../provider/animation_provider.dart';
import '../l10n/app_localizations.dart';

class AnimationPickerPage extends StatefulWidget {
  const AnimationPickerPage({super.key});

  @override
  State<AnimationPickerPage> createState() => _AnimationPickerPageState();
}

class _AnimationPickerPageState extends State<AnimationPickerPage> {
  static const _animations = [
    _AnimationInfo('波浪 1', 'assets/animations/lottie/wave1.json', 0),
    _AnimationInfo('波浪 2', 'assets/animations/lottie/wave2.json', 1),
    _AnimationInfo('波浪 3', 'assets/animations/lottie/wave3.json', 2),
    _AnimationInfo('波浪 4', 'assets/animations/lottie/wave4.json', 3),
    _AnimationInfo('波浪 5', 'assets/animations/lottie/wave5.json', 4),
    _AnimationInfo('波浪 6', 'assets/animations/lottie/wave6.json', 5),
    _AnimationInfo('波浪 7', 'assets/animations/lottie/wave7.json', 6),
    _AnimationInfo('波浪 8', 'assets/animations/lottie/wave8.json', 7),
  ];

  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = context.read<AnimationProvider>().index;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.changeAppearance),
        actions: [
          TextButton(
            onPressed: () {
              context.read<AnimationProvider>().setIndex(_selectedIndex);
              Navigator.pop(context);
            },
             child: Text(l10n.done),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: _animations.length,
            itemBuilder: (context, index) {
              final anim = _animations[index];
              final isSelected = _selectedIndex == anim.index;
              return GestureDetector(
                onTap: () => setState(() => _selectedIndex = anim.index),
                child: Card(
                  elevation: isSelected ? 4 : 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isSelected
                        ? BorderSide(color: colorScheme.primary, width: 3)
                        : const BorderSide(color: Colors.transparent),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        Expanded(
                          child: Lottie.asset(
                            anim.assetPath,
                            animate: true,
                            repeat: true,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          anim.label,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AnimationInfo {
  final String label;
  final String assetPath;
  final int index;

  const _AnimationInfo(this.label, this.assetPath, this.index);
}
