import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../data/models/chat_message.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Listener para provocar rebuild cuando cambia el texto
    _inputCtrl.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _trySend(ChatProvider chat) {
    final txt = _inputCtrl.text.trim();
    if (txt.isEmpty || chat.sending) return;
    _inputCtrl.clear();
    chat.sendMessage(txt);
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chat, _) {
        _scrollToEnd();
        final scheme = Theme.of(context).colorScheme;

        final canSend = !chat.sending && _inputCtrl.text.trim().isNotEmpty;

        return Scaffold(
          backgroundColor: scheme.background,
          appBar: AppBar(
            title: const Text('Asistente (Beta)'),
            actions: [
              IconButton(
                tooltip: 'Limpiar conversación',
                icon: const Icon(Icons.refresh),
                onPressed: chat.sending ? null : chat.clearChat,
              ),
              if (chat.sending)
                IconButton(
                  tooltip: 'Detener',
                  icon: const Icon(Icons.stop_circle_outlined),
                  onPressed: chat.stopGeneration,
                ),
            ],
          ),
          body: Column(
            children: [
              if (chat.error != null)
                _ErrorBanner(
                  message: chat.error!,
                  onClose: () => ScaffoldMessenger.of(context)
                      .hideCurrentSnackBar(),
                ),
              Expanded(
                child: ListView.builder(
                  controller: _scrollCtrl,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  itemCount: chat.messages.length,
                  itemBuilder: (context, i) {
                    final m = chat.messages[i];
                    final prevRole = i > 0 ? chat.messages[i - 1].role : '';
                    final showAvatar = m.role != prevRole;
                    return _MessageBubble(
                      message: m,
                      showAvatar: showAvatar,
                    );
                  },
                ),
              ),
              // (Opcional) Chips de sugerencias:
              // _QuickSuggestions(onTap: (q) {
              //   _inputCtrl.text = q;
              //   setState(() {});
              // }),
              const Divider(height: 1),
              SafeArea(
                top: false,
                minimum:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputCtrl,
                        focusNode: _focusNode,
                        minLines: 1,
                        maxLines: 5,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _trySend(chat),
                        decoration: const InputDecoration(
                          hintText: 'Escribe tu mensaje...',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        enabled: !chat.sending,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: canSend ? () => _trySend(chat) : null,
                      icon: const Icon(Icons.send),
                      label: const Text('Enviar'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool showAvatar;

  const _MessageBubble({
    required this.message,
    required this.showAvatar,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final scheme = Theme.of(context).colorScheme;
    final bubbleColor = isUser
        ? scheme.primaryContainer.withOpacity(0.9)
        : scheme.surfaceVariant.withOpacity(
        Theme.of(context).brightness == Brightness.dark ? 0.4 : 1.0);
    final textColor =
    isUser ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;
    final radius = Radius.circular(18);

    return Padding(
      padding: EdgeInsets.only(
        top: 6,
        bottom: 6,
        left: isUser ? 40 : 8,
        right: isUser ? 8 : 40,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
        isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser && showAvatar)
            CircleAvatar(
              radius: 18,
              backgroundColor: scheme.primary.withOpacity(0.15),
              child: Icon(Icons.smart_toy, color: scheme.primary, size: 20),
            )
          else if (!isUser)
            const SizedBox(width: 36),
          Flexible(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: radius,
                  topRight: radius,
                  bottomLeft: isUser ? radius : Radius.zero,
                  bottomRight: isUser ? Radius.zero : radius,
                ),
                border: Border.all(
                  color: message.error
                      ? scheme.error
                      : Colors.black.withOpacity(0.05),
                ),
              ),
              child: _AnimatedTyping(
                active: message.streaming,
                child: SelectableText(
                  message.text.isEmpty && message.streaming
                      ? '...'
                      : message.text,
                  style: TextStyle(
                    color: message.error ? scheme.error : textColor,
                    fontStyle: message.streaming ? FontStyle.italic : null,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedTyping extends StatefulWidget {
  final bool active;
  final Widget child;
  const _AnimatedTyping({required this.active, required this.child});

  @override
  State<_AnimatedTyping> createState() => _AnimatedTypingState();
}

class _AnimatedTypingState extends State<_AnimatedTyping>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _opacity = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (widget.active) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _AnimatedTyping oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.active && _ctrl.isAnimating) {
      _ctrl.stop();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;
    return FadeTransition(opacity: _opacity, child: widget.child);
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onClose;
  const _ErrorBanner({required this.message, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Icon(Icons.error, color: scheme.onErrorContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            ),
            IconButton(
              onPressed: onClose,
              icon: Icon(Icons.close, color: scheme.onErrorContainer),
            )
          ],
        ),
      ),
    );
  }
}

// (Opcional) Sugerencias rápidas
class _QuickSuggestions extends StatelessWidget {
  final void Function(String) onTap;
  const _QuickSuggestions({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final suggestions = <String>[
      'Resumen de mis gastos del mes',
      '¿Cuál fue mi última transacción?',
      'Consejo para reducir gastos',
    ];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, i) {
          final text = suggestions[i];
          return ActionChip(
            label: Text(text, style: const TextStyle(fontSize: 12)),
            onPressed: () => onTap(text),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: suggestions.length,
      ),
    );
  }
}