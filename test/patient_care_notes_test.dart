import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clinova/core/auth/auth_config.dart';
import 'package:clinova/core/auth/auth_models.dart';
import 'package:clinova/core/routing/app_routes.dart';
import 'package:clinova/features/dashboard/patient/models/patient_care_note_model.dart';
import 'package:clinova/features/dashboard/patient/screens/patient_care_notes_screen.dart';
import 'package:clinova/features/dashboard/patient/services/patient_care_notes_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PatientCareNote Model Tests', () {
    test('toJson and fromJson serialize and deserialize accurately', () {
      final note = PatientCareNote(
        id: 'note-001',
        text: 'Patient advised to monitor peak flow values every morning.',
        date: DateTime(2025, 3, 14, 10, 30),
        author: 'Dr. Sarah Smith',
        category: 'Follow-up',
      );

      final map = note.toJson();
      final restored = PatientCareNote.fromJson(map);

      expect(restored.id, 'note-001');
      expect(restored.text, 'Patient advised to monitor peak flow values every morning.');
      expect(restored.date, DateTime(2025, 3, 14, 10, 30));
      expect(restored.author, 'Dr. Sarah Smith');
      expect(restored.category, 'Follow-up');
    });

    test('formattedDate formats real dates nicely and returns empty string if null', () {
      final noteWithDate = PatientCareNote(
        id: '1',
        text: 'Regular follow up',
        date: DateTime(2025, 5, 20),
      );
      expect(noteWithDate.formattedDate, '20 May 2025');

      final noteWithoutDate = PatientCareNote(
        id: '2',
        text: 'Observation note',
      );
      expect(noteWithoutDate.formattedDate, '');
    });
  });

  group('PatientCareNotesRepository Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await PatientCareNotesRepository.instance.init();
      await PatientCareNotesRepository.instance.clearNotes();
    });

    test('Initial notes list is empty without fabricating dummy clinical notes', () {
      expect(PatientCareNotesRepository.instance.notes, isEmpty);
      expect(PatientCareNotesRepository.instance.latestNote, isNull);
    });

    test('Adding notes emits to stream and updates latestNote', () async {
      final note1 = PatientCareNote(
        id: 'n1',
        text: 'Note 1',
        date: DateTime(2025, 1, 1),
      );
      final note2 = PatientCareNote(
        id: 'n2',
        text: 'Latest clinical observation',
        date: DateTime(2025, 2, 1),
      );

      await PatientCareNotesRepository.instance.addNote(note1);
      expect(PatientCareNotesRepository.instance.notes.length, 1);
      expect(PatientCareNotesRepository.instance.latestNote?.text, 'Note 1');

      await PatientCareNotesRepository.instance.addNote(note2);
      expect(PatientCareNotesRepository.instance.notes.length, 2);
      // Latest note added is the first in list
      expect(PatientCareNotesRepository.instance.latestNote?.text, 'Latest clinical observation');
    });

    test('Persistence: notes are saved to and loaded from SharedPreferences', () async {
      final note = PatientCareNote(
        id: 'persist-1',
        text: 'Post-consultation follow-up in 2 weeks',
        date: DateTime(2025, 6, 10),
      );

      await PatientCareNotesRepository.instance.saveNotes([note]);

      // Re-init repository to simulate app restart
      await PatientCareNotesRepository.instance.init();
      expect(PatientCareNotesRepository.instance.notes.length, 1);
      expect(PatientCareNotesRepository.instance.notes.first.text, 'Post-consultation follow-up in 2 weeks');
      expect(PatientCareNotesRepository.instance.notes.first.formattedDate, '10 Jun 2025');
    });
  });

  group('Patient Care Notes Dashboard Widget Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await PatientCareNotesRepository.instance.init();
      await PatientCareNotesRepository.instance.clearNotes();

      await AuthConfig.authService.login(
        email: 'test.patient@example.com',
        password: 'password123',
        role: UserRole.patient,
      );
    });

    tearDown(() async {
      await AuthConfig.authService.logout();
    });

    testWidgets('Dashboard renders Patient Care Notes card with empty state when no notes exist',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          routes: AppRoutes.routes,
          initialRoute: AppRoutes.patientDashboard,
        ),
      );
      await tester.pumpAndSettle();

      // Title & Subtitle
      expect(find.text('Patient Care Notes'), findsOneWidget);
      expect(find.text('Important observations and follow-ups'), findsOneWidget);

      // Empty state text
      expect(find.text('Your care notes will appear here.'), findsOneWidget);

      // Verify Quick History is completely absent
      expect(find.text('Quick History'), findsNothing);
      expect(find.text('My Reports'), findsNothing);
    });

    testWidgets('Dashboard displays note preview and real date when note exists',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Seed a note
      await PatientCareNotesRepository.instance.saveNotes([
        PatientCareNote(
          id: 'test-note-1',
          text: 'Patient reported feeling significantly better after starting current regimen. Follow up in 14 days.',
          date: DateTime(2025, 4, 15),
          author: 'Dr. Clara Oswald',
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          routes: AppRoutes.routes,
          initialRoute: AppRoutes.patientDashboard,
        ),
      );
      await tester.pumpAndSettle();

      // Header remains
      expect(find.text('Patient Care Notes'), findsOneWidget);
      expect(find.text('Important observations and follow-ups'), findsOneWidget);

      // Empty state text is absent
      expect(find.text('Your care notes will appear here.'), findsNothing);

      // Note content is rendered
      expect(
        find.textContaining('Patient reported feeling significantly better'),
        findsOneWidget,
      );

      // Real note date is rendered
      expect(find.text('15 Apr 2025'), findsOneWidget);
    });

    testWidgets('Renders properly on mobile layout', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          routes: AppRoutes.routes,
          initialRoute: AppRoutes.patientDashboard,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Patient Care Notes'), findsOneWidget);
      expect(find.text('Important observations and follow-ups'), findsOneWidget);
      expect(find.text('Your care notes will appear here.'), findsOneWidget);
    });

    testWidgets('Tapping Patient Care Notes card (title or empty state) navigates to PatientCareNotesScreen and back returns to dashboard',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          routes: AppRoutes.routes,
          initialRoute: AppRoutes.patientDashboard,
        ),
      );
      await tester.pumpAndSettle();

      // Tap on title text of the card
      await tester.tap(find.text('Patient Care Notes'));
      await tester.pumpAndSettle();

      // Navigated to dedicated PatientCareNotesScreen
      expect(find.byType(PatientCareNotesScreen), findsOneWidget);
      expect(find.text('No care notes yet.'), findsOneWidget);
      expect(find.text('Care Notes & Observations'), findsOneWidget);

      // Back action returns to Patient Dashboard
      final backButton = find.byTooltip('Back to Dashboard');
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Back on dashboard
      expect(find.byType(PatientCareNotesScreen), findsNothing);
      expect(find.text('Start a New Case'), findsOneWidget);

      // Tap on empty state text of the card to verify entire card is clickable
      await tester.tap(find.text('Your care notes will appear here.'));
      await tester.pumpAndSettle();

      expect(find.byType(PatientCareNotesScreen), findsOneWidget);
      expect(find.text('No care notes yet.'), findsOneWidget);

      // Return to dashboard
      await tester.tap(find.byTooltip('Back to Dashboard'));
      await tester.pumpAndSettle();
      expect(find.byType(PatientCareNotesScreen), findsNothing);
    });

    testWidgets('Tapping populated Patient Care Notes card navigates to PatientCareNotesScreen displaying saved notes with real dates',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Seed 2 notes
      await PatientCareNotesRepository.instance.saveNotes([
        PatientCareNote(
          id: 'note-1',
          text: 'Patient advised to continue inhaler twice daily.',
          date: DateTime(2025, 7, 20),
          author: 'Dr. Clara Oswald',
          category: 'Follow-up',
        ),
        PatientCareNote(
          id: 'note-2',
          text: 'Blood pressure readings stable at 120/80 mmHg.',
          date: DateTime(2025, 7, 10),
          author: 'Dr. Marcus Vance',
          category: 'Routine Checkup',
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          routes: AppRoutes.routes,
          initialRoute: AppRoutes.patientDashboard,
        ),
      );
      await tester.pumpAndSettle();

      // Note text is displayed on dashboard preview
      final noteFinder = find.textContaining('Patient advised to continue inhaler');
      expect(noteFinder, findsOneWidget);

      // Tap note preview area of the card
      await tester.tap(noteFinder);
      await tester.pumpAndSettle();

      // Opens PatientCareNotesScreen
      expect(find.byType(PatientCareNotesScreen), findsOneWidget);

      // Verify both notes are shown
      expect(find.text('Patient advised to continue inhaler twice daily.'), findsOneWidget);
      expect(find.text('Blood pressure readings stable at 120/80 mmHg.'), findsOneWidget);

      // Verify authors, categories, and real dates
      expect(find.text('Dr. Clara Oswald'), findsOneWidget);
      expect(find.text('Dr. Marcus Vance'), findsOneWidget);
      expect(find.text('Follow-up'), findsOneWidget);
      expect(find.text('Routine Checkup'), findsOneWidget);
      expect(find.text('20 Jul 2025'), findsOneWidget);
      expect(find.text('10 Jul 2025'), findsOneWidget);

      // Back action returns to Patient Dashboard
      await tester.tap(find.byTooltip('Back to Dashboard'));
      await tester.pumpAndSettle();
      expect(find.byType(PatientCareNotesScreen), findsNothing);
    });
  });
}
