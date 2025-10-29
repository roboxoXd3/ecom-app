# Account Deletion Feature - Testing Guide

**Feature:** Account Deletion (Google Play Store Compliance)  
**Date:** October 29, 2025  
**Status:** Ready for Testing

---

## Pre-Testing Setup

### 1. Apply Database Migration

**IMPORTANT:** Run the database migration first before testing.

```sql
-- Connect to your Supabase project SQL Editor
-- Copy and paste the contents of:
-- /ecom_app/database_migrations/account_deletion_function.sql

-- Or use Supabase CLI:
supabase db push
```

**Verify Migration:**
```sql
-- Check if functions exist
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_name IN ('delete_user_account', 'is_active_vendor');
```

### 2. Environment Variables

**Web Application (.env.local):**
```env
NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
```

**Flutter App:**
- Ensure Supabase configuration is set in `main.dart`

### 3. Test Accounts

Create the following test accounts:

**Test Account 1: Regular Customer**
- Email: `test.customer@example.com`
- Has: Orders, addresses, wishlist items
- Purpose: Test standard account deletion

**Test Account 2: Customer Without Orders**
- Email: `test.newuser@example.com`
- Has: No orders, basic profile only
- Purpose: Test deletion with minimal data

**Test Account 3: Vendor Account**
- Email: `test.vendor@example.com`
- Has: Vendor status approved + products
- Purpose: Test vendor blocking

**Test Account 4: Former Vendor**
- Email: `test.formervendor@example.com`
- Has: Vendor status rejected/suspended, no products
- Purpose: Test deletion of non-active vendor

---

## Test Scenarios

### Scenario 1: Standard Customer Account Deletion ✅

**Setup:**
- Login as `test.customer@example.com`
- Ensure account has:
  - At least 2 orders (completed)
  - 2-3 shipping addresses
  - 1-2 payment methods
  - 5+ wishlist items
  - Chat messages

**Steps:**
1. Open app and navigate to Profile tab
2. Tap Settings icon (top right)
3. Select "Privacy Settings"
4. Scroll to "Danger Zone" section
5. Tap "Delete Account"
6. Verify deletion screen shows:
   - Warning card
   - List of data to be deleted
   - List of data to be anonymized
7. Check both confirmation checkboxes
8. Enter password: `[account_password]`
9. Tap "Delete My Account Permanently"
10. Confirm in final dialog

**Expected Results:**
- ✅ Account deleted successfully message appears
- ✅ User is automatically signed out
- ✅ Redirected to login screen
- ✅ Cannot login with deleted credentials

**Database Verification:**
```sql
-- Run these queries after deletion
-- Replace USER_ID with the deleted user's ID

-- Check profile (should be marked deleted)
SELECT id, full_name, is_deleted 
FROM profiles 
WHERE id = 'USER_ID';
-- Expected: full_name = 'Deleted User', is_deleted = true

-- Check auth user (should not exist)
SELECT id, email 
FROM auth.users 
WHERE id = 'USER_ID';
-- Expected: No rows

-- Check orders (should be anonymized)
SELECT id, customer_name, customer_email 
FROM orders 
WHERE user_id = 'USER_ID';
-- Expected: customer_name = 'Deleted User', customer_email = 'deleted@user.com'

-- Check personal data deleted
SELECT COUNT(*) FROM shipping_addresses WHERE user_id = 'USER_ID';
-- Expected: 0

SELECT COUNT(*) FROM payment_methods WHERE user_id = 'USER_ID';
-- Expected: 0

SELECT COUNT(*) FROM wishlist WHERE user_id = 'USER_ID';
-- Expected: 0

SELECT COUNT(*) FROM chat_messages WHERE sender_id = 'USER_ID';
-- Expected: 0

SELECT COUNT(*) FROM loyalty_points WHERE user_id = 'USER_ID';
-- Expected: 0
```

---

### Scenario 2: New User With No Orders ✅

**Setup:**
- Login as `test.newuser@example.com`
- Ensure account has NO orders

**Steps:**
1. Follow same deletion steps as Scenario 1

