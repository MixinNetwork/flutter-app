import 'package:flutter_app/ui/provider/mention_cache_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('replaceMention preserves empty content', () {
    final mentionCache = MentionCache(null);

    expect(mentionCache.replaceMention('', {}), '');
  });
}
