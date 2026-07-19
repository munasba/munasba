import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/lock_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/categories/categories_screen.dart';
import '../../features/events/event_detail_screen.dart';
import '../../features/events/event_form_screen.dart';
import '../../features/events/events_list_screen.dart';
import '../../features/events/invitee_picker_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/people/people_list_screen.dart';
import '../../features/people/person_detail_screen.dart';
import '../../features/people/person_form_screen.dart';
import '../../features/reports/reports_screen.dart';
import '../../features/settings/about_screen.dart';
import '../../features/settings/security_settings_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/tasks/tasks_screen.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/lock', builder: (context, state) => const LockScreen()),
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),

      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),

          GoRoute(
            path: '/people',
            builder: (context, state) => const PeopleListScreen(),
            routes: [
              GoRoute(path: 'new', builder: (context, state) => const PersonFormScreen()),
              GoRoute(
                path: ':id',
                builder: (context, state) => PersonDetailScreen(personId: state.pathParameters['id']!),
              ),
              GoRoute(
                path: ':id/edit',
                builder: (context, state) => PersonFormScreen(personId: state.pathParameters['id']),
              ),
            ],
          ),

          GoRoute(path: '/categories', builder: (context, state) => const CategoriesScreen()),

          GoRoute(
            path: '/events',
            builder: (context, state) => const EventsListScreen(),
            routes: [
              GoRoute(path: 'new', builder: (context, state) => const EventFormScreen()),
              GoRoute(
                path: ':id',
                builder: (context, state) => EventDetailScreen(eventId: state.pathParameters['id']!),
              ),
              GoRoute(
                path: ':id/edit',
                builder: (context, state) => EventFormScreen(eventId: state.pathParameters['id']),
              ),
              GoRoute(
                path: ':id/invitees',
                builder: (context, state) => InviteePickerScreen(eventId: state.pathParameters['id']!),
              ),
            ],
          ),

          GoRoute(
            path: '/tasks',
            builder: (context, state) => TasksScreen(eventId: state.uri.queryParameters['eventId']),
          ),

          GoRoute(path: '/reports', builder: (context, state) => const ReportsScreen()),

          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
            routes: [
              GoRoute(path: 'security', builder: (context, state) => const SecuritySettingsScreen()),
              GoRoute(path: 'about', builder: (context, state) => const AboutScreen()),
            ],
          ),
        ],
      ),
    ],
  );
});