**Expected Results:**
- ✅ Deletion succeeds
- ✅ No orders to anonymize (none exist)
- ✅ User signed out successfully

**Database Verification:**
```sql
-- Check no orphaned data
SELECT COUNT(*) FROM profiles WHERE id = 'USER_ID' AND is_deleted = false;
-- Expected: 0

SELECT COUNT(*) FROM auth.users WHERE id = 'USER_ID';
-- Expected: 0
```

---

### Scenario 3: Active Vendor Blocking ❌ (Should FAIL)

**Setup:**
- Login as `test.vendor@example.com`
- Ensure vendor status is 'approved'
- Ensure vendor has at least 1 product

**Steps:**
1. Navigate to Profile → Settings → Privacy Settings → Delete Account
2. Observe eligibility check on deletion screen

**Expected Results:**
- ✅ Orange warning banner appears
- ✅ Message: "Cannot delete account while you have an active vendor account. Please contact support to close your vendor account first."
- ✅ Delete button is DISABLED
- ✅ Password field is DISABLED

**Database Verification:**
```sql
-- Verify vendor is active
SELECT id, user_id, status 
FROM vendors 
WHERE user_id = 'USER_ID';
-- Expected: status = 'approved'

SELECT COUNT(*) FROM products WHERE vendor_id = (
  SELECT id FROM vendors WHERE user_id = 'USER_ID'
);
-- Expected: > 0
```

---

### Scenario 4: Web-Based Deletion ✅

**Setup:**
- Use a web browser
- Have test account credentials ready

**Steps:**
1. Navigate to `https://[yourdomain.com]/account/delete`
2. If not logged in, redirected to login
3. Login with test credentials
4. Return to deletion page
5. Check both confirmation checkboxes
6. Enter password
7. Click "Delete My Account Permanently"
8. Confirm in browser dialog

**Expected Results:**
- ✅ Success message appears
- ✅ User signed out
- ✅ Redirected to home page
- ✅ Cannot login again

---

### Scenario 5: Incorrect Password ❌ (Should FAIL)

**Setup:**
- Login as any test customer

**Steps:**
1. Navigate to deletion screen
2. Check both confirmation checkboxes
3. Enter INCORRECT password
4. Tap delete button

**Expected Results:**
- ✅ Error message: "Incorrect password. Please try again."
- ✅ Account NOT deleted
- ✅ User still logged in

---

### Scenario 6: Missing Confirmations ❌ (Should FAIL)

**Setup:**
- Login as test customer

**Steps:**
1. Navigate to deletion screen
2. Enter correct password
3. Do NOT check confirmation boxes
4. Tap delete button

**Expected Results:**
- ✅ Error message: "Please confirm that you understand the consequences"
- ✅ Account NOT deleted

---

### Scenario 7: Network Error Handling 🔌

**Setup:**
- Login as test customer
- Turn off WiFi/data before confirming deletion

**Steps:**
1. Navigate to deletion screen
2. Fill in all fields correctly
3. Disable network connection
4. Tap delete button

**Expected Results:**
- ✅ Error message indicating network issue
- ✅ Loading state ends
- ✅ Can retry after enabling network

---

## API Testing

### Test API Endpoint Directly

**Check Eligibility (GET):**
```bash
curl -X GET 'https://[yourdomain.com]/api/account/delete' \
  -H 'Authorization: Bearer YOUR_JWT_TOKEN'
```

**Expected Response (Regular User):**
```json
{
  "canDelete": true,
  "isVendor": false,
  "message": "Your account is eligible for deletion."
}
```

**Expected Response (Vendor):**
```json
{
  "canDelete": false,
  "isVendor": true,
  "message": "Cannot delete account while you have an active vendor account..."
}
```

**Delete Account (POST):**
```bash
curl -X POST 'https://[yourdomain.com]/api/account/delete' \
  -H 'Authorization: Bearer YOUR_JWT_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{"password": "test_password"}'
```

**Expected Response (Success):**
```json
{
  "success": true,
  "message": "Your account has been successfully deleted..."
}
```

