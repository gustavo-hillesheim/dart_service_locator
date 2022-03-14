class CouldNotLocateException<T> implements Exception {
  final String message;
  final List<Type> typeStack;

  CouldNotLocateException(this.typeStack)
      : message =
            'Could not locate instance of type "$T". This means that you tried to locate a type that was not registered' +
                (typeStack.length > 1
                    ? ', check the following stack to discover how this occurred: \n${_typeStackAsString(typeStack)}'
                    : '');

  @override
  String toString() {
    return message;
  }
}

class CircularDependencyException<T> implements Exception {
  final String message;
  final List<Type> typeStack;

  CircularDependencyException(this.typeStack)
      : message = 'A circular dependency was found when resolving "$T". '
            'This means that a service required by "$T" requires "$T", '
            'check the following stack to discover how this occurred: \n${_typeStackAsString(typeStack)}';

  @override
  String toString() {
    return message;
  }
}

String _typeStackAsString(List<Type> typeStack) {
  if (typeStack.length < 2) {
    return '';
  }
  String stackAsString = '';
  for (int i = 1; i < typeStack.length; i++) {
    final previousType = typeStack[i - 1];
    final currentType = typeStack[i];
    stackAsString += '-> $previousType tried to locate $currentType\n';
  }
  return stackAsString;
}

class TriedToExecuteAsyncFactoryInSyncMethodException implements Exception {
  final String message;
  final List<Type> typeStack;

  TriedToExecuteAsyncFactoryInSyncMethodException(this.typeStack)
      : message = 'A call to an async factory was found when trying to resolve a dependency synchronously. '
            'Check the following stack to discover how this occurred:  \n${_typeStackAsString(typeStack)}';

  @override
  String toString() {
    return message;
  }
}
