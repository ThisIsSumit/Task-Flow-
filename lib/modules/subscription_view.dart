import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:todo_app/data/services/subscription_service.dart';

class SubscriptionView extends StatelessWidget {
  const SubscriptionView({super.key});

  @override
  Widget build(BuildContext context) {
    final subscriptionService = Get.find<SubscriptionService>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Upgrade to Premium')),
      body: Obx(
        () => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Unlock Task Automation',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Premium unlocks an AI automation agent that can run custom task instructions before deadlines.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            const _BenefitTile(
              icon: Icons.auto_awesome,
              title: 'Run custom task instructions automatically',
            ),
            const _BenefitTile(
              icon: Icons.email_outlined,
              title: 'Draft or execute smart outputs (email, summary, notes)',
            ),
            const _BenefitTile(
              icon: Icons.description_outlined,
              title: 'Choose suggest mode or execute mode per task',
            ),
            const _BenefitTile(
              icon: Icons.video_call_outlined,
              title: 'Flexible automation, not limited to fixed templates',
            ),
            const SizedBox(height: 20),
            if (subscriptionService.isPremium.value)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Premium is active on this account. You can now enable automation when creating or editing tasks.',
                ),
              )
            else if (!subscriptionService.supportsInAppPurchase)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'In-app purchases are available on Android and iOS. Run the mobile app with store products configured to complete subscription checkout.',
                ),
              )
            else if (!subscriptionService.isStoreAvailable.value)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Store connection is unavailable. Verify Play Store / App Store product setup and device account access.',
                ),
              )
            else ...[
              ...subscriptionService.products.map(
                (product) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PlanCard(
                    product: product,
                    isBusy: subscriptionService.isPurchasePending.value,
                    onSubscribe:
                        () => subscriptionService.purchasePremium(product),
                  ),
                ),
              ),
              TextButton(
                onPressed:
                    subscriptionService.isPurchasePending.value
                        ? null
                        : subscriptionService.restorePurchases,
                child: const Text('Restore Purchases'),
              ),
            ],
            if (subscriptionService.errorMessage.value.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                subscriptionService.errorMessage.value,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BenefitTile extends StatelessWidget {
  final IconData icon;
  final String title;

  const _BenefitTile({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final ProductDetails product;
  final bool isBusy;
  final VoidCallback onSubscribe;

  const _PlanCard({
    required this.product,
    required this.isBusy,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(product.description),
            const SizedBox(height: 10),
            Text(product.price, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isBusy ? null : onSubscribe,
                child:
                    isBusy
                        ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Text('Subscribe'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
