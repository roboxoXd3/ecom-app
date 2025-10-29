# Google Play Store Account Deletion Policy - Compliance Documentation

**App Name:** Be Smart E-commerce  
**Date:** October 29, 2025  
**Status:** ✅ COMPLIANT  
**Policy Version:** 1.0

---

## Executive Summary

This document provides comprehensive information about the account deletion feature implemented in the Be Smart mobile application, ensuring full compliance with Google Play Store's Account Deletion Policy requirements.

**Compliance Status:** ✅ FULLY COMPLIANT

---

## Google Play Store Requirements Checklist

### ✅ 1. In-App Account Deletion
**Requirement:** Users must be able to initiate account deletion directly within the app.

**Implementation:**
- **Location:** Profile Tab → Settings Icon → Privacy Settings → Danger Zone → Delete Account
- **Path:** Users can access the deletion feature through the app's settings menu
- **User Flow:**
  1. Open Be Smart app
  2. Tap Profile tab (bottom navigation)
  3. Tap Settings icon (top right)
  4. Select "Privacy Settings"
  5. Scroll to "Danger Zone" section
  6. Tap "Delete Account"
  7. Review what will be deleted/retained
  8. Confirm understanding with checkboxes
  9. Enter password for verification
  10. Confirm final deletion

**Files:**
- `/lib/features/presentation/screens/profile/privacy_settings_screen.dart` - Entry point
- `/lib/features/presentation/screens/profile/delete_account_screen.dart` - Full deletion flow
- `/lib/core/services/account_deletion_service.dart` - Backend logic

---

### ✅ 2. Web-Based Account Deletion
**Requirement:** A web resource must be available for users to delete their accounts without needing to reinstall the app.

**Implementation:**
- **URL:** `https://[yourdomain.com]/account/delete`
- **Accessibility:** Public page, accessible without app installation
- **Features:**
  - User authentication check
  - Same deletion flow as mobile app
  - Password verification
  - Clear information about data deletion
  - Confirmation dialogs

**File:**
- `/ecomWebsite/app/account/delete/page.js`

---

### ✅ 3. Comprehensive Data Deletion
**Requirement:** Upon account deletion, all associated user data should be removed from servers. Any data retained must be clearly disclosed.

**Implementation:**

#### Data That Gets DELETED:
✅ Personal information (name, phone number, profile picture)  
✅ Shipping addresses  
✅ Payment methods  
✅ Wishlist items  
✅ Shopping cart  
✅ Chat messages and conversations  
✅ Search history  
✅ Loyalty points, rewards, and badges  
✅ Currency preferences  
✅ Account credentials (email and password)

#### Data That Gets ANONYMIZED (Retained for Legal Compliance):
⚠️ **Order history** - Anonymized with "Deleted User" placeholder  
⚠️ **Transaction records** - Required for tax/legal compliance

**Justification for Retention:**
- Legal requirement for tax audits (typically 7 years)
- Financial reporting and accounting
- Fraud prevention and investigation
- Regulatory compliance
- All retained data is completely anonymized and cannot be linked to the user

**Database Implementation:**
- File: `/ecom_app/database_migrations/account_deletion_function.sql`
- PostgreSQL function: `delete_user_account(user_uuid UUID)`
- Proper FK cascade handling to prevent orphaned data
- Transaction-based deletion with rollback on error

---

### ✅ 4. Clear Disclosure
**Requirement:** The app's Data Safety section on the Play Store should transparently inform users about data deletion practices.

**Implementation:**

#### Privacy Policy
- **Location:** `https://[yourdomain.com]/privacy-policy`
- **Section:** Section 7 - Account Deletion
- **Content:** Comprehensive explanation of:
  - How to delete account (in-app and web)
  - What data gets deleted
  - What data gets anonymized and why
  - Important notes and restrictions

**File:**
- `/ecomWebsite/app/privacy-policy/page.js` - Updated with Section 7

#### In-App Disclosure
- Deletion screen shows complete list of data categories
- Separate sections for deleted vs. anonymized data
- Explanation of legal retention requirements
- Multiple confirmation checkboxes

---

## Additional Features

### Vendor Account Protection
- **Feature:** Blocks deletion for active vendor accounts
- **Reason:** Prevents disruption to customer orders and marketplace integrity
- **User Guidance:** Clear error message directing to support for vendor account closure

### Password Verification
- **Feature:** Requires password re-entry before deletion
- **Reason:** Prevents accidental or unauthorized account deletion
- **Security:** Additional layer of protection for user accounts

### Multiple Confirmations
- **Feature:** Multi-step confirmation process
- **Steps:**
  1. Review deletion information
  2. Checkbox confirmations (2 required)
  3. Password entry
  4. Final confirmation dialog

### Grace Period for Backups
- **Feature:** 30-day backup retention period
- **Disclosure:** Clearly stated in privacy policy
- **Purpose:** Technical requirement for backup systems

---

## Technical Architecture

### Database Function
```sql
-- PostgreSQL Function
CREATE OR REPLACE FUNCTION delete_user_account(user_uuid UUID)
RETURNS JSON
```

**Features:**
- Vendor status check
- Proper FK cascade order
- Transaction-based with rollback
- Comprehensive error handling
- Order anonymization (not deletion)

### API Endpoint
```
POST /api/account/delete
Authorization: Bearer {token}
Body: { "password": "user_password" }
```

**Features:**
- JWT token verification
- Password validation
- Vendor blocking
- Calls database function
- Deletes auth user via Supabase Admin API

### Flutter Service
```dart
class AccountDeletionService
```

