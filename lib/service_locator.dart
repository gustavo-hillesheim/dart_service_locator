import 'package:service_locator/exceptions.dart';

class ServiceLocator {
  final Map<Type, Object?> _instances = {};
  final Map<Type, _Factory?> _factories = {};
  final List<Type> _servicesBeingLocated = [];

  void registerInstance<T extends Object>(T instance) {
    _instances[T] = instance;
  }

  void registerFactory<T extends Object>(
    FactoryFn<T> factoryFn, {
    bool singleton = true,
    bool lazy = true,
  }) {
    final factory = _Factory(
      factoryFn: factoryFn,
      isSingleton: singleton,
      isLazy: lazy,
    );
    _factories[T] = factory;
    if (!lazy && singleton) {
      _instances[T] = _resolveFactory(factory);
    }
  }

  T call<T extends Object>() {
    return locate<T>();
  }

  T locate<T extends Object>() {
    _checkIsNotBeingLocated<T>();
    _servicesBeingLocated.add(T);
    _checkCanBeLocated<T>();
    final locatedService = (_locateInInstances<T>() ?? _locateInFactories<T>())!;
    if (locatedService.shouldCache) {
      _instances[T] = locatedService.instance;
    }
    _servicesBeingLocated.remove(T);
    return locatedService.instance;
  }

  _LocatedService<T>? _locateInInstances<T extends Object>() {
    final instance = _instances[T] as T?;
    if (instance == null) {
      return null;
    }
    return _LocatedService(instance: instance, shouldCache: true);
  }

  _LocatedService<T>? _locateInFactories<T extends Object>() {
    final factory = _factories[T] as _Factory<T>?;
    if (factory == null) {
      return null;
    }
    return _LocatedService(
      instance: _resolveFactory(factory),
      shouldCache: factory.isSingleton,
    );
  }

  void _checkIsNotBeingLocated<T extends Object>() {
    if (_servicesBeingLocated.contains(T)) {
      throw CircularDependencyException<T>([..._servicesBeingLocated, T]);
    }
  }

  void _checkCanBeLocated<T extends Object>() {
    if (!canLocate<T>()) {
      throw CouldNotLocateException<T>(_servicesBeingLocated);
    }
  }

  bool canLocate<T extends Object>() {
    return _instances.containsKey(T) || _factories.containsKey(T);
  }

  T _resolveFactory<T extends Object>(_Factory<T> factory) {
    return factory.factoryFn(this);
  }
}

class _LocatedService<T> {
  final T instance;
  final bool shouldCache;

  _LocatedService({required this.instance, required this.shouldCache});
}

class _Factory<T extends Object> {
  final FactoryFn<T> factoryFn;
  final bool isSingleton;
  final bool isLazy;

  _Factory({
    required this.factoryFn,
    required this.isSingleton,
    required this.isLazy,
  });
}

typedef FactoryFn<T extends Object> = T Function(ServiceLocator l);
