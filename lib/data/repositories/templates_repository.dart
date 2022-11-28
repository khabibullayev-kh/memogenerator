import 'dart:convert';

import 'package:memogenerator/data/models/template.dart';
import 'package:memogenerator/data/shared_preference_data.dart';
import 'package:rxdart/rxdart.dart';
import 'package:collection/collection.dart';

class TemplatesRepository {

  final updater = PublishSubject<Null>();
  final SharedPreferenceData spData;

  static TemplatesRepository? _instance;

  factory TemplatesRepository.getInstance() =>
      _instance ??= TemplatesRepository._internal(SharedPreferenceData.getInstance());

  TemplatesRepository._internal(this.spData);

  Future<bool> addToTemplates(final Template newTemplate) async {
    final templates = await getTemplates();
    final memeIndex = templates.indexWhere((meme) => meme.id == newTemplate.id);
    if (memeIndex == -1) {
      templates.add(newTemplate);
    } else {
      templates.removeAt(memeIndex);
      templates.insert(memeIndex, newTemplate);
    }
    return _setTemplates(templates);
  }

  Future<bool> removeFromTemplates(final String id) async {
    final templates = await getTemplates();
    templates.removeWhere((meme) => meme.id == id);
    return _setTemplates(templates);
  }

  Stream<List<Template>> observeTemplates() async* {
    yield await getTemplates();
    await for (final _ in updater) {
      yield await getTemplates();
    }
  }

  Future<List<Template>> getTemplates() async {
    final rawTemplates = await spData.getTemplates();
    return rawTemplates
        .map((rawTemplate) => Template.fromJson(json.decode(rawTemplate)))
        .toList();
  }

  Future<bool> _setTemplates(final List<Template> templates) async {
    final rawTemplates = templates
        .map((meme) => json.encode(meme.toJson()))
        .toList();
    return _setRawTemplates(rawTemplates);
  }

  Future<bool> _setRawTemplates(final List<String> rawTemplates) {
    updater.add(null);
    return spData.setTemplates(rawTemplates);
  }

  Future<Template?> getTemplate(final String id) async {
    final templates = await getTemplates();
    return templates.firstWhereOrNull((meme) => meme.id == id);
  }
}