**Methods:**
- `checkDeletionEligibility()` - Verify if user can delete
- `deleteAccount()` - Execute deletion
- `verifyPassword()` - Security verification
- `getDeletionInfo()` - Information for UI

---

## User Experience Flow

### In-App Flow
```
Profile Tab
  └─ Settings Icon
      └─ Privacy Settings
          └─ Danger Zone Section
              └─ Delete Account Button
                  └─ Delete Account Screen
                      ├─ Warning Card
                      ├─ What Will Be Deleted
                      ├─ What Will Be Retained
                      ├─ Confirmation Checkboxes
                      ├─ Password Entry
                      └─ Delete Button
                          └─ Final Confirmation Dialog
                              └─ Success → Sign Out → Login Screen
```

### Web Flow
```
Visit /account/delete
  └─ Login Check (redirect if not logged in)
      └─ Deletion Form
          ├─ Warning Alert
          ├─ Eligibility Check
          ├─ Data Deletion Info
          ├─ Confirmation Checkboxes
          ├─ Password Entry
          └─ Delete Button
              └─ Final Confirmation
                  └─ Success → Sign Out → Home
```

---

## Screenshots Guide

### Required Screenshots for Play Store Submission

1. **Entry Point - Privacy Settings**
   - Path: Profile → Settings → Privacy Settings
   - Highlight: "Danger Zone" section with "Delete Account" button

2. **Delete Account Screen - Top**
   - Warning card visible
   - "What Will Be Deleted" section

3. **Delete Account Screen - Middle**
   - "What Will Be Retained" section
   - Confirmation checkboxes

4. **Delete Account Screen - Bottom**
   - Password entry field
   - Delete button
   - Cancel button

5. **Final Confirmation Dialog**
   - Warning message
   - "Yes, Delete My Account" button

6. **Web Deletion Page**
   - Screenshot of https://[yourdomain.com]/account/delete
   - Show full page with form

---

## Testing Checklist

### Functional Testing
- [x] In-app deletion flow works end-to-end
- [x] Web deletion flow works end-to-end
- [x] Password verification works correctly
- [x] Vendor account blocking works
- [x] Personal data is deleted from database
- [x] Order data is anonymized (not deleted)
- [x] User is signed out after deletion
- [x] Cannot login with deleted account

### Edge Cases
- [x] Deletion with active orders
- [x] Deletion with no order history
- [x] Deletion with no addresses/payment methods
- [x] Vendor account blocking message
- [x] Incorrect password handling
- [x] Network error handling

### Security Testing
- [x] Password required for deletion
- [x] JWT token verification
- [x] Unauthorized deletion attempts blocked
- [x] Database transaction rollback on error

---

## Play Store Data Safety Declaration

### When filling out the Data Safety form:

**Account Deletion Section:**

1. **Does your app allow users to request that their data be deleted?**
   - ✅ YES

2. **How can users request deletion?**
   - ✅ Within the app
   - ✅ Via a website URL

3. **Website URL for account deletion:**
   - `https://[yourdomain.com]/account/delete`

4. **In-app deletion path:**
   - Profile → Settings → Privacy Settings → Delete Account

5. **What data is deleted?**
   - All personal information
   - User-generated content (wishlist, cart, messages)
   - Account credentials

6. **What data is retained?**
   - Anonymized order history for legal compliance
   - Explain: Required for tax reporting and regulatory compliance

---

## Compliance Certification

✅ **In-App Deletion:** Implemented and tested  
✅ **Web Deletion:** Implemented and tested  
✅ **Data Deletion:** Comprehensive with clear disclosure  
✅ **Transparency:** Privacy policy updated with Section 7  
✅ **User Control:** Multi-step confirmation process  
✅ **Security:** Password verification required  
✅ **Legal Compliance:** Order anonymization for regulatory requirements

**Certification Date:** October 29, 2025  
**Certified By:** Development Team  
**Version:** 1.0

---

## Support Information

**For Questions About Account Deletion:**
- Email: support@besmart.com
- In-App: Profile → Help & Support
- Privacy Policy: https://[yourdomain.com]/privacy-policy (Section 7)

**For Vendor Account Closure:**
- Contact support before attempting account deletion
- Email: support@besmart.com

---

## Appendix A: Database Tables Affected

### Tables with Data DELETED:
- `chat_messages`
- `chat_analytics`
- `conversation_context`
- `chat_conversations`
- `cart_items`
- `carts`
- `wishlist`
- `search_analytics`
- `payment_methods`
- `other_payment_methods`
- `shipping_addresses`
- `vendor_follows`
- `vendor_reviews`
- `loyalty_points`
- `loyalty_transactions`
- `user_badges`
- `loyalty_vouchers`
- `user_currency_preferences`

### Tables with Data ANONYMIZED:
- `orders` - customer_name, customer_email, customer_phone set to placeholder values
- `profiles` - marked as deleted with placeholder name

### Auth System:
- `auth.users` - User account deleted via Supabase Admin API

---

## Appendix B: Related Files

### Mobile App (Flutter)
```
/lib/core/services/account_deletion_service.dart
/lib/features/presentation/screens/profile/delete_account_screen.dart
/lib/features/presentation/screens/profile/privacy_settings_screen.dart
```

### Web Application (Next.js)
```
/ecomWebsite/app/api/account/delete/route.js
/ecomWebsite/app/account/delete/page.js
/ecomWebsite/app/privacy-policy/page.js
```

### Database
```
/ecom_app/database_migrations/account_deletion_function.sql
```

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | October 29, 2025 | Initial implementation - Full compliance with Google Play Store policy |

---

**Document Status:** ✅ READY FOR PLAY STORE SUBMISSION

This documentation should be included with your Play Store submission to demonstrate compliance with the Account Deletion Policy.

