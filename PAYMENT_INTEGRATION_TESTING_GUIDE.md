# Payment Integration Testing Guide
## Squad API Integration - Flutter Mobile App

---

## 🚀 **Quick Start Testing**

### **Prerequisites**
1. ✅ Squad API credentials (sandbox/test keys)
2. ✅ Supabase database with payment fields migration
3. ✅ Flutter dependencies installed
4. ✅ Test user account created

### **Environment Setup**
```bash
# 1. Install dependencies
flutter pub get

# 2. Set up environment variables in .env
SQUAD_PUBLIC_KEY=pk_test_your_squad_public_key
SQUAD_SECRET_KEY=sk_test_your_squad_secret_key
SQUAD_BASE_URL=https://sandbox-api-d.squadco.com
SQUAD_WEBHOOK_SECRET=your_webhook_secret

# 3. Run database migration
# Execute add_squad_payment_fields.sql in Supabase SQL editor

# 4. Build and run the app
flutter run
```

---

## 🧪 **Test Scenarios**

### **1. Cash on Delivery (COD) Flow**
**Expected Behavior:** Order created immediately without payment gateway

**Test Steps:**
1. Add items to cart
2. Navigate to checkout
3. Select delivery address
4. Choose "Cash on Delivery"
5. Tap "Confirm Order"

**✅ Success Criteria:**
- Order created with status "pending"
- Payment status set to "pending"
- Escrow status set to "none"
- User redirected to order confirmation
- Cart cleared after successful order

**🔍 Debug Points:**
```dart
// Check console logs for:
print('OrderController: Creating order with ${items.length} items');
print('OrderController: Order created successfully');
```

---

### **2. Card Payment Flow**
**Expected Behavior:** WebView opens with Squad payment gateway

**Test Steps:**
1. Add items to cart
2. Navigate to checkout
3. Select delivery address
4. Choose "Credit/Debit Card"
5. Tap "Pay Now"
6. Complete payment in WebView

**✅ Success Criteria:**
- Squad payment initiation successful
- WebView opens with checkout URL
- Payment completion detected
- Order created with payment details
- Payment status set to "completed"
- Escrow status set to "held"

**🔍 Debug Points:**
```dart
// Check console logs for:
print('Initiating Squad payment...');
print('Amount: ${total}');
print('Transaction Ref: ${currentTransactionRef.value}');
print('Squad Payment Response: ${response.statusCode} - ${response.body}');
```

---

### **3. UPI Payment Flow**
**Expected Behavior:** UPI-specific payment channels used

**Test Steps:**
1. Follow card payment steps but select "UPI Payment"
2. Verify payment channels are set to ['transfer']

**✅ Success Criteria:**
- Payment initiated with transfer channel only
- UPI apps available for payment
- Payment completion handled correctly

---

### **4. Payment Verification System**
**Expected Behavior:** Automatic verification of pending payments

**Test Steps:**
1. Initiate payment but don't complete it
2. Wait for periodic verification (2 minutes)
3. Complete payment externally
4. Verify status updates automatically

**✅ Success Criteria:**
- Pending payments added to verification queue
- Periodic verification runs every 2 minutes
- Payment status updates when completed
- User receives notification of status change

**🔍 Debug Points:**
```dart
// Check console logs for:
print('Added $transactionRef to pending verification queue');
print('Verifying ${_pendingVerifications.length} pending payments...');
print('Payment verified and order updated: ${order.id}');
```

---

### **5. Payment Failure Handling**
**Expected Behavior:** Failed payments handled gracefully

**Test Steps:**
1. Initiate payment
2. Cancel or fail payment in WebView
3. Verify error handling

**✅ Success Criteria:**
- Payment failure detected
- User shown appropriate error message
- Cart items preserved
- Order not created for failed payments
- User can retry payment

---

### **6. Payment Cancellation**
**Expected Behavior:** User can cancel payment process

**Test Steps:**
1. Initiate payment
2. Tap close/cancel in WebView
3. Confirm cancellation in dialog

**✅ Success Criteria:**
- Cancellation dialog appears
- Payment process stops
- User returned to checkout
- Cart items preserved
- No order created

---

## 🔧 **Testing Tools & Commands**

### **Flutter Testing Commands**
```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/

# Run with verbose logging
flutter run --verbose

# Build release APK for testing
flutter build apk --release
```

### **Debug Console Commands**
```dart
// In Flutter app, check these logs:
print('Squad Payment Request: ${jsonEncode(body)}');
print('Squad Payment Response: ${response.statusCode} - ${response.body}');
print('Payment result: $result');
print('OrderController: Creating order with payment details');
```

### **Supabase Database Queries**
```sql
-- Check orders with payment details
SELECT 
  id, 
  total, 
  status, 
  payment_status, 
  escrow_status,
  squad_transaction_ref,
  created_at
FROM orders 
ORDER BY created_at DESC 
LIMIT 10;

-- Check payment analytics
SELECT * FROM payment_analytics;

-- Check pending payments
SELECT * FROM orders 
WHERE payment_status = 'pending' 
  AND squad_transaction_ref IS NOT NULL;
```

