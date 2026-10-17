import 'package:flutter/material.dart';
import '../../../../core/theme/clinova_colors.dart';
import '../../../../shared/widgets/demo_banner.dart';
import '../../../../shared/widgets/neumorphic_card.dart';
import '../../../../shared/widgets/neumorphic_icon_container.dart';
import '../../../../shared/widgets/neumorphic_input.dart';

class PatientAiAssistantView extends StatefulWidget {
  const PatientAiAssistantView({super.key});

  @override
  State<PatientAiAssistantView> createState() => _PatientAiAssistantViewState();
}

class _PatientAiAssistantViewState extends State<PatientAiAssistantView> {
  final _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {
      "isUser": false,
      "text": "Hello, I’m the Clinova AI Assistant. I can help organize your health symptoms, suggest questions for your doctor, and prepare structured clinical case intake summaries.",
      "time": "Just now",
    },
  ];

  final List<String> _quickPrompts = [
    "I have a persistent cough and low fever",
    "What questions should I ask my doctor?",
    "Help me prepare my medication history",
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage([String? preset]) {
    final text = (preset ?? _messageController.text).trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({
        "isUser": true,
        "text": text,
        "time": "Just now",
      });
      _messageController.clear();
    });

    // Simulated assistant response
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        _messages.add({
          "isUser": false,
          "text": "Thank you for sharing. I am noting this symptom into your consultation intake record to assist your physician during clinical review.",
          "time": "Just now",
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DemoBanner(compact: true, margin: EdgeInsets.only(bottom: 16)),

            Row(
              children: [
                NeumorphicIconContainer(
                  size: 44,
                  iconSize: 22,
                  borderRadius: 14,
                  icon: Icons.smart_toy_outlined,
                  iconColor: ClinovaColors.primaryAccent,
                  isInset: true,
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "AI Health Assistant",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: ClinovaColors.primaryText,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "Interactive symptom intake & clinical preparation preview",
                        style: TextStyle(
                          fontSize: 12.5,
                          color: ClinovaColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Quick prompt chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _quickPrompts.map((prompt) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ActionChip(
                      label: Text(prompt),
                      backgroundColor: ClinovaColors.surfaceNeumorphic,
                      labelStyle: const TextStyle(
                        fontSize: 12,
                        color: ClinovaColors.primaryAccent,
                        fontWeight: FontWeight.w600,
                      ),
                      side: BorderSide(color: ClinovaColors.primaryAccent.withValues(alpha: 0.25)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onPressed: () => _sendMessage(prompt),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            // Message conversation container
            NeumorphicCard(
              padding: const EdgeInsets.all(18),
              borderRadius: 20,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _messages.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) {
                  final m = _messages[i];
                  final isUser = m["isUser"] as bool;

                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 520),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: isUser
                            ? ClinovaColors.primaryAccent
                            : ClinovaColors.inputRecessedFill,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Text(
                            m["text"] as String,
                            style: TextStyle(
                              fontSize: 13,
                              color: isUser ? Colors.white : ClinovaColors.primaryText,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            m["time"] as String,
                            style: TextStyle(
                              fontSize: 10,
                              color: isUser ? Colors.white70 : ClinovaColors.tertiaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),

            // Message input
            Row(
              children: [
                Expanded(
                  child: NeumorphicInput(
                    controller: _messageController,
                    label: "Health Question",
                    hint: "Ask a health question or describe symptoms...",
                    prefixIcon: Icons.chat_bubble_outline_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                NeumorphicIconContainer(
                  size: 52,
                  iconSize: 22,
                  borderRadius: 14,
                  icon: Icons.send_rounded,
                  iconColor: ClinovaColors.primaryAccent,
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, size: 20),
                    color: ClinovaColors.primaryAccent,
                    onPressed: () => _sendMessage(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
