class ResizableItem {
  ResizableItem({
    this.collapsed = false,
    this.collapsedSize,
    this.max = double.infinity,
    this.min = 0,
    this.resizable = true,
    required double value,
  }) : _value = value;

  final double min;
  final double max;
  final bool collapsed;
  final double? collapsedSize;
  final bool resizable;
  double _value;
  double? _newValue;

  bool? _newCollapsed;

  bool get newCollapsed => _newCollapsed ?? collapsed;

  double get newValue {
    return _newValue ?? _value;
  }

  double get value {
    return _value;
  }

  @override
  String toString() {
    return 'ResizableItem(value: $value, min: $min, max: $max)';
  }
}

class _BorrowInfo {
  const _BorrowInfo(this.from, this.givenSize);
  final double givenSize;

  final int from;
}

class Resizer {
  Resizer(
    this.items, {
    this.collapseRatio = 0.5, // half of min size
    this.expandRatio = 0.5, // half of max size
  });

  final List<ResizableItem> items;
  final double collapseRatio;
  final double expandRatio;

  double _couldNotBorrow = 0;

  bool attemptExpand(double delta, int direction, int index) {
    final item = items[index];
    final currentSize = item.newValue; // check
    final minSize = item.min;
    final maxSize = item.max;
    final newSize = currentSize + delta;
    final minOverflow = newSize - minSize;
    final maxOverflow = newSize - maxSize;

    if (minOverflow < 0 && delta < 0) {
      delta -= minOverflow;
    }

    if (maxOverflow > 0 && delta > 0) {
      delta -= maxOverflow;
    }

    if (delta == 0) {
      return false;
    }

    if (index == 0) {
      direction = 1;
    } else if (index == items.length - 1) {
      direction = -1;
    }
    if (direction < 0) {
      final borrowed = _borrowSize(index - 1, -delta, 0, -1);
      if (borrowed.givenSize != -delta) {
        reset();

        return false;
      }
      item._newValue = (item.newValue + delta).clamp(minSize, maxSize);

      // check
      return true;
    } else if (direction > 0) {
      final borrowed = _borrowSize(index + 1, -delta, items.length - 1, 1);
      if (borrowed.givenSize != -delta) {
        reset();

        return false;
      }
      item._newValue = (item.newValue + delta).clamp(minSize, maxSize);

      // check
      return true;
    } else if (direction == 0) {
      final halfDelta = delta / 2;
      final borrowedLeft = _borrowSize(index - 1, -halfDelta, 0, -1);
      final borrowedRight =
          _borrowSize(index + 1, -halfDelta, items.length - 1, 1);
      if (borrowedLeft.givenSize != -halfDelta ||
          borrowedRight.givenSize != -halfDelta) {
        reset();

        return false;
      }
      item._newValue = (item.newValue + delta).clamp(minSize, maxSize);

      // check
      return true;
    }

    return false;
  }

  bool attemptCollapse(int direction, int index) {
    if (index == 0) {
      direction = 1;
    } else if (index == items.length - 1) {
      direction = -1;
    }
    if (direction < 0) {
      final item = items[index];
      final collapsedSize = item.collapsedSize ?? 0;
      final currentSize = item.newValue;
      final delta = currentSize - collapsedSize;
      final borrowed = _borrowSize(index - 1, delta, 0, -1);
      if (borrowed.givenSize != delta) {
        reset();

        return false;
      }
      item._newCollapsed = true;

      return true;
    } else if (direction > 0) {
      final item = items[index];
      final collapsedSize = item.collapsedSize ?? 0;
      final delta = item.newValue - collapsedSize;
      final borrowed = _borrowSize(index + 1, delta, items.length - 1, 1);
      if (borrowed.givenSize != delta) {
        reset();

        return false;
      }
      item._newCollapsed = true;

      return true;
    } else if (direction == 0) {
      final item = items[index];
      final collapsedSize = item.collapsedSize ?? 0;
      final delta = item.newValue - collapsedSize;
      final halfDelta = delta / 2;
      final borrowedLeft = _borrowSize(index - 1, halfDelta, 0, -1);
      final borrowedRight =
          _borrowSize(index + 1, halfDelta, items.length - 1, 1);
      if (borrowedLeft.givenSize != halfDelta ||
          borrowedRight.givenSize != halfDelta) {
        reset();

        return false;
      }
      item._newCollapsed = true;

      return true;
    }

    return false;
  }

  bool attemptExpandCollapsed(int direction, int index) {
    if (index == 0) {
      direction = 1;
    } else if (index == items.length - 1) {
      direction = -1;
    }
    final item = items[index];
    final collapsedSize = item.collapsedSize ?? 0;
    final currentSize = item.newValue;
    final delta = collapsedSize - currentSize;
    if (direction < 0) {
      final borrowed = _borrowSize(index - 1, delta, 0, -1);
      if (borrowed.givenSize != delta) {
        reset();

        return false;
      }
      item._newCollapsed = false;

      return true;
    } else if (direction > 0) {
      final borrowed = _borrowSize(index + 1, delta, items.length - 1, 1);
      if (borrowed.givenSize != delta) {
        reset();

        return false;
      }
      item._newCollapsed = false;

      return true;
    } else if (direction == 0) {
      final halfDelta = delta / 2;
      final borrowedLeft = _borrowSize(index - 1, halfDelta, 0, -1);
      final borrowedRight =
          _borrowSize(index + 1, halfDelta, items.length - 1, 1);
      if (borrowedLeft.givenSize != halfDelta ||
          borrowedRight.givenSize != halfDelta) {
        reset();

        return false;
      }
      item._newCollapsed = false;

      return true;
    }

    return false;
  }

