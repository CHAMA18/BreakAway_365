import 'package:flutter/material.dart';
import 'package:breakaway365_web/services/walkthrough_service.dart';

/// A modern walkthrough overlay that displays step-by-step tutorials
class WalkthroughOverlay extends StatefulWidget {
  final Widget child;

  const WalkthroughOverlay({super.key, required this.child});

  @override
  State<WalkthroughOverlay> createState() => _WalkthroughOverlayState();
}

class _WalkthroughOverlayState extends State<WalkthroughOverlay>
    with SingleTickerProviderStateMixin {
  final WalkthroughService _service = WalkthroughService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );
    _service.addListener(_onWalkthroughChanged);
  }

  void _onWalkthroughChanged() {
    if (_service.isWalkthroughActive) {
      _animationController.forward(from: 0);
    } else {
      _animationController.reverse();
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _service.removeListener(_onWalkthroughChanged);
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_service.isWalkthroughActive && _service.currentStep != null)
          FadeTransition(
            opacity: _fadeAnimation,
            child: _WalkthroughContent(
              step: _service.currentStep!,
              stepIndex: _service.currentStepIndex,
              totalSteps: _service.totalSteps,
              scaleAnimation: _scaleAnimation,
              onNext: _service.nextStep,
              onPrevious: _service.previousStep,
              onSkip: _service.endWalkthrough,
              onGoToStep: _service.goToStep,
            ),
          ),
      ],
    );
  }
}

class _WalkthroughContent extends StatelessWidget {
  final WalkthroughStep step;
  final int stepIndex;
  final int totalSteps;
  final Animation<double> scaleAnimation;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onSkip;
  final ValueChanged<int> onGoToStep;

  const _WalkthroughContent({
    required this.step,
    required this.stepIndex,
    required this.totalSteps,
    required this.scaleAnimation,
    required this.onNext,
    required this.onPrevious,
    required this.onSkip,
    required this.onGoToStep,
  });

