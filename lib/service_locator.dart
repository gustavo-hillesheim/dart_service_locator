import 'exceptions.dart';

abstract class Locator {
  T call<T extends Object>() {
    return locate<T>();
  }

  T locate<T extends Object>();
  bool canLocate<T extends Object>();
}

class ServiceLocator extends Locator {
  final Map<Type, Object?> _instances = {};
  final Map<Type, _Factory?> _factories = {};
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
      _instances[T] = _createLocateDelegate()._resolveFactory(factory);
    }
  }

  @override
  T locate<T extends Object>() {
    return _createLocateDelegate().locate<T>();
  }

  @override
  bool canLocate<T extends Object>() {
    return _createLocateDelegate().canLocate<T>();
  }

  _LocateDeletage _createLocateDelegate() {
    return _LocateDeletage(instances: _instances, factories: _factories);
  }
}

class _LocateDeletage extends Locator {
  final Map<Type, Object?> instances;
  final Map<Type, _Factory?> factories;
  final List<Type> servicesBeingLocated = [];

  _LocateDeletage({required this.instances, required this.factories});

  @override
  T locate<T extends Object>() {
    _checkIsNotBeingLocated<T>();
    servicesBeingLocated.add(T);
    _checkCanBeLocated<T>();
    final locatedService = (_locateInInstances<T>() ?? _locateInFactories<T>())!;
    if (locatedService.shouldCache) {
      instances[T] = locatedService.instance;
    }
    servicesBeingLocated.remove(T);
    return locatedService.instance;
  }

  @override
  bool canLocate<T extends Object>() {
    return instances.containsKey(T) || factories.containsKey(T);
  }

  _LocatedService<T>? _locateInInstances<T extends Object>() {
    final instance = instances[T] as T?;
    if (instance == null) {
      return null;
    }
    return _LocatedService(instance: instance, shouldCache: true);
  }

  _LocatedService<T>? _locateInFactories<T extends Object>() {
    final factory = factories[T] as _Factory<T>?;
    if (factory == null) {
      return null;
    }
    return _LocatedService(
      instance: _resolveFactory(factory),
      shouldCache: factory.isSingleton,
    );
  }

  void _checkIsNotBeingLocated<T extends Object>() {
    if (servicesBeingLocated.contains(T)) {
      throw CircularDependencyException<T>([...servicesBeingLocated, T]);
    }
  }

  void _checkCanBeLocated<T extends Object>() {
    if (!canLocate<T>()) {
      throw CouldNotLocateException<T>(servicesBeingLocated);
    }
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

typedef FactoryFn<T extends Object> = T Function(Locator l);
