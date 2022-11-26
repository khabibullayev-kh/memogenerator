import 'dart:io';

import 'package:flutter/material.dart';
import 'package:memogenerator/presentation/create_meme/create_meme_bloc.dart';
import 'package:memogenerator/presentation/create_meme/font_settings_bottom_sheet.dart';
import 'package:memogenerator/presentation/create_meme/meme_text_on_canvas.dart';
import 'package:memogenerator/presentation/create_meme/models/meme_text.dart';
import 'package:memogenerator/presentation/create_meme/models/meme_text_with_offset.dart';
import 'package:memogenerator/presentation/create_meme/models/meme_text_with_selection.dart';
import 'package:memogenerator/presentation/widgets/app_button.dart';
import 'package:memogenerator/resources/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';

class CreateMemePage extends StatefulWidget {
  final String? id;
  final String? selectedMemePath;

  const CreateMemePage({Key? key, this.id, this.selectedMemePath})
      : super(key: key);

  @override
  State<CreateMemePage> createState() => _CreateMemePageState();
}

class _CreateMemePageState extends State<CreateMemePage> {
  late CreateMemeBloc bloc;

  @override
  void initState() {
    super.initState();
    bloc = CreateMemeBloc(
        id: widget.id, selectedMemePath: widget.selectedMemePath);
  }

