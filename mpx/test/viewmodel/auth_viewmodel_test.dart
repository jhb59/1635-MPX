import 'package:flutter_test/flutter_test.dart';
import 'package:mpx/viewmodel/auth_viewmodel.dart';
import '../mocks/mock_spotify_service.dart';
import 'package:mockito/mockito.dart';

void main() {
  late MockSpotifyService mockService;
  late AuthViewModel viewModel;

  setUp(() {
    mockService = MockSpotifyService();
    viewModel = AuthViewModel(service: mockService);
  });

  test("handleCallback sets login state to true when token exchange succeeds", () async {
    // Arrange
    when(mockService.exchangeCodeForToken("VALID_CODE"))
        .thenAnswer((_) async => true);

    // Act
    await viewModel.handleCallback("VALID_CODE");

    // Assert
    expect(viewModel.isLoggedIn, true);
    verify(mockService.exchangeCodeForToken("VALID_CODE")).called(1);
  });

  test("handleCallback sets login state to false when token exchange fails", () async {
    // Arrange
    when(mockService.exchangeCodeForToken("INVALID_CODE"))
        .thenAnswer((_) async => false);

    // Act
    await viewModel.handleCallback("INVALID_CODE");

    // Assert
    expect(viewModel.isLoggedIn, false);
    verify(mockService.exchangeCodeForToken("INVALID_CODE")).called(1);
  });

  test("login() calls spotify.authenticate()", () async {
    // Arrange
    when(mockService.authenticate()).thenAnswer((_) async => {});

    // Act
    await viewModel.login();

    // Assert
    verify(mockService.authenticate()).called(1);
  });
}
