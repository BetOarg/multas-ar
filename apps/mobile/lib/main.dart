import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit/ui_kit.dart';

void main() {
  runApp(const ProviderScope(child: MultasArApp()));
}

class MultasArApp extends StatelessWidget {
  const MultasArApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Multas AR',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚖️ Multas AR'),
        backgroundColor: AppTheme.surface,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '⚖️',
                style: TextStyle(fontSize: 64),
              ),
              const SizedBox(height: 16),
              Text(
                'Multas AR',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.text,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Asistente legal de infracciones de tránsito',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Text(
                  '🚧 Fase 1 en construcción\n\n'
                  'El MVP estará disponible próximamente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.text, height: 1.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}