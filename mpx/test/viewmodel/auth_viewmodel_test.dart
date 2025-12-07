import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:mpx/viewmodel/auth_viewmodel.dart';
import 'package:mpx/services/auth_service.dart';

import 'auth_viewmodel_test.mocks.dart';

@GenerateMocks([AuthService])
void main() {
  late AuthViewModel viewModel;
  late MockAuthService mockAuthService;

  setUp(() {
    mockAuthService = MockAuthService();
    viewModel = AuthViewModel.test(mockAuthService); // <-- SEE STEP 3
  });

  test('Initial state should NOT be authenticated', () {
    expect(viewModel.isAuthenticated, false);
  });

  test('handleCallback authenticates user', () async {
    when(mockAuthService.handleCallback("123"))
      .thenAnswer((_) async {});

    await viewModel.handleCallback("123");

    expect(viewModel.isAuthenticated, true);
  });
}