  void dragDivider(double delta, int index) {
    if (delta == 0) {
      return;
    }

    final borrowedLeft = _borrowSize(index - 1, delta, 0, -1);
    final borrowedRight = _borrowSize(index, -delta, items.length - 1, 1);

    final borrowedRightSize = borrowedRight.givenSize;
    final borrowedLeftSize = borrowedLeft.givenSize;

    final couldNotBorrowRight = borrowedRightSize + delta;
    final couldNotBorrowLeft = borrowedLeftSize - delta;

    couldNotBorrowLeft != 0 || couldNotBorrowRight != 0
        ? _couldNotBorrow += delta
        : _couldNotBorrow = 0;
    double givenBackLeft = 0;
    double givenBackRight = 0;

    if (couldNotBorrowLeft != -couldNotBorrowRight) {
      givenBackLeft =
          _borrowSize(borrowedRight.from, -couldNotBorrowLeft, index, -1)
              .givenSize;
      givenBackRight =
          _borrowSize(borrowedLeft.from, -couldNotBorrowRight, index - 1, 1)
              .givenSize;
    }

    if (givenBackLeft != -couldNotBorrowLeft ||
        givenBackRight != -couldNotBorrowRight) {
      reset();

      return;
    }

    final payOffLeft = _payOffLoanSize(index - 1, delta, -1);
    final payOffRight = _payOffLoanSize(index, -delta, 1);

    final payingBackLeft = _borrowSize(index - 1, -payOffLeft, 0, -1).givenSize;
    final payingBackRight =
        _borrowSize(index, -payOffRight, items.length - 1, 1).givenSize;

    if (payingBackLeft != -payOffLeft || payingBackRight != -payOffRight) {
      reset();

      return;
    }

    if (_couldNotBorrow > 0) {
      final start = borrowedRight.from;
      int endNotCollapsed = items.length - 1;
      for (int i = endNotCollapsed; i > start; i -= 1) {
        if (items[i].newCollapsed) {
          endNotCollapsed = i - 1;
        } else {
          break;
        }
      }
      if (start == endNotCollapsed) {
        _checkCollapseUntil(index);
      }
      _checkExpanding(index);
    } else if (_couldNotBorrow < 0) {
      final start = borrowedLeft.from;
      int endNotCollapsed = 0;
      for (int i = endNotCollapsed; i < start; i += 1) {
        if (items[i].newCollapsed) {
          endNotCollapsed = i + 1;
        } else {
          break;
        }
      }
      if (start == endNotCollapsed) {
        _checkCollapseUntil(index);
      }
      _checkExpanding(index);
    }
  }

  void reset() {
    for (final item in items) {
      if (item._newValue != null) {
        item._newValue = null;
        item._newCollapsed = null;
      }
    }
  }

  double _payOffLoanSize(double delta, int direction, int index) {
    if (direction < 0) {
      for (int i = 0; i < index; i += 1) {
        final borrowedSize = items[i].newValue - items[i].value;
        if (borrowedSize < 0 && delta > 0) {
          double newBorrowedSize = borrowedSize + delta;
          if (newBorrowedSize > 0) {
            delta = -borrowedSize;
            newBorrowedSize = 0;
          }
          items[i]._newValue = items[i].value + newBorrowedSize;

          return delta;
        } else if (borrowedSize > 0 && delta < 0) {
          double newBorrowedSize = borrowedSize + delta;
          if (newBorrowedSize < 0) {
            delta = -borrowedSize;
            newBorrowedSize = 0;
          }
          items[i]._newValue = items[i].value + newBorrowedSize;

          return delta;
        }
      }
    } else if (direction > 0) {
      for (int i = items.length - 1; i > index; i -= 1) {
        final borrowedSize = items[i].newValue - items[i].value;
        if (borrowedSize < 0 && delta > 0) {
          double newBorrowedSize = borrowedSize + delta;
          if (newBorrowedSize > 0) {
            delta = -borrowedSize;
            newBorrowedSize = 0;
          }
          items[i]._newValue = items[i].value + newBorrowedSize;

          return delta;
        } else if (borrowedSize > 0 && delta < 0) {
          double newBorrowedSize = borrowedSize + delta;
          if (newBorrowedSize < 0) {
            delta = -borrowedSize;
            newBorrowedSize = 0;
          }
          items[i]._newValue = items[i].value + newBorrowedSize;

          return delta;
        }
      }
    }

    return 0;
  }

  ResizableItem? _getItem(int index) {
    return index < 0 || index >= items.length ? null : items[index];
  }

