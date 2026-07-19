import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/app_settings.dart';
import '../data/models/category.dart';
import '../data/models/event.dart';
import '../data/models/invitee.dart';
import '../data/models/person.dart';
import '../data/models/task.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/categories_repository.dart';
import '../data/repositories/events_repository.dart';
import '../data/repositories/invitees_repository.dart';
import '../data/repositories/people_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/tasks_repository.dart';
import '../data/services/notifications_service.dart';

// ---------------------------------------------------------------------------
// Repositories (stateless singletons)
// ---------------------------------------------------------------------------
final categoriesRepoProvider = Provider((ref) => CategoriesRepository());
final peopleRepoProvider = Provider((ref) => PeopleRepository());
final eventsRepoProvider = Provider((ref) => EventsRepository());
final inviteesRepoProvider = Provider((ref) => InviteesRepository());
final tasksRepoProvider = Provider((ref) => TasksRepository());
final settingsRepoProvider = Provider((ref) => SettingsRepository());
final authRepoProvider = Provider((ref) => AuthRepository());

// ---------------------------------------------------------------------------
// Categories
// ---------------------------------------------------------------------------
class CategoriesNotifier extends AsyncNotifier<List<Category>> {
  @override
  Future<List<Category>> build() => ref.read(categoriesRepoProvider).getAll();

  Future<void> refresh() async => state = await AsyncValue.guard(() => ref.read(categoriesRepoProvider).getAll());

  Future<void> add({required String name, required String icon, required int colorIndex}) async {
    await ref.read(categoriesRepoProvider).create(name: name, icon: icon, colorIndex: colorIndex);
    await refresh();
  }

  Future<void> updateCategory(Category category) async {
    await ref.read(categoriesRepoProvider).update(category);
    await refresh();
  }

  Future<void> remove(String id) async {
    await ref.read(categoriesRepoProvider).delete(id);
    await refresh();
  }
}

final categoriesProvider = AsyncNotifierProvider<CategoriesNotifier, List<Category>>(CategoriesNotifier.new);

final categoryPeopleCountProvider = FutureProvider((ref) => ref.read(categoriesRepoProvider).peopleCountByCategory());

// ---------------------------------------------------------------------------
// People
// ---------------------------------------------------------------------------
class PeopleNotifier extends AsyncNotifier<List<Person>> {
  @override
  Future<List<Person>> build() => ref.read(peopleRepoProvider).getAll();

  Future<void> refresh() async => state = await AsyncValue.guard(() => ref.read(peopleRepoProvider).getAll());

  Future<Person> add(Person draft) async {
    final created = await ref.read(peopleRepoProvider).create(draft);
    if (created.birthday != null) {
      await NotificationsService.scheduleBirthdayReminder(created);
    }
    await refresh();
    return created;
  }

  Future<void> updatePerson(Person person) async {
    await ref.read(peopleRepoProvider).update(person);
    if (person.birthday != null) {
      await NotificationsService.scheduleBirthdayReminder(person);
    } else {
      await NotificationsService.cancelBirthdayReminder(person.id);
    }
    await refresh();
  }

  Future<void> remove(String id) async {
    await ref.read(peopleRepoProvider).delete(id);
    await NotificationsService.cancelBirthdayReminder(id);
    await refresh();
  }

  Future<void> toggleFavorite(String id, bool value) async {
    await ref.read(peopleRepoProvider).toggleFavorite(id, value);
    await refresh();
  }

  /// Merges a detected duplicate into the kept record and refreshes the list.
  /// See [PeopleRepository.mergeInto] for exactly what moves over.
  Future<void> mergeInto({required String keepId, required String removeId}) async {
    await ref.read(peopleRepoProvider).mergeInto(keepId: keepId, removeId: removeId);
    await NotificationsService.cancelBirthdayReminder(removeId);
    await refresh();
  }
}

final peopleProvider = AsyncNotifierProvider<PeopleNotifier, List<Person>>(PeopleNotifier.new);

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------
class EventsNotifier extends AsyncNotifier<List<EventItem>> {
  @override
  Future<List<EventItem>> build() => ref.read(eventsRepoProvider).getAll();

  Future<void> refresh() async => state = await AsyncValue.guard(() => ref.read(eventsRepoProvider).getAll());

  Future<EventItem> add(EventItem draft) async {
    final created = await ref.read(eventsRepoProvider).create(draft);
    await NotificationsService.scheduleEventReminders(created);
    await refresh();
    return created;
  }

  Future<void> updateEvent(EventItem event) async {
    await ref.read(eventsRepoProvider).update(event);
    await NotificationsService.scheduleEventReminders(event);
    await refresh();
  }

  Future<void> remove(String id) async {
    await ref.read(eventsRepoProvider).delete(id);
    await NotificationsService.cancelEventReminders(id);
    await refresh();
  }

  Future<void> duplicate(EventItem source) async {
    final copy = await ref.read(eventsRepoProvider).duplicate(source);
    await NotificationsService.scheduleEventReminders(copy);
    await refresh();
  }
}

final eventsProvider = AsyncNotifierProvider<EventsNotifier, List<EventItem>>(EventsNotifier.new);

// ---------------------------------------------------------------------------
// Invitees (scoped per event id via a family provider)
// ---------------------------------------------------------------------------
class InviteesNotifier extends FamilyAsyncNotifier<List<Invitee>, String> {
  @override
  Future<List<Invitee>> build(String eventId) => ref.read(inviteesRepoProvider).getByEvent(eventId);

  Future<void> refresh() async {
    state = await AsyncValue.guard(() => ref.read(inviteesRepoProvider).getByEvent(arg));
  }