  static const Color _overlayColor = Color(0xE6111827);
  static const Color _cardBackground = Colors.white;
  static const Color _accentTeal = Color(0xFF1BA4B8);
  static const Color _titleColor = Color(0xFF111827);
  static const Color _mutedColor = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    final isLastStep = stepIndex >= totalSteps - 1;
    final isFirstStep = stepIndex == 0;

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () {}, // Prevent taps from passing through
        child: Container(
          color: _overlayColor,
          child: SafeArea(
            child: Center(
              child: ScaleTransition(
                scale: scaleAnimation,
                child: Container(
                  margin: const EdgeInsets.all(24),
                  constraints: const BoxConstraints(maxWidth: 460),
                  decoration: BoxDecoration(
                    color: _cardBackground,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header with icon
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _accentTeal,
                              _accentTeal.withValues(alpha: 0.85),
                            ],
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                        ),
                        child: Column(
                          children: [
                            // Skip button row
                            Align(
                              alignment: Alignment.topRight,
                              child: GestureDetector(
                                onTap: onSkip,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Skip Tour',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Icon
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                step.icon ?? Icons.lightbulb_outline,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Step counter
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Step ${stepIndex + 1} of $totalSteps',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Content
                      Padding(
                        padding: const EdgeInsets.fromLTRB(28, 28, 28, 16),
                        child: Column(
                          children: [
                            Text(
                              step.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: _titleColor,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              step.description,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: _mutedColor,
                                fontSize: 15,
                                height: 1.6,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Step dots
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(totalSteps, (index) {
                            final isActive = index == stepIndex;
                            final isCompleted = index < stepIndex;
                            return GestureDetector(
                              onTap: () => onGoToStep(index),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: isActive ? 28 : 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? _accentTeal
                                      : isCompleted
                                          ? _accentTeal.withValues(alpha: 0.4)
                                          : const Color(0xFFE5E7EB),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),

                      // Navigation buttons
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                        child: Row(
                          children: [
                            // Previous button
                            Expanded(
                              child: _NavigationButton(
                                label: 'Previous',
                                icon: Icons.arrow_back_rounded,
                                isEnabled: !isFirstStep,
                                isPrimary: false,
                                onTap: isFirstStep ? null : onPrevious,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Next/Finish button
                            Expanded(
                              child: _NavigationButton(
                                label: isLastStep ? 'Finish' : 'Next',
                                icon: isLastStep
                                    ? Icons.check_rounded
                                    : Icons.arrow_forward_rounded,
                                isEnabled: true,
                                isPrimary: true,
                                onTap: onNext,
                                iconOnRight: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isEnabled;
  final bool isPrimary;
  final VoidCallback? onTap;
  final bool iconOnRight;

  const _NavigationButton({
    required this.label,
    required this.icon,
    required this.isEnabled,
    required this.isPrimary,
    this.onTap,
    this.iconOnRight = false,
  });

  static const Color _accentTeal = Color(0xFF1BA4B8);
  static const Color _disabledColor = Color(0xFFE5E7EB);
  static const Color _borderColor = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor =
        isPrimary ? (isEnabled ? _accentTeal : _disabledColor) : Colors.white;
    final Color textColor = isPrimary
        ? Colors.white
        : (isEnabled ? const Color(0xFF111827) : const Color(0xFFBBBFC5));
    final Color iconColor = textColor;

    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: isPrimary
              ? null
              : Border.all(color: isEnabled ? _borderColor : _disabledColor),
          boxShadow: isPrimary && isEnabled
              ? [
                  BoxShadow(
                    color: _accentTeal.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!iconOnRight) ...[
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (iconOnRight) ...[
              const SizedBox(width: 8),
              Icon(icon, size: 18, color: iconColor),
            ],
          ],
        ),
      ),
    );
  }
}

/// A dialog to select which page walkthrough to start
class WalkthroughSelectionDialog extends StatelessWidget {
  final VoidCallback? onStartWalkthrough;

  const WalkthroughSelectionDialog({super.key, this.onStartWalkthrough});

  static const Color _titleColor = Color(0xFF111827);
  static const Color _mutedColor = Color(0xFF6B7280);
  static const Color _accentTeal = Color(0xFF1BA4B8);
  static const Color _borderColor = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 600),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _accentTeal.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.school_outlined,
                      color: _accentTeal,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Page Walkthroughs',
                          style: TextStyle(
                            color: _titleColor,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Select a page to learn about its features',
                          style: TextStyle(
                            color: _mutedColor.withValues(alpha: 0.8),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: _mutedColor),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: _borderColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Walkthrough list
            Flexible(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                shrinkWrap: true,
                itemCount: WalkthroughService.availableWalkthroughs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final walkthrough =
                      WalkthroughService.availableWalkthroughs[index];
                  return _WalkthroughTile(
                    walkthrough: walkthrough,
                    onTap: () {
                      Navigator.of(context).pop();
                      WalkthroughService().startWalkthrough(walkthrough.pageId);
                      onStartWalkthrough?.call();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalkthroughTile extends StatefulWidget {
  final PageWalkthrough walkthrough;
  final VoidCallback onTap;

  const _WalkthroughTile({required this.walkthrough, required this.onTap});

  @override
  State<_WalkthroughTile> createState() => _WalkthroughTileState();
}

class _WalkthroughTileState extends State<_WalkthroughTile> {
  bool _isHovered = false;

  static const Color _titleColor = Color(0xFF111827);
  static const Color _mutedColor = Color(0xFF6B7280);
  static const Color _accentTeal = Color(0xFF1BA4B8);
  static const Color _borderColor = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _isHovered ? const Color(0xFFF8FAFC) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered ? _accentTeal.withValues(alpha: 0.3) : _borderColor,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: _accentTeal.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _isHovered
                      ? _accentTeal.withValues(alpha: 0.15)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.walkthrough.pageIcon,
                  color: _isHovered ? _accentTeal : _mutedColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.walkthrough.pageName,
                      style: TextStyle(
                        color: _titleColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.walkthrough.pageDescription,
                      style: TextStyle(
                        color: _mutedColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _isHovered
                      ? _accentTeal
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${widget.walkthrough.steps.length} steps',
                      style: TextStyle(
                        color: _isHovered ? Colors.white : _mutedColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.play_arrow_rounded,
                      size: 16,
                      color: _isHovered ? Colors.white : _mutedColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
