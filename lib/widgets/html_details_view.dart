import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

class HtmlDetailsView extends StatelessWidget {
  const HtmlDetailsView({
    Key? key,
    required this.html,
    this.color,
  }) : super(key: key);

  final String html;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final trimmed = html.trim();
    if (trimmed.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final textColor = color ?? theme.textTheme.bodyMedium?.color ?? Colors.black;
    final document = html_parser.parse(trimmed);
    final nodes = document.body?.nodes ?? html_parser.parseFragment(trimmed).nodes;
    final children = <Widget>[];

    for (final node in nodes) {
      final widget = _blockFor(node, context, textColor);
      if (widget != null) children.add(widget);
    }

    if (children.isEmpty) {
      final fallback = document.body?.text.trim() ?? trimmed;
      if (fallback.isEmpty) return const SizedBox.shrink();
      return Text(fallback, style: theme.textTheme.bodyMedium?.copyWith(color: textColor));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          children[i],
        ],
      ],
    );
  }

  Widget? _blockFor(dom.Node node, BuildContext context, Color textColor) {
    if (node is dom.Text) {
      final text = node.text.trim();
      if (text.isEmpty) return null;
      return Text(text, style: TextStyle(color: textColor, height: 1.4));
    }
    if (node is! dom.Element) return null;

    final theme = Theme.of(context);
    switch (node.localName) {
      case 'h1':
      case 'h2':
      case 'h3':
      case 'h4':
        return Text(
          node.text.trim(),
          style: theme.textTheme.titleMedium?.copyWith(
            color: textColor,
            fontWeight: FontWeight.w700,
          ),
        );
      case 'p':
      case 'div':
      case 'span':
        final nested = <Widget>[];
        for (final child in node.nodes) {
          if (['ul', 'ol', 'table', 'h1', 'h2', 'h3'].contains(
            child is dom.Element ? child.localName : '',
          )) {
            final block = _blockFor(child, context, textColor);
            if (block != null) nested.add(block);
          }
        }
        if (nested.isNotEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: nested,
          );
        }
        return Text.rich(
          TextSpan(children: _spans(node, TextStyle(color: textColor, height: 1.45))),
        );
      case 'ul':
        return _list(node, context, textColor, ordered: false);
      case 'ol':
        return _list(node, context, textColor, ordered: true);
      case 'table':
        return _table(node, context, textColor);
      case 'br':
        return const SizedBox(height: 8);
      default:
        final text = node.text.trim();
        if (text.isEmpty) return null;
        return Text.rich(
          TextSpan(children: _spans(node, TextStyle(color: textColor, height: 1.45))),
        );
    }
  }

  Widget _list(
    dom.Element node,
    BuildContext context,
    Color textColor, {
    required bool ordered,
  }) {
    final items = node.children.where((child) => child.localName == 'li').toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < items.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    ordered ? '${i + 1}.' : '•',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: _spans(
                        items[i],
                        TextStyle(color: textColor, height: 1.4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _table(dom.Element node, BuildContext context, Color textColor) {
    final rows = node.querySelectorAll('tr');
    if (rows.isEmpty) return const SizedBox.shrink();

    final borderColor = textColor.withOpacity(0.2);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        border: TableBorder.all(color: borderColor),
        defaultColumnWidth: const IntrinsicColumnWidth(),
        children: [
          for (var r = 0; r < rows.length; r++)
            TableRow(
              decoration: BoxDecoration(
                color: r == 0
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.08)
                    : null,
              ),
              children: [
                for (final cell in rows[r].children.where(
                  (child) => child.localName == 'th' || child.localName == 'td',
                ))
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Text.rich(
                      TextSpan(
                        children: _spans(
                          cell,
                          TextStyle(
                            color: textColor,
                            fontWeight: cell.localName == 'th' || r == 0
                                ? FontWeight.w700
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  List<InlineSpan> _spans(dom.Node node, TextStyle style) {
    if (node is dom.Text) {
      return [TextSpan(text: node.text, style: style)];
    }
    if (node is! dom.Element) return const [];
    if (node.localName == 'br') {
      return const [TextSpan(text: '\n')];
    }

    var next = style;
    switch (node.localName) {
      case 'strong':
      case 'b':
        next = style.copyWith(fontWeight: FontWeight.w700);
        break;
      case 'em':
      case 'i':
        next = style.copyWith(fontStyle: FontStyle.italic);
        break;
      case 'u':
        next = style.copyWith(decoration: TextDecoration.underline);
        break;
    }

    return [
      for (final child in node.nodes) ..._spans(child, next),
    ];
  }
}
