// lib/models/polymorphic_target.dart
// Base class for polymorphic targets (optional but can simplify code)
abstract class PolymorphicTarget {
  int get id;
  String get name; // Or another common identifying field
}

// Implement PolymorphicTarget for each model that can be a target
// Example: In product.dart, add 'implements PolymorphicTarget'
// class Product implements PolymorphicTarget { ... }
// @override int get id => this.id; // Add override if needed
// @override String get name => this.name; // Add override