---

## 🐛 **Common Issues & Solutions**

### **Issue 1: Payment Gateway Not Loading**
**Symptoms:** WebView shows blank page or error
**Solutions:**
- Check Squad API credentials
- Verify internet connection
- Check console for network errors
- Ensure Squad base URL is correct

### **Issue 2: Payment Verification Fails**
**Symptoms:** Payment completed but order not updated
**Solutions:**
- Check transaction reference matching
- Verify Squad webhook configuration
- Check periodic verification is running
- Manually verify payment status

### **Issue 3: Database Errors**
**Symptoms:** Order creation fails with database errors
**Solutions:**
- Run database migration script
- Check Supabase connection
- Verify user authentication
- Check table permissions

### **Issue 4: WebView Navigation Issues**
**Symptoms:** Payment redirects not working
**Solutions:**
- Check callback URL configuration
- Verify navigation delegate logic
- Test with different payment methods
- Check URL pattern matching

---

## 📊 **Performance Testing**

### **Load Testing Scenarios**
1. **Multiple Concurrent Payments**
   - Test 10+ simultaneous payment initiations
   - Verify no transaction reference conflicts
   - Check database performance

2. **Payment Verification Load**
   - Add 50+ pending payments
   - Monitor periodic verification performance
   - Check memory usage

3. **WebView Performance**
   - Test payment gateway loading times
   - Monitor memory usage during payment
   - Check for memory leaks

---

## 🔒 **Security Testing**

### **Security Checklist**
- [ ] API keys not exposed in logs
- [ ] Webhook signature validation working
- [ ] Transaction references are unique
- [ ] Payment amounts cannot be manipulated
- [ ] User can only access own orders
- [ ] Sensitive data encrypted in database

### **Security Test Cases**
1. **API Key Exposure**
   - Check app logs for exposed keys
   - Verify keys not in source code
   - Test with invalid keys

2. **Payment Amount Tampering**
   - Try modifying payment amounts
   - Verify server-side validation
   - Check order total consistency

3. **Transaction Reference Manipulation**
   - Test with duplicate references
   - Verify uniqueness constraints
   - Check reference validation

---

## 📱 **Device Testing Matrix**

### **Android Testing**
- [ ] Android 8+ (API 26+)
- [ ] Different screen sizes
- [ ] Various network conditions
- [ ] Background/foreground transitions

### **iOS Testing**
- [ ] iOS 12+ 
- [ ] iPhone and iPad
- [ ] Different network conditions
- [ ] App backgrounding during payment

---

## 📈 **Monitoring & Analytics**

### **Key Metrics to Track**
1. **Payment Success Rate**
   - Successful payments / Total attempts
   - Target: >95%

2. **Payment Completion Time**
   - Time from initiation to completion
   - Target: <2 minutes average

3. **Error Rates**
   - Payment failures / Total attempts
   - Target: <5%

4. **User Drop-off Points**
   - Where users abandon payment
   - Optimize high drop-off points

### **Monitoring Queries**
```sql
-- Payment success rate (last 7 days)
SELECT 
  payment_status,
  COUNT(*) as count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM orders 
WHERE created_at >= NOW() - INTERVAL '7 days'
  AND squad_transaction_ref IS NOT NULL
GROUP BY payment_status;

-- Average payment completion time
SELECT 
  AVG(EXTRACT(EPOCH FROM (updated_at - created_at))/60) as avg_minutes
FROM orders 
WHERE payment_status = 'completed'
  AND created_at >= NOW() - INTERVAL '7 days';
```

---

## ✅ **Final Testing Checklist**

### **Before Production Release**
- [ ] All test scenarios pass
- [ ] Database migration applied
- [ ] Production API keys configured
- [ ] Webhook endpoints configured
- [ ] Error handling tested
- [ ] Performance benchmarks met
- [ ] Security tests passed
- [ ] Device compatibility verified
- [ ] Analytics tracking working
- [ ] User acceptance testing completed

### **Production Deployment**
- [ ] Switch to production Squad API keys
- [ ] Update webhook URLs to production
- [ ] Enable production logging
- [ ] Set up monitoring alerts
- [ ] Prepare rollback plan
- [ ] Document known issues
- [ ] Train support team

---

## 🆘 **Support & Troubleshooting**

### **Log Files to Check**
1. Flutter console output
2. Supabase logs
3. Squad API response logs
4. Device system logs

### **Key Information for Support**
- Transaction reference
- User ID
- Order ID
- Payment method used
- Error messages
- Device information
- App version

### **Emergency Procedures**
1. **Payment Gateway Down**
   - Switch to COD only mode
   - Display maintenance message
   - Queue payments for retry

2. **Database Issues**
   - Enable read-only mode
   - Cache critical data
   - Implement graceful degradation

3. **High Error Rates**
   - Enable detailed logging
   - Implement circuit breaker
   - Notify development team

---

**Last Updated:** $(date)
**Version:** 1.0.0
**Author:** Payment Integration Team
