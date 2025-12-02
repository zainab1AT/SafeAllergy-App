import 'package:equatable/equatable.dart';

class Allergy extends Equatable {
  final int id;
  
  final String name;

  const Allergy({
    required this.id,
    required this.name,
  });

  @override
  List<Object?> get props => [id, name];

  @override
  String toString() => 'Allergy(id: $id, name: $name)';
}

