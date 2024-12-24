import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/main.dart'; // Ensure this points to your actual main.dart file

void main() {
  testWidgets('Login page loads and shows email/password fields', (WidgetTester tester) async {
    // Build the MyApp widget.
    await tester.pumpWidget(MyApp());

    // Verify the presence of email and password text fields on the login screen.
    expect(find.byType(TextField), findsNWidgets(2)); // Two TextFields for email and password
    expect(find.text('Email'), findsOneWidget); // Checking if 'Email' label exists
    expect(find.text('Password'), findsOneWidget); // Checking if 'Password' label exists
    expect(find.text('Login'), findsOneWidget); // Checking for the 'Login' button
  });

  testWidgets('Sign up page navigation and form fields', (WidgetTester tester) async {
    // Build the MyApp widget.
    await tester.pumpWidget(MyApp());

    // Tap on the 'Don't have an account? Sign up' button.
    await tester.tap(find.text('Don\'t have an account? Sign up'));
    await tester.pumpAndSettle(); // Wait for the navigation to complete.

    // Verify that we have navigated to the sign-up screen.
    expect(find.text('Sign Up'), findsOneWidget);

    // Verify the presence of name, email, and password fields on the sign-up screen.
    expect(find.byType(TextField), findsNWidgets(3)); // Three TextFields for name, email, and password
    expect(find.text('Name'), findsOneWidget); // Checking if 'Name' label exists
    expect(find.text('Email'), findsOneWidget); // Checking if 'Email' label exists
    expect(find.text('Password'), findsOneWidget); // Checking if 'Password' label exists
  });

  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build the MyApp widget.
    await tester.pumpWidget(MyApp());

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
