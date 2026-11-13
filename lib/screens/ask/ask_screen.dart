import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../providers/ledger_provider.dart';
import '../../providers/settings_provider.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class AskScreen extends StatefulWidget {
  const AskScreen({super.key});

  @override
  State<AskScreen> createState() => _AskScreenState();
}

class _AskScreenState extends State<AskScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    // Seed initial assistant greeting
    _messages.add(
      ChatMessage(
        text: 'नमस्ते! मैं आपका लेजर AI सहायक हूँ। आप व्यापार का हिसाब-किताब, आज की बिक्री, किसी पार्टी का बकाया, या स्टॉक की स्थिति पूछ सकते हैं।\n\nHello! I am your Ledgr AI assistant. Ask any question about party balances, today\'s sales, or stock availability.',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSubmitted(String query) {
    final clean = query.trim();
    if (clean.isEmpty) return;

    final ledger = Provider.of<LedgerProvider>(context, listen: false);
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    setState(() {
      _messages.add(
        ChatMessage(text: clean, isUser: true, timestamp: DateTime.now()),
      );
      _textController.clear();
    });
    _scrollToBottom();

    // Query Answer grounded strictly in app database facts
    final isHindi = settings.isHindi || _containsHindiOrHinglish(clean);
    final answer = ledger.answerUserQuery(clean, isHindi: isHindi);

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(text: answer, isUser: false, timestamp: DateTime.now()),
          );
        });
        _scrollToBottom();
      }
    });
  }

  bool _containsHindiOrHinglish(String text) {
    final lower = text.toLowerCase();
    return lower.contains('bhai') ||
        lower.contains('kitna') ||
        lower.contains('baaki') ||
        lower.contains('baki') ||
        lower.contains('aaj') ||
        lower.contains('karo') ||
        lower.contains('hai') ||
        lower.contains('ka') ||
        lower.contains('ki') ||
        lower.contains('रुपए');
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isHindi = settings.isHindi;

    final sampleChips = [
      "Ramesh Bhai ka kitna baaki hai?",
      "Aaj kitna sale hua?",
      "PVC roll ka stock kitna hai?",
      "Patel Bhai ka balance",
      "Kon se item ka stock kam hai?",
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.tabAsk),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: '100% Database Grounded Answers',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All answers are calculated directly from your ledger database. Never hallucinated.'),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // QUICK QUESTION CHIPS
          Container(
            height: 48,
            color: Colors.white,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              itemCount: sampleChips.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final chip = sampleChips[index];
                return ActionChip(
                  label: Text(
                    chip,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: AppColors.primaryContainer.withOpacity(0.5),
                  side: const BorderSide(color: AppColors.border),
                  onPressed: () => _handleSubmitted(chip),
                );
              },
            ),
          ),
          const Divider(height: 1),

          // CHAT MESSAGES LIST
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),

          // INPUT BAR (TEXT + VOICE MIC)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Hold/Tap Voice Question Button
                  IconButton(
                    icon: Icon(
                      _isSpeaking ? Icons.mic : Icons.mic_none,
                      color: _isSpeaking ? AppColors.micRecording : AppColors.primary,
                      size: 28,
                    ),
                    onPressed: () {
                      // Demo voice sample trigger
                      setState(() => _isSpeaking = !_isSpeaking);
                      if (_isSpeaking) {
                        _handleSubmitted("Ramesh Bhai ka kitna baaki hai?");
                        setState(() => _isSpeaking = false);
                      }
                    },
                  ),
                  const SizedBox(width: 4),

                  // Text Field
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        hintText: isHindi
                            ? 'यहाँ पूछें... (उदा. रमेश भाई का कितना बाकी है?)'
                            : 'Ask a question... (e.g. Ramesh Bhai ka kitna baaki hai?)',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                      onSubmitted: _handleSubmitted,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Send Button
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary,
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: () => _handleSubmitted(_textController.text),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser ? null : Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: TextStyle(
                fontSize: 16,
                height: 1.4,
                color: isUser ? Colors.white : AppColors.textPrimary,
                fontWeight: isUser ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 11,
                color: isUser ? Colors.white.withOpacity(0.7) : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
