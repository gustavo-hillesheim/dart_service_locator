import 'package:service_locator/exceptions.dart';

class ServiceLocator {
  final Map<Type, Object?> _instances = {};
  final Map<Type, Factory?> _factories = {};
  final List<Type> _servicesBeingLocated = [];

  void registerInstance<T extends Object>(T instance) {
    _instances[T] = instance;
  }

  void registerFactory<T extends Object>(
    FactoryFn<T> factoryFn, {
    bool singleton = true,
    bool lazy = true,
  }) {
    final factory = Factory(
      factoryFn: factoryFn,
      isSingleton: singleton,
      isLazy: lazy,
    );
    _factories[T] = factory;
    if (!lazy) {
      _resolveFactory(factory);
    }
  }

  T call<T extends Object>() {
    return locate<T>();
  }

  T locate<T extends Object>() {
    if (_servicesBeingLocated.contains(T)) {
      throw CircularDependencyException<T>([..._servicesBeingLocated, T]);
    }
    _servicesBeingLocated.add(T);
    if (!canLocate<T>()) {
      throw CouldNotLocateException<T>(_servicesBeingLocated);
    }
    final T result;
    if (!_instances.containsKey(T) && _factories.containsKey(T)) {
      result = _resolveFactory(_factories[T] as Factory<T>);
    } else {
      result = _instances[T] as T;
    }
    _servicesBeingLocated.remove(T);
    return result;
  }

  bool canLocate<T extends Object>() {
    return _instances.containsKey(T) || _factories.containsKey(T);
  }

  T _resolveFactory<T extends Object>(Factory<T> factory) {
    final T result;
    if (factory.isSingleton) {
      final instance = factory.factoryFn(this);
      _instances[T] = instance;
      result = instance;
    } else {
      result = factory.factoryFn(this);
    }
    return result;
  }
}

class Factory<T extends Object> {
  final FactoryFn<T> factoryFn;
  final bool isSingleton;
  final bool isLazy;

  Factory({
    required this.factoryFn,
    required this.isSingleton,
    required this.isLazy,
  });
}

typedef FactoryFn<T extends Object> = T Function(ServiceLocator l);
