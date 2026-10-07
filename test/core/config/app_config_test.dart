import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khaata_digital/core/config/app_config.dart';

void main() {
  tearDown(dotenv.clean);

  test('reads trimmed values from .env', () {
    dotenv.loadFromString(
      envString: '''
GOOGLE_SERVER_CLIENT_ID= 123-web.apps.googleusercontent.com
GOOGLE_IOS_CLIENT_ID=123-ios.apps.googleusercontent.com
SUPPORT_EMAIL=help@example.com
''',
    );
    expect(
      AppConfig.googleServerClientId,
      '123-web.apps.googleusercontent.com',
    );
    expect(AppConfig.googleIosClientId, '123-ios.apps.googleusercontent.com');
    expect(AppConfig.supportEmail, 'help@example.com');
  });

  test('missing file or key reads as empty (feature off)', () {
    expect(AppConfig.googleServerClientId, isEmpty, reason: 'not loaded');
    dotenv.loadFromString(envString: 'SUPPORT_EMAIL=');
    expect(AppConfig.supportEmail, isEmpty);
    expect(AppConfig.googleIosClientId, isEmpty);
  });
}
