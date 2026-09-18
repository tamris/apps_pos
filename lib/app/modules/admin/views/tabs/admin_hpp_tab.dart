import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:noli_apps/app/core/theme/app_colors.dart';
import 'package:noli_apps/app/modules/admin/controllers/admin_controller.dart';
import '../widgets/hpp/hpp_health_banner.dart';
import '../widgets/hpp/ai_recipe_generator_box.dart';
import '../widgets/hpp/hpp_simulation_panel.dart';

class AdminHppTab extends GetView<AdminController> {
  const AdminHppTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: RefreshIndicator(
        color: AppColors.secondary,
        onRefresh: () async {
          await Future.wait([
            controller.fetchHppSummary(),
            controller.fetchAdminProductCategories(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Health Check KPI & Alert Banner
              HppHealthBanner(controller: controller),

              // 2. Gemini AI Recipe Assistant Box
              AiRecipeGeneratorBox(controller: controller),

              // 3. Interactive HPP Simulation & 3-Tier Pricing Panel
              HppSimulationPanel(controller: controller),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
