import 'package:service_locator/exceptions.dart';
import 'package:service_locator/service_locator.dart';
import 'package:test/test.dart';

void main() {
  late ServiceLocator locator;

  setUp(() {
    locator = ServiceLocator();
  });

  group('registerInstance', () {
    test('SHOULD register instance of object', () {
      final instance = ClassA();

      locator.registerInstance(instance);

      expect(locator.canLocate<ClassA>(), true);
      expect(locator.locate<ClassA>(), same(instance));
    });
  });

  group('registerFactory', () {
    test('SHOULD register factory of type', () {
      locator.registerFactory((_) => ClassA());

      expect(locator.canLocate<ClassA>(), true);
      expect(locator.locate<ClassA>(), isA<ClassA>());
    });

    test('WHEN lazy factory is registered SHOULD only call when a locate is requested', () {
      var executedFactory = false;
      locator.registerFactory((l) {
        executedFactory = true;
        return ClassA();
      });

      expect(executedFactory, false);
      locator.locate<ClassA>();
      expect(executedFactory, true);
    });

    test('WHEN registering a non-lazy factory SHOULD instantly execute the factory', () {
      var executedFactory = false;
      locator.registerFactory(
        (l) {
          executedFactory = true;
          return ClassA();
        },
        lazy: false,
      );

      expect(executedFactory, true);
    });
  });

  group('canLocate', () {
    test('WHEN type is registered using instance SHOULD return true', () {
      locator.registerInstance(ClassA());

      expect(locator.canLocate<ClassA>(), true);
    });

    test('WHEN type is registered using factory SHOULD return true', () {
      locator.registerFactory((l) => ClassA());

      expect(locator.canLocate<ClassA>(), true);
    });

    test('WHEN type is not registered SHOULD return false', () {
      expect(locator.canLocate<ClassA>(), false);
    });
  });

  group('locate', () {
    test('WHEN instance is registered SHOULD return instance', () {
      final instance = ClassA();

      locator.registerInstance(instance);

      expect(locator.locate<ClassA>(), instance);
    });

    test('WHEN locating using a singleton factory SHOULD cache the instance returned', () {
      locator.registerFactory((_) => ClassA());

      expect(locator.locate<ClassA>(), same(locator.locate<ClassA>()));
    });

    test('WHEN locating using a non-singleton factory SHOULD return different instances', () {
      locator.registerFactory((l) => ClassA(), singleton: false);

      expect(locator.locate<ClassA>(), isNot(same(locator.locate<ClassA>())));
    });

    test('WHEN locating using a non-lazy non-singleton factory SHOULD return different instances', () {
      locator.registerFactory(
        (l) => ClassA(),
        singleton: false,
        lazy: false,
      );

      expect(locator.locate<ClassA>(), isNot(same(locator.locate<ClassA>())));
    });

    test('WHEN instance is not registered SHOULD throw CouldNotLocateException', () {
      try {
        locator.locate<ClassA>();
        fail('Should have thrown exception');
      } catch (e) {
        print(e);
        expect(e, isA<CouldNotLocateException<ClassA>>());
      }
    });

    test('WHEN nested factory is not registered SHOULD throw CouldNotLocateException', () {
      locator.registerFactory((l) => ClassB(l()));
      try {
        locator.locate<ClassB>();
        fail('Should have thrown exception');
      } catch (e) {
        print(e);
        expect(e, isA<CouldNotLocateException<ClassC>>());
      }
    });

    test('WHEN resolving circular dependencies SHOULD throw CircularDependencyException', () {
      locator.registerFactory((l) => ClassB(l()));
      locator.registerFactory((l) => ClassC(l()));

      try {
        locator.locate<ClassB>();
        fail('Should have thrown exception');
      } catch (e) {
        print(e);
        expect(e, isA<CircularDependencyException<ClassB>>());
      }
    });
  });
}

class ClassA {}

class ClassB {
  final ClassC c;

  ClassB(this.c);
}

class ClassC {
  final ClassB b;

  ClassC(this.b);
}
