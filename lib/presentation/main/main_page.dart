import 'dart:io';

import 'package:flutter/material.dart';
import 'package:memogenerator/data/models/meme.dart';
import 'package:memogenerator/presentation/main/main_bloc.dart';
import 'package:memogenerator/presentation/create_meme/create_meme_page.dart';
import 'package:memogenerator/presentation/main/models/meme_with_docs_path.dart';
import 'package:memogenerator/presentation/widgets/app_button.dart';
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
      child: WillPopScope(
        onWillPop: () async {
          final goBack = await showConfirmationExitDialog(context);
          return goBack ?? false;
        },
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
      ),
    );
  }

  Future<bool?> showConfirmationExitDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Точно хотите выйти?'),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16),
          content: const Text('Мемы сами себя не сделают'),
          actions: [
            AppButton(
              onTap: () => Navigator.of(context).pop(false),
              text: 'Остаться',
              color: AppColors.darkGrey,
            ),
            AppButton(
              onTap: () => Navigator.of(context).pop(true),
              text: 'Выйти',
            ),
          ],
        );
      },
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
    return StreamBuilder<MemesWithDocsPath>(
        stream: bloc.observeMemesWithDocsPath(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox.shrink();
          }
          final items = snapshot.requireData.memes;
          final docsPath = snapshot.requireData.docsPath;
          return GridView.extent(
            maxCrossAxisExtent: 180,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            children: items.map((item) {
              return GridItem(meme: item, docsPath: docsPath);
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

class GridItem extends StatelessWidget {
  const GridItem({
    Key? key,
    required this.meme,
    required this.docsPath,
  }) : super(key: key);

  final Meme meme;
  final String docsPath;

  @override
  Widget build(BuildContext context) {
    final imageFile = File("$docsPath${Platform.pathSeparator}${meme.id}.png");
    return GestureDetector(
      onTap: () {
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (context) {
          return CreateMemePage(id: meme.id);
        }));
      },
      child: Container(
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.darkGrey, width: 1),
        ),
        child: imageFile.existsSync() ? Image.file(
          File("$docsPath${Platform.pathSeparator}${meme.id}.png"),
        ) : Text(meme.id),
      ),
    );
  }
}
