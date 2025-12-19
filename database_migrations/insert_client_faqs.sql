-- Insert Client FAQs into faqs table
-- Total: 23 FAQs across 8 categories
-- Generated from client-provided FAQ PDF

-- Clear existing FAQs (optional - comment out if you want to keep existing)
-- DELETE FROM faqs;

-- Category: About Be Smart
INSERT INTO faqs (question, answer, category, order_index) VALUES
(
  'What is Be Smart?',
  'Be Smart is a trusted shopping brand that began as a fashion boutique. We have now expanded into a full online mall offering fashion, electronics, beauty items, home items, accessories, and more.',
  'about',
  1
),
(
  'Is Be Smart a store or a marketplace?',
  'Be Smart is both a brand store and a marketplace. We still sell our own products, and we also allow verified sellers to list items on our mall.',
  'about',
  2
);

-- Category: Ordering and Shopping
INSERT INTO faqs (question, answer, category, order_index) VALUES
(
  'Do I need an account to shop?',
  'Yes. Guest checkout is not allowed. Every customer must create an account to place orders, track deliveries, and access secure payments.',
  'ordering',
  3
),
(
  'How do I place an order?',
  E'- Create or log into your Be Smart account\n- Browse products\n- Add items to your cart\n- Enter your delivery address\n- Complete payment\n- Receive your order confirmation',
  'ordering',
  4
),
(
  'Can I buy from different sellers in one order?',
  'Yes. You can shop from multiple sellers in a single order. Delivery may come in separate packages.',
  'ordering',
  5
),
(
  'Do you offer installment payment or "buy now, pay later"?',
  'No. Be Smart does not support installment payments. All orders must be fully paid at checkout.',
  'ordering',
  6
);

-- Category: Payments
INSERT INTO faqs (question, answer, category, order_index) VALUES
(
  'What payment methods do you accept?',
  'Be Smart accepts debit cards, credit cards, bank transfers, USSD, and verified online payment gateways. Note: We do not offer a wallet system.',
  'payments',
  7
),
(
  'What additional payment features are unlocked after KYC?',
  E'After KYC verification, customers get access to:\n- Higher payment limits\n- Additional payment channels\n- Faster refund processing\n- Extra fraud protection',
  'payments',
  8
),
(
  'Why is KYC required?',
  'KYC helps verify identity, prevent fraud, protect buyers and sellers, and comply with financial regulations.',
  'payments',
  9
),
(
  'Are my payments secure?',
  'Yes. All payments are protected with secure, encrypted gateways and industry-standard security systems.',
  'payments',
  10
);

-- Category: Shipping and Delivery
INSERT INTO faqs (question, answer, category, order_index) VALUES
(
  'Do you deliver to all locations?',
  'Yes. Be Smart delivers to all locations nationwide, including cities, towns, and remote areas.',
  'shipping',
  11
),
(
  'How long does delivery take?',
  E'- Same city: 1 to 2 days\n- Nationwide: 2 to 7 days\n- Special items: delivery time may vary and will be shown at checkout',
  'shipping',
  12
),
(
  'How are delivery fees calculated?',
  'Delivery fees depend on location, weight, size of the product, and the seller''s location. The correct fee will appear at checkout.',
  'shipping',
  13
),
(
  'Can I track my order?',
  'Yes. You can track your order from your account dashboard once it has been shipped.',
  'shipping',
  14
);

-- Category: Returns and Refunds
INSERT INTO faqs (question, answer, category, order_index) VALUES
(
  'What is your return policy?',
  E'Items can be returned within 24 to 72 hours if:\n- The wrong item was delivered\n- The item is damaged\n- The item is defective\n- The item is not as described',
  'returns',
  15
),
(
  'How do I request a return or refund?',
  E'- Go to your Orders\n- Select the product\n- Click Request Return or Refund\n- Upload evidence\n- Submit for review',
  'returns',
  16
),
(
  'How long do refunds take?',
  'Refunds to a bank account typically take 1 to 3 working days. Some gateway refunds may take up to 7 days depending on the provider.',
  'returns',
  17
);

-- Category: Account and Security
INSERT INTO faqs (question, answer, category, order_index) VALUES
(
  'How do I create a Be Smart account?',
  'Click Sign Up, enter your details, verify your contact information, and your account will be created.',
  'account',
  18
),
(
  'Is my personal information safe?',
  'Yes. Be Smart uses strict data protection and encryption methods to keep your information secure.',
  'account',
  19
);

-- Category: Sellers and Vendors
INSERT INTO faqs (question, answer, category, order_index) VALUES
(
  'Can other sellers join the Be Smart mall?',
  'Yes. Verified vendors can apply to list products on the platform.',
  'sellers',
  20
),
(
  'What is required to join as a seller?',
  E'Sellers need:\n- Valid identification\n- Business or personal details\n- Product information\n- Bank details\n- KYC verification',
  'sellers',
  21
),
(
  'What tools do sellers receive?',
  'Sellers get a dashboard where they can upload products, manage inventory, process orders, track sales, and respond to customer messages.',
  'sellers',
  22
);

-- Category: Customer Support
INSERT INTO faqs (question, answer, category, order_index) VALUES
(
  'How can I contact Be Smart support?',
  'Support is available through:\n- Live chat\n- Email\n- WhatsApp\n- Phone\n- The in-app help center',
  'support',
  23
);

