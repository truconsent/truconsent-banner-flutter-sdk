/// Unit tests for RequestIdGenerator (UUID generation)
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

void main() {
  group('RequestIdGenerator', () {
    test('should generate valid UUID v4', () {
      const uuid = Uuid();
      final requestId = uuid.v4();
      
      // UUID v4 format: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
      final uuidRegex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        caseSensitive: false,
      );
      
      expect(uuidRegex.hasMatch(requestId), true);
    });

    test('should generate unique UUIDs', () {
      const uuid = Uuid();
      final id1 = uuid.v4();
      final id2 = uuid.v4();
      
      expect(id1, isNot(id2));
    });

    test('should generate UUID with correct length', () {
      const uuid = Uuid();
      final requestId = uuid.v4();
      
      // UUID string length: 36 characters (32 hex + 4 hyphens)
      expect(requestId.length, 36);
    });
  });
}

