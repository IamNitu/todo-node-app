import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'todo_page.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  static const _purple = Color(0xFFC956D8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _purple,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, viewport) {
            final horizontalPadding = viewport.maxWidth < 360 ? 18.0 : 25.0;
            const topPadding = 20.0;
            const bottomPadding = 24.0;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                topPadding,
                horizontalPadding,
                bottomPadding,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight:
                          (viewport.maxHeight - topPadding - bottomPadding)
                              .clamp(0, double.infinity),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.circle,
                                  color: Color(0xFFFFEE54),
                                  size: 10,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'TODO, MADE SIMPLE',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.3,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: _openTodos,
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Skip'),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Make room for\nwhat matters.',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    height: 1.04,
                                    letterSpacing: -1.1,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Plan a little. Breathe a lot. Your day is yours.',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    height: 1.4,
                                  ),
                            ),
                          ],
                        ),
                        const _PlannerIllustration(),
                        FilledButton.icon(
                          onPressed: _openTodos,
                          iconAlignment: IconAlignment.end,
                          icon: const Icon(Icons.arrow_forward_rounded),
                          label: const Text("Let's get started"),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF8F35A1),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 17,
                            ),
                            textStyle: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _openTodos() async {
    final preferences = SharedPreferencesAsync();
    await preferences.setBool('has_seen_onboarding', true);
    Get.off<void>(() => const TodoPage());
  }
}

class _PlannerIllustration extends StatelessWidget {
  const _PlannerIllustration();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.12,
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Align(
              alignment: const Alignment(0.82, -0.72),
              child: FractionallySizedBox(
                widthFactor: 0.19,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE94D),
                      borderRadius: BorderRadius.circular(
                        constraints.maxWidth * 0.06,
                      ),
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: const Color(0xFF2E2530),
                      size: constraints.maxWidth * 0.09,
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: const Alignment(-0.86, -0.25),
              child: FractionallySizedBox(
                widthFactor: 0.14,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF8875),
                      borderRadius: BorderRadius.circular(
                        constraints.maxWidth * 0.045,
                      ),
                    ),
                    child: Icon(
                      Icons.favorite_rounded,
                      color: Colors.white,
                      size: constraints.maxWidth * 0.07,
                    ),
                  ),
                ),
              ),
            ),
            FractionallySizedBox(
              widthFactor: 0.76,
              child: Transform.rotate(
                angle: -0.035,
                child: Container(
                  padding: EdgeInsets.all(constraints.maxWidth * 0.055),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFCF5),
                    borderRadius: BorderRadius.circular(
                      constraints.maxWidth * 0.075,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF531D5C).withValues(alpha: 0.28),
                        blurRadius: constraints.maxWidth * 0.08,
                        offset: Offset(0, constraints.maxWidth * 0.045),
                      ),
                    ],
                  ),
                  child: const _PlannerNote(),
                ),
              ),
            ),
            Align(
              alignment: const Alignment(0.8, 0.82),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: constraints.maxWidth * 0.04,
                  vertical: constraints.maxWidth * 0.03,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2788F5),
                  borderRadius: BorderRadius.circular(
                    constraints.maxWidth * 0.05,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4F1D5A).withValues(alpha: 0.2),
                      blurRadius: constraints.maxWidth * 0.04,
                      offset: Offset(0, constraints.maxWidth * 0.02),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.bolt_rounded,
                      color: Colors.white,
                      size: constraints.maxWidth * 0.045,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        'One thing at a time',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: constraints.maxWidth * 0.03,
                          fontWeight: FontWeight.w700,
                        ),
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

class _PlannerNote extends StatelessWidget {
  const _PlannerNote();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "TODAY'S PLAN",
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: const Color(0xFF8F35A1),
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'A little progress adds up.',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: const Color(0xFF17151A),
            fontWeight: FontWeight.w800,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: const LinearProgressIndicator(
            value: 0.6,
            minHeight: 6,
            backgroundColor: Color(0xFFE9E3E9),
            color: Color(0xFFC956D8),
          ),
        ),
        const SizedBox(height: 10),
        const _PlanLine(label: 'Finish the project outline', checked: true),
        const _PlanLine(label: 'Take a screen break'),
        const _PlanLine(label: 'Make time to create'),
      ],
    );
  }
}

class _PlanLine extends StatelessWidget {
  const _PlanLine({required this.label, this.checked = false});

  final String label;
  final bool checked;

  @override
  Widget build(BuildContext context) {
    final color = checked ? const Color(0xFFFF8875) : const Color(0xFFB9F17A);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            checked ? Icons.check_circle_rounded : Icons.circle_outlined,
            color: checked ? const Color(0xFF73A83F) : color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF26232A),
                decoration: checked ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
