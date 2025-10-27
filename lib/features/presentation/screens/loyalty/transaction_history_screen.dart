import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/loyalty_controller.dart';

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final LoyaltyController controller = Get.find<LoyaltyController>();

    // Load transactions when screen is opened
    controller.loadTransactionHistory();

    return Scaffold(
      appBar: AppBar(title: const Text('Transaction History')),
      body: Obx(() {
        if (controller.isLoadingTransactions.value &&
            controller.transactions.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final transactions = controller.transactions;
        if (transactions.isEmpty) {
          return const Center(
            child: Text(
              'No transactions yet',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            return _buildTransactionItem(transaction);
          },
        );
      }),
    );
  }

  Widget _buildTransactionItem(transaction) {
    final isPositive = transaction.isPositive;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
                isPositive
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isPositive ? Icons.add : Icons.remove,
            color: isPositive ? Colors.green : Colors.red,
          ),
        ),
        title: Text(
          transaction.description,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              transaction.typeDisplayName,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 2),
            Text(
              _formatDate(transaction.createdAt),
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isPositive ? '+' : ''}${transaction.pointsChange}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isPositive ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Balance: ${transaction.pointsBalanceAfter}',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
