import 'dart:ui';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/event.dart';
import '../../data/models/invitee.dart';
import '../../data/models/person.dart';
import '../../data/models/task.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/glass_card.dart';

// ─── Color Palette (Visual Identity Guide) ───
class AppColors {
  AppColors._();

  // Primary Palette
  static const Color premiumGold = Color(0xFFC5A880);
  static const Color blushPink = Color(0xFFE5BAA9);
  static const Color creamyWhite = Color(0xFFFFFDF9);
  static const Color charcoalText = Color(0xFF2D2D2D);
  static const Color mutedGray = Color(0xFF757575);

  // Status Colors
  static const Color statusConfirmed = Color(0xFF4CAF50);
  static const Color statusPending = Color(0xFFFF9800);
  static const Color statusDeclined = Color(0xFFE57373);

  // Event Gradient Colors (soft pastels)
  static const List<Color> eventGradients = [
    Color(0xFFE5BAA9),
    Color(0xFFC5A880),
    Color(0xFFD4B896),
    Color(0xFFE8D5C4),
    Color(0xFFF0E6D8),
    Color(0xFFDDC9B4),
  ];

  // Service Background Colors
  static const Color serviceHalls = Color(0xFFFDF6F0);
  static const Color serviceCatering = Color(0xFFFDF0F0);
  static const Color servicePhoto = Color(0xFFF0F8FF);
  static const Color serviceInvites = Color(0xFFF5F0FF);
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 12) return 'صباح الخير';
    if (h >= 12 && h < 17) return 'نهارك سعيد';
    return 'مساء الخير';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final people = ref.watch(peopleProvider).valueOrNull ?? [];
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final events = ref.watch(eventsProvider).valueOrNull ?? [];
    final invitees = ref.watch(allInviteesProvider).valueOrNull ?? [];
    final tasks = ref.watch(tasksProvider).valueOrNull ?? [];
    final name = ref.watch(displayNameProvider).valueOrNull;

    final upcoming = events.where((e) => e.date != null && !e.isOver).toList()
      ..sort((a, b) => a.date!.compareTo(b.date!));
    final nextEvents = upcoming.take(3).toList();

    final calledCount = people.where((p) => p.lastCallStatus == 'called').length;
    final pendingInvites = invitees
        .where((i) => i.rsvpStatus == RsvpStatus.pending || i.rsvpStatus == RsvpStatus.notContacted)
        .length;
    final pendingTasks = tasks.where((t) => t.effectiveStatus != TaskStatus.completed).length;

    return Scaffold(
      backgroundColor: AppColors.creamyWhite,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            // ─── Header ───
            _Header(greeting: _greeting(), name: name, pendingTasks: pendingTasks)
                .animate()
                .fadeIn(duration: 350.ms)
                .slideY(begin: -0.15, end: 0, curve: Curves.easeOutCubic),
            const SizedBox(height: 16),

            // ─── Search Bar ───
            const _SearchBar().animate().fadeIn(delay: 80.ms, duration: 350.ms),
            const SizedBox(height: 24),

            // ─── Upcoming Events Carousel ───
            _UpcomingEventsCarousel(events: nextEvents, invitees: invitees, tasks: tasks)
                .animate()
                .fadeIn(delay: 140.ms, duration: 400.ms)
                .slideY(begin: 0.08, end: 0),
            const SizedBox(height: 28),

            // ─── Services Grid ───
            const _ServicesGrid()
                .animate()
                .fadeIn(delay: 200.ms, duration: 400.ms),
            const SizedBox(height: 28),

            // ─── Inspiration Grid ───
            const _InspirationGrid()
                .animate()
                .fadeIn(delay: 260.ms, duration: 400.ms),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: const _BottomNavBar(),
    );
  }
}

// ─── Header ───
class _Header extends StatelessWidget {
  final String greeting;
  final String? name;
  final int pendingTasks;
  const _Header({required this.greeting, required this.name, required this.pendingTasks});