---

## Database Function Testing

### Test Functions Directly in SQL Editor

**Test is_active_vendor function:**
```sql
-- Test with regular customer
SELECT is_active_vendor('customer_user_id');
-- Expected: false

-- Test with active vendor
SELECT is_active_vendor('vendor_user_id');
-- Expected: true
```

**Test delete_user_account function:**
```sql
-- Test with test account
SELECT delete_user_account('test_user_id');
-- Expected: JSON with success: true
```

---

## Performance Testing

### Deletion Speed
- **Expected Time:** < 3 seconds for standard account
- **Expected Time:** < 5 seconds for account with 100+ orders

**Test:**
1. Create account with large amount of data:
   - 100+ orders
   - 50+ addresses
   - 200+ wishlist items
2. Time the deletion process

---

## Security Testing

### Test Unauthorized Deletion
```bash
# Try to delete another user's account
curl -X POST 'https://[yourdomain.com]/api/account/delete' \
  -H 'Authorization: Bearer USER_A_TOKEN' \
  -d '{"password": "user_b_password"}'
```

**Expected:** Should fail with unauthorized error

### Test Without Authentication
```bash
# Try without token
curl -X POST 'https://[yourdomain.com]/api/account/delete' \
  -H 'Content-Type: application/json' \
  -d '{"password": "test_password"}'
```

**Expected:** 401 Unauthorized

---

## Regression Testing

After account deletion, verify other features still work:

1. ✅ New user registration
2. ✅ Order placement by other users
3. ✅ Vendor product creation
4. ✅ Chat system
5. ✅ Loyalty program

---

## Test Data Cleanup

After testing, clean up test accounts:

```sql
-- List test accounts
SELECT id, email FROM auth.users WHERE email LIKE '%@example.com';

-- Delete test accounts (if needed for re-testing)
SELECT delete_user_account('test_user_id_1');
SELECT delete_user_account('test_user_id_2');
```

---

## Known Issues / Edge Cases

### Handled ✅
- Vendor account blocking
- No orders to anonymize
- Network failures
- Incorrect password
- Missing confirmations

### To Monitor 🔍
- Very large accounts (1000+ orders)
- Concurrent deletion attempts
- Deletion during active order placement

---

## Success Criteria

Account deletion feature is ready for production when:

- ✅ All 7 test scenarios pass
- ✅ Database verification queries return expected results
- ✅ API endpoints respond correctly
- ✅ Security tests pass (unauthorized attempts fail)
- ✅ Privacy policy is updated
- ✅ Play Store documentation is complete
- ✅ No data leaks or orphaned records

---

## Reporting Issues

If any test fails:

1. Document the failure:
   - Scenario number
   - Steps taken
   - Expected vs actual result
   - Screenshots/logs

2. Check logs:
   - **Flutter:** Device logs in Xcode/Android Studio
   - **API:** Supabase logs or server logs
   - **Database:** PostgreSQL error logs

3. Debug queries:
```sql
-- Check for orphaned data
SELECT 'profiles' as table_name, COUNT(*) 
FROM profiles 
WHERE id NOT IN (SELECT id FROM auth.users)

UNION ALL

SELECT 'orders', COUNT(*) 
FROM orders 
WHERE user_id NOT IN (SELECT id FROM auth.users)
AND customer_name != 'Deleted User';
```

---

## Post-Testing Checklist

Before submitting to Play Store:

- [ ] All test scenarios passed
- [ ] Database migration applied to production
- [ ] Environment variables configured
- [ ] Privacy policy live and updated
- [ ] Web deletion page accessible
- [ ] API endpoints secured and tested
- [ ] Screenshots taken for Play Store submission
- [ ] Documentation reviewed
- [ ] Backup and rollback plan ready

---

## Contact

For testing issues or questions:
- Development Team: [your-email@example.com]
- Documentation: `/ecom_app/PLAY_STORE_ACCOUNT_DELETION_POLICY.md`

---

**Testing Status:** ⏳ READY FOR EXECUTION

Run through all scenarios and update this document with results before Play Store submission.