  Future<void> setSelected(
    Set<String> personIds,
    Map<String, int> companionsByPersonId, {
    Map<String, RsvpStatus> statusByPersonId = const {},
  }) async {
    final repo = ref.read(inviteesRepoProvider);
    final current = await repo.getByEvent(arg);

    for (final personId in personIds) {
      await repo.upsert(
        eventId: arg,
        personId: personId,
        companions: companionsByPersonId[personId] ?? 1,
        rsvpStatus: statusByPersonId[personId] ?? RsvpStatus.pending,
      );
    }
    for (final inv in current) {
      if (!personIds.contains(inv.personId)) await repo.remove(arg, inv.personId);
    }
    await refresh();
  }

  Future<void> updateStatus(String inviteeId, RsvpStatus status) async {
    await ref.read(inviteesRepoProvider).updateStatus(inviteeId, status);
    await refresh();
  }

  Future<void> updateCompanions(String inviteeId, int companions) async {
    await ref.read(inviteesRepoProvider).updateCompanions(inviteeId, companions);
    await refresh();
  }
}

final inviteesProvider =
    AsyncNotifierProvider.family<InviteesNotifier, List<Invitee>, String>(InviteesNotifier.new);

/// Every invitee row across all events — used by Home/Reports for
/// app-wide attendance totals.
final allInviteesProvider = FutureProvider((ref) => ref.read(inviteesRepoProvider).getAll());

// ---------------------------------------------------------------------------
// Tasks
// ---------------------------------------------------------------------------
class TasksNotifier extends AsyncNotifier<List<TaskItem>> {
  @override
  Future<List<TaskItem>> build() => ref.read(tasksRepoProvider).getAll();

  Future<void> refresh() async => state = await AsyncValue.guard(() => ref.read(tasksRepoProvider).getAll());

  Future<void> add(TaskItem draft) async {
    await ref.read(tasksRepoProvider).create(draft);
    await refresh();
  }

  Future<void> updateTask(TaskItem task) async {
    await ref.read(tasksRepoProvider).update(task);
    await refresh();
  }

  Future<void> remove(String id) async {
    await ref.read(tasksRepoProvider).delete(id);
    await refresh();
  }

  Future<void> reorder(List<TaskItem> ordered) async {
    await ref.read(tasksRepoProvider).reorder(ordered);
    await refresh();
  }
}

final tasksProvider = AsyncNotifierProvider<TasksNotifier, List<TaskItem>>(TasksNotifier.new);

// ---------------------------------------------------------------------------
// Settings (theme, locale, accent color, security, onboarding)
// ---------------------------------------------------------------------------
class SettingsNotifier extends AsyncNotifier<AppSettingsModel> {
  @override
  Future<AppSettingsModel> build() => ref.read(settingsRepoProvider).get();

  Future<void> _save(AppSettingsModel next) async {
    await ref.read(settingsRepoProvider).save(next);
    state = AsyncValue.data(next);
  }

  Future<void> setThemeMode(String mode) async {
    final current = state.valueOrNull ?? const AppSettingsModel();
    await _save(current.copyWith(themeMode: mode));
  }

  Future<void> setLanguage(String language) async {
    final current = state.valueOrNull ?? const AppSettingsModel();
    await _save(current.copyWith(language: language));
  }

  Future<void> setAccentColor(int colorValue) async {
    final current = state.valueOrNull ?? const AppSettingsModel();
    await _save(current.copyWith(accentColorValue: colorValue));
  }

  Future<void> setOnboardingSeen(bool value) async {
    final current = state.valueOrNull ?? const AppSettingsModel();
    await _save(current.copyWith(onboardingSeen: value));
  }

  Future<void> setLock({required bool enabled, String? pinHash}) async {
    final current = state.valueOrNull ?? const AppSettingsModel();
    await _save(current.copyWith(lockEnabled: enabled, pinHash: pinHash ?? current.pinHash));
  }

  Future<void> setBiometric(bool enabled) async {
    final current = state.valueOrNull ?? const AppSettingsModel();
    await _save(current.copyWith(biometricEnabled: enabled));
  }
}

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, AppSettingsModel>(SettingsNotifier.new);

// ---------------------------------------------------------------------------
// Auth session
// ---------------------------------------------------------------------------
class AuthNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => ref.read(authRepoProvider).isLoggedIn();

  Future<void> signIn(String name) async {
    await ref.read(authRepoProvider).signIn(name);
    state = const AsyncValue.data(true);
  }

  Future<void> signOut() async {
    await ref.read(authRepoProvider).signOut();
    state = const AsyncValue.data(false);
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, bool>(AuthNotifier.new);

/// The user's saved display name (captured on the welcome/onboarding flow),
/// used to greet them by name on the home screen.
final displayNameProvider = FutureProvider<String?>((ref) {
  ref.watch(authProvider); // refresh after sign-in
  return ref.read(authRepoProvider).displayName();
});

// ---------------------------------------------------------------------------
// UI-only ephemeral state
// ---------------------------------------------------------------------------
final peopleSearchQueryProvider = StateProvider<String>((ref) => '');
final peopleFilterProvider = StateProvider<String>((ref) => 'all'); // all | favorite | category
final peopleFilterCategoryProvider = StateProvider<String?>((ref) => null); // used when peopleFilterProvider == 'category'
final categorySearchQueryProvider = StateProvider<String>((ref) => '');
final eventsFilterProvider = StateProvider<String>((ref) => 'all'); // all | upcoming | ongoing | finished
final selectedReportMonthProvider = StateProvider<DateTime>((ref) => DateTime.now());
