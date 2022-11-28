import 'dart:convert';
import 'package:memogenerator/data/models/meme.dart';
import 'package:memogenerator/data/shared_preference_data.dart';
import 'package:rxdart/rxdart.dart';
import 'package:collection/collection.dart';

class MemesRepository {
  final updater = PublishSubject<Null>();
  final SharedPreferenceData spData;

  //статический конструктор,возвращает инстанс
  static MemesRepository? _instance;

  factory MemesRepository.getInstance() => _instance ??=
      MemesRepository._internal(SharedPreferenceData.getInstance());

  MemesRepository._internal(this.spData);

  //Метод добавления в избраное
  Future<bool> addToMemes(final Meme newMeme) async {
    // Если лист пустой
    final memes = await getMemes();
    final memeIndex = memes.indexWhere((meme) => meme.id == newMeme.id);
    if (memeIndex == -1) {
      memes.add(newMeme);
    } else {
      memes.removeAt(memeIndex);
      memes.insert(memeIndex, newMeme);
    }
    return _setMemes(memes);
  }

  //Метод удаления из избранного
  Future<bool> removeFromMemes(final String id) async {
    // Если лист пустой
    final memes = await getMemes();
    memes.removeWhere((meme) => meme.id == id);
    return _setMemes(memes);
  }

  // Метод будет выдавать список со всем избранным,которые будут обображатся на мейн странице при входе на экран
  // Метод Observe
  Stream<List<Meme>> observeMemes() async* {
    yield await getMemes();
    await for (final _ in updater) {
      yield await getMemes();
    }
  }

  // еще 2 доп Метода
  Future<List<Meme>> getMemes() async {
    final rawMemes = await spData.getMemes();
    return rawMemes
        .map((rawMeme) => Meme.fromJson(json.decode(rawMeme)))
        .toList();
  }

  //Метод оффлайн просмотра избранного
  Future<Meme?> getMeme(final String id) async {
    final memes = await getMemes();
    return memes.firstWhereOrNull((meme) => meme.id == id);
  }

  Future<bool> _setMemes(final List<Meme> Memes) async {
    final rawMemes = Memes.map((Meme) => json.encode(Meme.toJson())).toList();
    return _setRawMemes(rawMemes);
  }

  Future<bool> _setRawMemes(final List<String> rawMemes) {
    updater.add(null);
    return spData.setMemes(rawMemes);
  }
}