  @override
  Widget build(BuildContext context) {
    return Provider.value(
      value: bloc,
      child: WillPopScope(
        onWillPop: () async {
          final allSaved = await bloc.isAllSaved();
          if (allSaved) {
            return true;
          }
          final goBack = await showConfirmationExitDialog(context);
          return goBack ?? false;
        },
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            backgroundColor: AppColors.lemon,
            foregroundColor: AppColors.darkGrey,
            title: const Text('Создаём мем'),
            bottom: const EditTextBar(),
            actions: [
              GestureDetector(
                onTap: () => bloc.shareMeme(),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Icon(Icons.share, color: AppColors.darkGrey),
                ),
              ),
              GestureDetector(
                onTap: () => bloc.saveMeme(),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Icon(Icons.save, color: AppColors.darkGrey),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.white,
          body: const SafeArea(
            child: CreateMemePageContent(),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    bloc.dispose();
    super.dispose();
  }

  Future<bool?> showConfirmationExitDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Хотите выйти?'),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16),
          content: const Text('Вы потеряете несохраненные изменения'),
          actions: [
            AppButton(
              onTap: () => Navigator.of(context).pop(false),
              text: 'Отмена',
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
}

class EditTextBar extends StatefulWidget implements PreferredSizeWidget {
  const EditTextBar({Key? key}) : super(key: key);

  @override
  State<EditTextBar> createState() => _EditTextBarState();

  @override
  Size get preferredSize => const Size.fromHeight(68);
}

class _EditTextBarState extends State<EditTextBar> {
  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<CreateMemeBloc>(context, listen: false);
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: StreamBuilder<MemeText?>(
        stream: bloc.observeSelectedMemeText(),
        builder: (context, snapshot) {
          final MemeText? selectedMemeText =
              snapshot.hasData ? snapshot.data : null;
          if (selectedMemeText?.text != controller.text) {
            final newText = selectedMemeText?.text ?? '';
            controller.text = newText;
            controller.selection =
                TextSelection.collapsed(offset: newText.length);
          }
          final haveSelected = selectedMemeText != null;
          return TextField(
            enabled: haveSelected,
            controller: controller,
            onChanged: (text) {
              if (haveSelected) {
                bloc.changeMemeText(selectedMemeText.id, text);
              }
            },
            onEditingComplete: () => bloc.deselectMemeText(),
            cursorColor: AppColors.fuchsia,
            decoration: InputDecoration(
              filled: true,
              fillColor:
                  haveSelected ? AppColors.fuchsia16 : AppColors.darkGrey6,
              hintText: haveSelected ? 'Ввести текст' : null,
              hintStyle: TextStyle(fontSize: 16, color: AppColors.darkGrey38),
              disabledBorder: UnderlineInputBorder(
                  borderSide:
                      BorderSide(color: AppColors.darkGrey38, width: 1)),
              enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.fuchsia38, width: 1)),
              focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.fuchsia, width: 2)),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

class CreateMemePageContent extends StatefulWidget {
  const CreateMemePageContent({Key? key}) : super(key: key);

  @override
  State<CreateMemePageContent> createState() => _CreateMemePageContentState();
}

class _CreateMemePageContentState extends State<CreateMemePageContent> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const MemeCanvasWidget(),
        Container(
          height: 1,
          width: double.infinity,
          color: AppColors.darkGrey,
        ),
        const Expanded(
          flex: 1,
          child: BottomList(),
        )
      ],
    );
  }
}

class BottomList extends StatelessWidget {
  const BottomList({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<CreateMemeBloc>(context, listen: false);
    return Container(
      color: Colors.white,
      child: StreamBuilder<List<MemeTextWithSelection>>(
          initialData: const <MemeTextWithSelection>[],
          stream: bloc.observeMemeTextWithSelection(),
          builder: (context, snapshot) {
            final items = snapshot.hasData
                ? snapshot.data!
                : const <MemeTextWithSelection>[];
            return ListView.separated(
              itemCount: items.length + 1,
              itemBuilder: (BuildContext context, int index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Center(
                      child: AppButton(
                        onTap: () => bloc.addNewText(),
                        text: "Добавить текст",
                        icon: Icons.add,
                      ),
                    ),
                  );
                }
                final item = items[index - 1];
                return BottomMemeText(item: item);
              },
              separatorBuilder: (BuildContext context, int index) {
                if (index == 0) {
                  return const SizedBox.shrink();
                }
                return const BottomSeparator();
              },
            );
          }),
    );
  }
}

class BottomSeparator extends StatelessWidget {
  const BottomSeparator({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: AppColors.darkGrey,
      margin: const EdgeInsets.only(left: 16),
    );
  }
}

class BottomMemeText extends StatelessWidget {
  const BottomMemeText({
    Key? key,
    required this.item,
  }) : super(key: key);

  final MemeTextWithSelection item;

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<CreateMemeBloc>(context, listen: false);

    return GestureDetector(
      onTap: () => bloc.selectMemeText(item.memeText.id),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 48,
        alignment: Alignment.centerLeft,
        color: item.selected ? AppColors.darkGrey16 : null,
        child: Row(
          children: [
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                item.memeText.text,
                style: const TextStyle(color: AppColors.darkGrey, fontSize: 16),
              ),
            ),
            const SizedBox(width: 4),
            BottomMemeTextAction(
              icon: Icons.font_download_outlined,
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24),
                  )),
                  builder: (context) {
                    return Provider.value(
                      value: bloc,
                      child: FontSettingBottomSheet(memeText: item.memeText),
                    );
                  },
                );
              },
            ),
            const SizedBox(width: 4),

            BottomMemeTextAction(
              icon: Icons.delete_forever_outlined,
              onTap: () {
                bloc.deleteMemeText(item.memeText.id);
              },
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

class BottomMemeTextAction extends StatelessWidget {
  const BottomMemeTextAction({
    Key? key,
    required this.onTap,
    required this.icon,
  }) : super(key: key);

  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon),
      ),
    );
  }
}

class MemeCanvasWidget extends StatelessWidget {
  const MemeCanvasWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<CreateMemeBloc>(context, listen: false);
    return Expanded(
      flex: 2,
      child: Container(
        color: AppColors.darkGrey38,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(8),
        child: AspectRatio(
          aspectRatio: 1,
          child: GestureDetector(
            onTap: () => bloc.deselectMemeText(),
            child: StreamBuilder<ScreenshotController>(
                stream: bloc.observeScreenshotController(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox.shrink();
                  }
                  return Screenshot(
                    controller: snapshot.requireData,
                    child: Stack(
                      children: const [
                        BackgroundImage(),
                        MemeTexts(),
                      ],
                    ),
                  );
                }),
          ),
        ),
      ),
    );
  }
}

