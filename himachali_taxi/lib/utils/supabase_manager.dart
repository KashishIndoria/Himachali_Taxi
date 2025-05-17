import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

class SupabaseManager {
  static SupabaseManager? _instance;
  static SupabaseClient? _client;

  // Private constructor
  SupabaseManager._();

  // Singleton instance getter
  static SupabaseManager get instance {
    _instance ??= SupabaseManager._();
    return _instance!;
  }

  // Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://gbgjozxbypjojgumobgw.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdiZ2pvenhieXBqb2pndW1vYmd3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDMwNjM3MjIsImV4cCI6MjA1ODYzOTcyMn0.txlNsKomj68eA7PA_W41ovSyMI89Rev8NL-aYP50cwI',
    );
    _client = Supabase.instance.client;
  }

  // Get Supabase client
  static SupabaseClient get client {
    if (_client == null) {
      throw Exception(
          'Supabase client not initialized. Call initialize() first.');
    }
    return _client!;
  }

  static Future<String> uploadImage(File imageFile) async {
    await initialize();

    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
      final filePath = 'profile_images/$fileName';

      print('Uploading image to Supabase: $filePath');

      await client.storage.from('profile-pics').upload(filePath, imageFile);

      final imageUrl =
          client.storage.from('profile-pics').getPublicUrl(filePath);

      // Ensure URL has proper scheme
      final completeUrl = imageUrl.startsWith('http')
          ? imageUrl
          : 'https://gbgjozxbypjojgumobgw.supabase.co$imageUrl';

      print('Image uploaded successfully: $completeUrl');

      return completeUrl;
    } catch (error) {
      print('Error uploading to Supabase: $error');
      rethrow;
    }
  }
}
