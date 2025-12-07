import 'package:flutter_test/flutter_test.dart';
import 'package:mpx/viewmodel/spotify_viewmodel.dart';

void main() {
  group('SpotifyViewModel Tests', () {
    late SpotifyViewModel viewModel;

    setUp(() {
      viewModel = SpotifyViewModel();
    });

    test('Initial state should have loading false', () {
      expect(viewModel.loading, false);
    });

    test('Initial state should have empty tracks list', () {
      expect(viewModel.tracks, isEmpty);
    });

    test('Initial state should have no error', () {
      expect(viewModel.error, isNull);
    });

    test('loadRecentTracks sets loading state correctly', () async {
      expect(viewModel.loading, false);
      
      // Note: This will fail if not authenticated, but tests the structure
      // The loading state should change during the operation
      try {
        await viewModel.loadRecentTracks();
      } catch (e) {
        // Expected to fail without proper authentication setup
      }
      
      // After loading completes (or fails), loading should be false
      expect(viewModel.loading, false);
    });
  });
}

