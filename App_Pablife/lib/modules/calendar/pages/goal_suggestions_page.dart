import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../widgets/app_text_vector.dart';
import '../../../widgets/design_system/text_default.dart';
import '../controllers/goal_suggestions_controller.dart';

class GoalSuggestionsPage extends StatelessWidget {
  const GoalSuggestionsPage({super.key});

  static const route = '/calendar/goal-suggestions';

  @override
  Widget build(BuildContext context) {
    return GetBuilder<GoalSuggestionsController>(
      builder: (controller) {
        return Scaffold(
          backgroundColor: const Color(0xFF00343C),
          body: Column(
            children: [
              const SizedBox(height: 32),
              _buildHeader(controller),
              const SizedBox(height: 20),
              Expanded(child: _buildContent(controller)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(GoalSuggestionsController controller) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: controller.goBack,
                child: Container(
                  width: 66,
                  height: 65,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
              const AppTextVector(width: 148, height: 45),
              Container(
                width: 66,
                height: 65,
                decoration: BoxDecoration(
                  color: const Color(0xFF0C8DA1),
                  border: Border.all(color: Colors.white, width: 1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Icon(Icons.lightbulb, color: Colors.white, size: 32),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const TextDefault(
          'Sugestões de Metas',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ],
    );
  }

  Widget _buildContent(GoalSuggestionsController controller) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(39),
        topRight: Radius.circular(39),
      ),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(color: Color(0xFFC1CDFF)),
        child: Column(
          children: [
            Expanded(
              child: controller.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF00343C),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(15, 10, 15, 80),
                      itemCount: controller.suggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = controller.suggestions[index];
                        return _buildSuggestionCard(suggestion, controller);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionCard(
    Map<String, dynamic> suggestion,
    GoalSuggestionsController controller,
  ) {
    return GestureDetector(
      onTap: () => controller.selectSuggestion(suggestion),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Color(suggestion['color'] ?? 0xFFCDDC39),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextDefault(
                  suggestion['category'] ?? 'Financeira',
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
                TextDefault(
                  suggestion['duration'] ?? '6 meses',
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              suggestion['title'] ?? 'Fundo de Emergência',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.1,
                fontFamily: 'Instrument Sans',
              ),
            ),
            const SizedBox(height: 15),
            TextDefault(
              suggestion['description'] ??
                  'Juntar dinheiro equivalente a 6 meses do q vc ganha!',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
