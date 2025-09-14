import 'package:flutter/material.dart';

enum TitleSize { compact, medium, large }

class LargeTitleScaffold extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final double contentTopSpacing;
  final TitleSize size;

  // Opcional: FAB como en un Scaffold normal
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  const LargeTitleScaffold({
    super.key,
    required this.title,
    required this.children,
    this.actions,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
    this.contentTopSpacing = 8,
    this.size = TitleSize.compact,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });

  @override
  Widget build(BuildContext context) {
    final appBarBg = Theme.of(context).scaffoldBackgroundColor;

    SliverAppBar _buildAppBar() {
      switch (size) {
        case TitleSize.large:
          return SliverAppBar.large(
            pinned: true,
            elevation: 0,
            // Evita el “scroll under”: AppBar opaco y sin sombra al desplazarse
            backgroundColor: appBarBg,
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 0,
            title: Text(title),
            actions: actions,
          );
        case TitleSize.medium:
          return SliverAppBar.medium(
            pinned: true,
            elevation: 0,
            backgroundColor: appBarBg,
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 0,
            title: Text(title),
            actions: actions,
          );
        case TitleSize.compact:
        default:
          return SliverAppBar(
            pinned: true,
            elevation: 0,
            toolbarHeight: kToolbarHeight,
            backgroundColor: appBarBg,
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 0,
            title: Text(title),
            actions: actions,
          );
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation:
      floatingActionButtonLocation ?? FloatingActionButtonLocation.endFloat,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          // Separador fino para evitar “pegado” visual
          SliverToBoxAdapter(child: SizedBox(height: contentTopSpacing)),
          SliverPadding(
            padding: padding,
            sliver: SliverList.list(children: children),
          ),
        ],
      ),
    );
  }
}