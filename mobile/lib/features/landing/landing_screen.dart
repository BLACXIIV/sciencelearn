import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/icons.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

/// Public welcome screen — mirrors the web landing page's content.
/// Logged-in users never reach this (router redirects them home).
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  static const _features = [
    (AppEmoji.lessons, 'Lessons & Materials',
        'Topic lessons with objectives and downloadable materials, aligned to the DepEd MATATAG curriculum.'),
    (AppEmoji.assessment, 'Assessments',
        'Pre-tests, post-tests and quizzes in five formats: multiple choice, true or false, fill in the blank, identification and enumeration.'),
    (AppEmoji.review, 'Review Center',
        'Flashcards, formula guides and key terms to revise before any assessment.'),
    (AppEmoji.progress, 'Progress Tracking',
        'Students see completion and scores over time; teachers see the whole class at a glance.'),
    (AppEmoji.school, 'Classes',
        'Teachers create classes with auto-generated join codes. Students enter a code and they are in.'),
    (AppEmoji.account, 'Portals for Every Role',
        'One sign-in for students, teachers and admins, on both the mobile app and the web portal.'),
  ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [AppColors.bg, AppColors.surface2],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(children: [
                  const EmojiIcon(AppEmoji.science, size: 88),
                  const SizedBox(height: 12),
                  Text('ScienceLearn',
                      style: text.displaySmall?.copyWith(fontWeight: FontWeight.w800)),
                  Text('Learn · Explore · Excel',
                      style: text.titleMedium?.copyWith(color: AppColors.blue)),
                  const SizedBox(height: 12),
                  Text(
                    'A science learning system for the DepEd MATATAG curriculum, with lessons, assessments, review tools and class management, on mobile and web.',
                    textAlign: TextAlign.center,
                    style: text.bodyMedium?.copyWith(color: AppColors.muted, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    alignment: WrapAlignment.center, spacing: 10, runSpacing: 10,
                    children: [
                      FilledButton.icon(
                        onPressed: () => context.push('/login'),
                        icon: const Icon(AppIcons.login, size: 18),
                        label: const Text('Sign in'),
                        style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
                      ),
                      OutlinedButton(
                        onPressed: () => context.push('/signup'),
                        style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
                        child: const Text('Create an account'),
                      ),
                    ]),
                  const SizedBox(height: 28),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Everything in one system',
                        style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 10),
                  for (final f in _features)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          EmojiIcon(f.$1, size: 40),
                          const SizedBox(width: 14),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(f.$2, style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(f.$3,
                                style: text.bodySmall
                                    ?.copyWith(color: AppColors.muted, height: 1.5)),
                          ])),
                        ]),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    'Developed by Regym R. Medina · With the support of The Notre Dame of Isulan, Inc.',
                    textAlign: TextAlign.center,
                    style: text.bodySmall?.copyWith(color: AppColors.muted),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