  _BorrowInfo _borrowSize(double delta, int direction, int index, int until) {
    assert(direction == -1 || direction == 1, 'Direction must be -1 or 1');
    final item = _getItem(index);
    if (item == null) {
      return _BorrowInfo(0, index - direction);
    }
    if (index == until + direction) {
      return _BorrowInfo(0, index);
    }
    if (!item.resizable) {
      return _BorrowInfo(0, index - direction);
    }

    final minSize = item.min;
    final maxSize = item.max;

    if (item.newCollapsed) {
      return (direction < 0 && delta < 0) || (direction > 0 && delta > 0)
          ? _borrowSize(index + direction, delta, until, direction)
          : _BorrowInfo(0, index);
    }

    final newSize = item.newValue + delta;

    if (newSize < minSize) {
      final overflow = newSize - minSize;
      final given = delta - overflow;
      final borrowSize =
          _borrowSize(index + direction, overflow, until, direction);
      item._newValue = minSize;

      return _BorrowInfo(borrowSize.givenSize + given, borrowSize.from);
    }

    if (newSize > maxSize) {
      final maxOverflow = newSize - maxSize;
      final given = delta - maxOverflow;

      final borrowSize =
          _borrowSize(index + direction, maxOverflow, until, direction);
      item._newValue = maxSize;

      return _BorrowInfo(borrowSize.givenSize + given, borrowSize.from);
    }

    item._newValue = newSize;

    return _BorrowInfo(delta, index);
  }

  void _checkCollapseUntil(int index) {
    if (_couldNotBorrow < 0) {
      for (int i = index - 1; i >= 0; i -= 1) {
        final previousItem = _getItem(i);
        final collapsibleSize = previousItem?.collapsedSize;
        if (previousItem != null &&
            collapsibleSize != null &&
            !previousItem.newCollapsed) {
          final minSize = previousItem.min;
          final threshold = (collapsibleSize - minSize) * collapseRatio;
          if (_couldNotBorrow < threshold) {
            final toBorrow = minSize - collapsibleSize;
            final borrowed = _borrowSize(index, toBorrow, items.length - 1, 1);
            final borrowedSize = borrowed.givenSize;
            if (borrowedSize < toBorrow) {
              reset();

              return;
            }
            previousItem._newCollapsed = true;
            previousItem._newValue = previousItem.collapsedSize ?? 0;
            previousItem._value = previousItem._newValue!;
            _couldNotBorrow = 0;
          }
        }
      }
    } else {
      for (int i = index; i < items.length; i += 1) {
        final nextItem = _getItem(i);
        final collapsibleSize = nextItem?.collapsedSize;
        if (nextItem != null &&
            collapsibleSize != null &&
            !nextItem.newCollapsed) {
          final minSize = nextItem.min;
          final threshold = (collapsibleSize - minSize) * collapseRatio;
          if (_couldNotBorrow > threshold) {
            final toBorrow = minSize - collapsibleSize;
            final borrowed = _borrowSize(index - 1, toBorrow, 0, -1);
            final borrowedSize = borrowed.givenSize;
            if (borrowedSize < toBorrow) {
              reset();

              return;
            }
            nextItem._newCollapsed = true;
            nextItem._newValue = nextItem.collapsedSize ?? 0;
            nextItem._value = nextItem._newValue!;
            _couldNotBorrow = 0;
          }
        }
      }
    }
  }

  void _checkExpanding(int index) {
    if (_couldNotBorrow > 0) {
      int toCheck = index - 1;
      for (; toCheck >= 0; toCheck -= 1) {
        final item = _getItem(toCheck);
        final collapsibleSize = item?.collapsedSize;
        if (item != null && item.newCollapsed && collapsibleSize != null) {
          final minSize = item.min;
          final threshold = (minSize - collapsibleSize) * expandRatio;
          if (_couldNotBorrow >= threshold) {
            final toBorrow = collapsibleSize - minSize;
            final borrowed =
                _borrowSize(toCheck + 1, toBorrow, items.length, 1);
            final borrowedSize = borrowed.givenSize;
            if (borrowedSize > toBorrow) {
              reset();
              continue;
            }
            item._newCollapsed = false;
            item._newValue = minSize;
            item._value = minSize;
            _couldNotBorrow = 0;
          }
          break;
        }
      }
    } else if (_couldNotBorrow < 0) {
      int toCheck = index;
      for (; toCheck < items.length; toCheck += 1) {
        final item = _getItem(toCheck);
        final collapsibleSize = item?.collapsedSize;
        if (item != null && collapsibleSize != null && item.newCollapsed) {
          final minSize = item.min;
          final threshold = (collapsibleSize - minSize) * expandRatio;
          if (_couldNotBorrow <= threshold) {
            final toBorrow = collapsibleSize - minSize;
            final borrowed = _borrowSize(toCheck - 1, toBorrow, -1, -1);
            final borrowedSize = borrowed.givenSize;
            if (borrowedSize > toBorrow) {
              reset();
              continue;
            }
            item._newCollapsed = false;
            item._newValue = minSize;
            item._value = minSize;
            _couldNotBorrow = 0;
          }
          break;
        }
      }
    }
  }
}
