import 'package:flutter/material.dart';
import 'package:memogenerator/data/models/meme.dart';
import 'package:memogenerator/presentation/main/main_bloc.dart';
import 'package:memogenerator/presentation/create_meme/create_meme_page.dart';
import 'package:memogenerator/resources/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late MainBloc bloc;

  @override
  void initState() {
    super.initState();
    bloc = MainBloc();
  }

  @override
  Widget build(BuildContext context) {
    return Provider.value(
      value: bloc,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: AppColors.lemon,
          foregroundColor: AppColors.darkGrey,
          title: Text('Мемогенератор',
              style: GoogleFonts.seymourOne(fontSize: 24)),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final selectedMemePath = await bloc.selectMeme();
            if (selectedMemePath == null) {
              return;
            }
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CreateMemePage(
                  selectedMemePath: selectedMemePath,
                ),
              ),
            );
          },
          backgroundColor: AppColors.fuchsia,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Создать'),
        ),
        backgroundColor: Colors.white,
        body: SafeArea(
          child: MainPageContent(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    bloc.dispose();
    super.dispose();
  }
}

class MainPageContent extends StatefulWidget {
  @override
  State<MainPageContent> createState() => _MainPageContentState();
}

class _MainPageContentState extends State<MainPageContent> {
  late FocusNode searchFieldFocusNode;

  @override
  void initState() {
    super.initState();
    searchFieldFocusNode = FocusNode();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<MainBloc>(context, listen: false);
    return StreamBuilder<List<Meme>>(
        stream: bloc.observeMemes(),
        initialData: const <Meme>[],
        builder: (context, snapshot) {
          final items = snapshot.hasData ? snapshot.data! : const <Meme>[];
          return ListView(
            children: items.map((item) {
              return GestureDetector(
                onTap: () {
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (context) {
                    return CreateMemePage(id: item.id);
                  }));
                },
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    item.id.toString(),
                  ),
                ),
              );
            }).toList(),
          );
        });
  }

  @override
  void dispose() {
    searchFieldFocusNode.dispose();
    super.dispose();
  }
}
