import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'template.g.dart';

@JsonSerializable()
class Template extends Equatable{

  final String id;
  final String imageUrl;


  Template({required this.id, required this.imageUrl});

  factory Template.fromJson(final Map<String, dynamic> json) => _$TemplateFromJson(json);

  Map<String, dynamic> toJson() => _$TemplateToJson(this);

  @override
  // TODO: implement props
  List<Object?> get props => [id, imageUrl];
}