class MemeTexts extends StatelessWidget {
  const MemeTexts({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<CreateMemeBloc>(context, listen: false);
    return StreamBuilder<List<MemeTextWithOffset>>(
        initialData: const <MemeTextWithOffset>[],
        stream: bloc.observeMemeTextWithOffsets(),
        builder: (context, snapshot) {
          final memeTextsWithOffsets =
              snapshot.hasData ? snapshot.data! : const <MemeTextWithOffset>[];
          return LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: memeTextsWithOffsets.map(
                  (memeTextWithOffset) {
                    return DraggableMemeText(
                      key: ValueKey(memeTextWithOffset.memeText.id),
                      memeTextWithOffset: memeTextWithOffset,
                      parentConstraints: constraints,
                    );
                  },
                ).toList(),
              );
            },
          );
        });
  }
}

class BackgroundImage extends StatelessWidget {
  const BackgroundImage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<CreateMemeBloc>(context, listen: false);
    return StreamBuilder<String?>(
      stream: bloc.observeMemePath(),
      builder: (context, snapshot) {
        final path = snapshot.hasData ? snapshot.data : null;
        if (path == null) {
          return Container(color: Colors.white);
        }
        return Image.file(File(path));
      },
    );
  }
}

class DraggableMemeText extends StatefulWidget {
  final MemeTextWithOffset memeTextWithOffset;
  final BoxConstraints parentConstraints;

  const DraggableMemeText({
    Key? key,
    required this.memeTextWithOffset,
    required this.parentConstraints,
  }) : super(key: key);

  @override
  State<DraggableMemeText> createState() => _DraggableMemeTextState();
}

class _DraggableMemeTextState extends State<DraggableMemeText> {
  late double top;
  late double left;

  final double padding = 8;

  @override
  void initState() {
    super.initState();
    top = widget.memeTextWithOffset.offset?.dy ??
        widget.parentConstraints.maxHeight / 2;
    left = widget.memeTextWithOffset.offset?.dx ??
        widget.parentConstraints.maxWidth / 3;
    if (widget.memeTextWithOffset.offset == null) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        final bloc = Provider.of<CreateMemeBloc>(context, listen: false);
        bloc.changeMemeTextOffset(
            widget.memeTextWithOffset.memeText.id, Offset(left, top));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<CreateMemeBloc>(context, listen: false);
    return Positioned(
      top: top,
      left: left,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => bloc.selectMemeText(widget.memeTextWithOffset.memeText.id),
        onPanUpdate: (details) {
          bloc.selectMemeText(widget.memeTextWithOffset.memeText.id);
          setState(() {
            left = calculateLeft(details);
            top = calculateTop(details);
            bloc.changeMemeTextOffset(
                widget.memeTextWithOffset.memeText.id, Offset(left, top));
          });
        },
        child: StreamBuilder<MemeText?>(
            stream: bloc.observeSelectedMemeText(),
            builder: (context, snapshot) {
              final selectedItem = snapshot.hasData ? snapshot.data : null;
              final selected =
                  widget.memeTextWithOffset.memeText.id == selectedItem?.id &&
                      selectedItem != null;
              return MemeTextOnCanvas(
                selected: selected,
                padding: padding,
                parentConstraints: widget.parentConstraints,
                text: widget.memeTextWithOffset.memeText.text,
                fontSize: widget.memeTextWithOffset.memeText.fontSize,
                color: widget.memeTextWithOffset.memeText.color,
                fontWeight: widget.memeTextWithOffset.memeText.fontWeight,
              );
            }),
      ),
    );
  }

  double calculateTop(DragUpdateDetails details) {
    final rawTop = top + details.delta.dy;
    if (rawTop < 0) {
      return 0;
    }
    if (rawTop > widget.parentConstraints.maxHeight - padding * 2 - 30) {
      return widget.parentConstraints.maxHeight - padding * 2 - 30;
    }
    return rawTop;
  }

  double calculateLeft(DragUpdateDetails details) {
    final rawLeft = left + details.delta.dx;
    if (rawLeft < 0) {
      return 0;
    }
    if (rawLeft > widget.parentConstraints.maxWidth - padding * 2 - 24) {
      return widget.parentConstraints.maxWidth - padding * 2 - 24;
    }
    return rawLeft;
  }
}
