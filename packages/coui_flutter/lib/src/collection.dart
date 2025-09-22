void mutateSeparated<T>(List<T> separatedList, T separator, List<T> source) {
  int targetIndex = 0; // Position in separatedList we're modifying

  for (int i = 0; i < source.length; i += 1) {
    // Update or add source element
    if (targetIndex < separatedList.length) {
      separatedList[targetIndex] = source[i];
    } else {
      separatedList.add(source[i]);
    }
    targetIndex += 1;

    // Update or add separator if not the last element
    if (i < source.length - 1) {
      if (targetIndex < separatedList.length) {
        separatedList[targetIndex] = separator;
      } else {
        separatedList.add(separator);
      }
      targetIndex += 1;
    }
  }

  // Remove extra elements if separatedList is too long
  if (targetIndex < separatedList.length) {
    separatedList.removeRange(targetIndex, separatedList.length);
  }
}

class SeparatedIterable<T> extends Iterable<T> {
  const SeparatedIterable(this._iterable, this._separator);

  final Iterable<T> _iterable;

  final T _separator;

  @override
  Iterator<T> get iterator => SeparatedIterator(_iterable.iterator, _separator);
}

class SeparatedIterator<T> implements Iterator<T> {
  SeparatedIterator(this._iterator, this._separator);

  final Iterator<T> _iterator;
  final T _separator;
  T? _current;
  bool _isSeparator = false;

  bool? _hasNextAfterSeparator;

  @override
  T get current => _current!;

  @override
  bool moveNext() {
    final hasNextAfterSeparator = _hasNextAfterSeparator;
    if (_isSeparator) {
      if (hasNextAfterSeparator != null) {
        _isSeparator = false;
        _hasNextAfterSeparator = null;
        if (hasNextAfterSeparator) {
          _current = _iterator.current;
          _isSeparator = true;
        }

        return hasNextAfterSeparator;
      }
      _hasNextAfterSeparator = _iterator.moveNext();
      if (_hasNextAfterSeparator!) {
        _current = _separator;

        return true;
      }

      return false;
    }
    final moveNext = _iterator.moveNext();
    if (moveNext) {
      _current = _iterator.current;
      _isSeparator = true;
    }

    return moveNext;
  }
}
