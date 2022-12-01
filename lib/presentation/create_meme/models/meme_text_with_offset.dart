import 'dart:ui';

import 'package:equatable/equatable.dart';

import 'meme_text.dart';

class MemeTextWithOffset  extends Equatable{
  final MemeText memeText;
  final Offset? offset;

  MemeTextWithOffset({
    required this.memeText,
    required this.offset,
  });

  @override
  List<Object?> get props => [memeText, offset];
}