  @override
  Widget build(BuildContext context) {
    final displayName = (name == null || name!.isEmpty) ? 'صديقنا' : name!;
    return Row(
      children: [
        // Profile Avatar
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppColors.premiumGold, AppColors.blushPink],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: AppColors.premiumGold, width: 2),
          ),
          alignment: Alignment.center,
          child: Text(
            displayName.isNotEmpty ? displayName.substring(0, 1) : '👋',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'مرحباً، $displayName! ✨',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.mutedGray,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'استعدي لاحتفالك القادم',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.charcoalText,
                ),
              ),
            ],
          ),
        ),
        // Notification Bell
        _NotificationBell(count: pendingTasks),
      ],
    );
  }
}

class _NotificationBell extends StatelessWidget {
  final int count;
  const _NotificationBell({required this.count});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE8E0D5), width: 1),
          ),
          child: const Icon(
            Icons.notifications_none_rounded,
            color: AppColors.charcoalText,
            size: 22,
          ),
        ),
        if (count > 0)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: const BoxDecoration(
                color: AppColors.statusDeclined,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              alignment: Alignment.center,
              child: Text(
                '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Search Bar ───
class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E0D5), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Icon(
              Icons.search,
              color: AppColors.premiumGold,
              size: 20,
            ),
          ),
          Expanded(
            child: TextField(
              style: const TextStyle(
                color: AppColors.charcoalText,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'بحث عن مناسبات، خدمات...',
                hintStyle: TextStyle(
                  color: AppColors.mutedGray.withOpacity(0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Upcoming Events Carousel ───
class _UpcomingEventsCarousel extends StatelessWidget {
  final List<EventItem> events;
  final List<Invitee> invitees;
  final List<TaskItem> tasks;

  const _UpcomingEventsCarousel({
    required this.events,
    required this.invitees,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'مناسباتي القادمة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoalText,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/events'),
              child: const Text(
                'الكل ←',
                style: TextStyle(
                  color: AppColors.premiumGold,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (events.isEmpty)
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF0EBE3)),
            ),
            child: Center(
              child: Text(
                'لا توجد مناسبات قادمة',
                style: TextStyle(
                  color: AppColors.mutedGray.withOpacity(0.5),
                  fontSize: 14,
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 280,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: events.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) => _EventCard(
                event: events[index],
                invitees: invitees,
                tasks: tasks,
              ),
            ),
          ),
      ],
    );
  }
}

class _EventCard extends StatelessWidget {
  final EventItem event;
  final List<Invitee> invitees;
  final List<TaskItem> tasks;

  const _EventCard({
    required this.event,
    required this.invitees,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context) {
    final guestCount = invitees
        .where((i) => i.eventId == event.id)
        .fold<int>(0, (s, i) => s + i.companions);
    final eventTasks = tasks.where((t) => t.eventId == event.id).toList();
    final completion = eventTasks.isEmpty
        ? 0.0
        : eventTasks.where((t) => t.effectiveStatus == TaskStatus.completed).length /
            eventTasks.length;

    final gradientColors = AppColors.eventGradients[
        event.colorIndex % AppColors.eventGradients.length];
    final days = event.date!.difference(DateTime.now()).inDays;

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0EBE3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Image Header
          Container(
            height: 140,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  gradientColors,
                  gradientColors.withOpacity(0.7),
                ],
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    _getEventIcon(event.name),
                    size: 60,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 12,
                          color: AppColors.premiumGold,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'قادمة',
                          style: TextStyle(
                            color: AppColors.premiumGold,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Event Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoalText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  formatDate(event.date),
                  style: TextStyle(
                    color: AppColors.mutedGray.withOpacity(0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 12),
                // Countdown Badge
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.blushPink,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '⏰ متبقي: ${days < 0 ? '0' : '$days'} يوماً',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Mini Stats Row
                Row(
                  children: [
                    _MiniStat(
                      icon: Icons.groups_rounded,
                      value: '$guestCount',
                      label: 'مدعو',
                    ),
                    const SizedBox(width: 20),
                    _MiniStat(
                      icon: Icons.check_circle_rounded,
                      value: '${(completion * 100).round()}%',
                      label: 'اكتمال',
                    ),
                    const Spacer(),
                    // View Button
                    TextButton(
                      onPressed: () => context.push('/events/${event.id}'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.premiumGold,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: AppColors.premiumGold),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'عرض',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_back_rounded, size: 14),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getEventIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('زفاف') || lower.contains('wedding')) return Icons.favorite;
    if (lower.contains('تخرج') || lower.contains('grad')) return Icons.school;
    if (lower.contains('عيد') || lower.contains('birthday')) return Icons.cake;
    if (lower.contains('استقبال') || lower.contains('reception')) return Icons.celebration;
    return Icons.event;
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _MiniStat({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.mutedGray),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: AppColors.charcoalText,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: AppColors.mutedGray.withOpacity(0.7),
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Services Grid ───
class _ServicesGrid extends StatelessWidget {
  const _ServicesGrid();

  @override
  Widget build(BuildContext context) {
    final services = [
      (Icons.castle_rounded, 'قاعات', AppColors.serviceHalls),
      (Icons.restaurant_rounded, 'ضيافة', AppColors.serviceCatering),
      (Icons.camera_alt_rounded, 'تصوير', AppColors.servicePhoto),
      (Icons.mail_rounded, 'دعوات', AppColors.serviceInvites),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'استكشف الخدمات',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.charcoalText,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: services.map((service) {
            final (icon, label, bgColor) = service;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  // Navigate to service category
                },
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: bgColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFF0EBE3)),
                      ),
                      child: Icon(
                        icon,
                        color: AppColors.premiumGold,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.charcoalText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─── Inspiration Grid ───
class _InspirationGrid extends StatelessWidget {
  const _InspirationGrid();

  @override
  Widget build(BuildContext context) {
    final inspirations = [
      (Icons.cake_rounded, 'أفكار كيك', Color(0xFFFFE4E1), Color(0xFFFFD5CD)),
      (Icons.local_florist_rounded, 'تنسيق ورود', Color(0xFFE8F5E9), Color(0xFFC8E6C9)),
      (Icons.checkroom_rounded, 'فساتين', Color(0xFFFFF3E0), Color(0xFFFFE0B2)),
      (Icons.palette_rounded, 'ديكور', Color(0xFFF3E5F5), Color(0xFFE1BEE7)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'أحدث الأفكار والإلهام',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.charcoalText,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.1,
          ),
          itemCount: inspirations.length,
          itemBuilder: (context, index) {
            final (icon, label, color1, color2) = inspirations[index];
            return GestureDetector(
              onTap: () {
                // Navigate to inspiration detail
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color1, color2],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 40,
                      color: AppColors.charcoalText.withOpacity(0.3),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.charcoalText.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ─── Bottom Navigation Bar ───
class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: const Color(0xFFF0EBE3)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Home (Active)
              _NavItem(
                icon: Icons.home_rounded,
                label: 'الرئيسية',
                isActive: true,
                onTap: () {},
              ),
              // Events
              _NavItem(
                icon: Icons.calendar_month_rounded,
                label: 'مناسباتي',
                isActive: false,
                onTap: () => context.push('/events'),
              ),
              // FAB - Add Event
              GestureDetector(
                onTap: () => context.push('/events/new'),
                child: Container(
                  width: 56,
                  height: 56,
                  margin: const EdgeInsets.only(top: -20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.premiumGold, AppColors.blushPink],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.premiumGold.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              // People
              _NavItem(
                icon: Icons.people_rounded,
                label: 'الأشخاص',
                isActive: false,
                onTap: () => context.push('/people'),
              ),
              // Settings
              _NavItem(
                icon: Icons.settings_rounded,
                label: 'الإعدادات',
                isActive: false,
                onTap: () => context.push('/settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24,
            color: isActive ? AppColors.premiumGold : AppColors.mutedGray,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? AppColors.premiumGold : AppColors.mutedGray,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Arabic Months (for reference) ───
const _arabicMonths = [
  'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
  'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
];

