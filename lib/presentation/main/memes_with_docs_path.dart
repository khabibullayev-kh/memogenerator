import 'package:equatable/equatable.dart';
import 'package:memogenerator/data/models/meme.dart';

class MemeWithDocsPath extends Equatable{
  final List<Meme> memes;
  final String docsPath;

  MemeWithDocsPath(this.memes, this.docsPath);

  @override
  List<Object?> get props => [memes,docsPath];



}