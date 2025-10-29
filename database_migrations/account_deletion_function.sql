-- =====================================================
-- ACCOUNT DELETION FUNCTION - GOOGLE PLAY STORE COMPLIANCE
-- =====================================================
-- This function implements hybrid account deletion:
-- - Deletes personal information immediately
-- - Anonymizes order history for legal/tax compliance
-- - Blocks deletion for active vendors
-- 
-- Date: October 29, 2025
-- Compliance: Google Play Store Account Deletion Policy
-- =====================================================

-- Function to check if user is an active vendor
CREATE OR REPLACE FUNCTION is_active_vendor(user_uuid UUID)
RETURNS BOOLEAN AS $$
DECLARE
  vendor_exists BOOLEAN;
  has_products BOOLEAN;
BEGIN
  -- Check if user has a vendor record with approved status
  SELECT EXISTS(
    SELECT 1 FROM vendors 
    WHERE user_id = user_uuid 
    AND status IN ('approved', 'pending')
  ) INTO vendor_exists;
  
  -- Check if vendor has products
  SELECT EXISTS(
    SELECT 1 FROM products p
    INNER JOIN vendors v ON p.vendor_id = v.id
    WHERE v.user_id = user_uuid
  ) INTO has_products;
  
  RETURN vendor_exists OR has_products;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Main account deletion function
CREATE OR REPLACE FUNCTION delete_user_account(user_uuid UUID)
RETURNS JSON AS $$
DECLARE
  result JSON;
  rows_affected INTEGER := 0;
  cart_ids UUID[];
  vendor_id_value UUID;
BEGIN
  -- Start transaction
  BEGIN
    -- Step 1: Check if user is an active vendor
    IF is_active_vendor(user_uuid) THEN
      RETURN json_build_object(
        'success', false,
        'error', 'vendor_active',
        'message', 'Cannot delete account while you have an active vendor account. Please contact support to close your vendor account first.'
      );
    END IF;

    -- Step 2: Get vendor_id if exists for cleanup
    SELECT id INTO vendor_id_value FROM vendors WHERE user_id = user_uuid LIMIT 1;

    -- Step 3: Delete communication data
    -- Chat messages
    DELETE FROM chat_messages WHERE sender_id = user_uuid OR receiver_id = user_uuid;
    GET DIAGNOSTICS rows_affected = ROW_COUNT;
    RAISE NOTICE 'Deleted % chat messages', rows_affected;
    
    -- Chat analytics
    DELETE FROM chat_analytics WHERE user_id = user_uuid;
    GET DIAGNOSTICS rows_affected = ROW_COUNT;
    RAISE NOTICE 'Deleted % chat analytics', rows_affected;
    
    -- Conversation context
    DELETE FROM conversation_context WHERE user_id = user_uuid;
    GET DIAGNOSTICS rows_affected = ROW_COUNT;
    RAISE NOTICE 'Deleted % conversation contexts', rows_affected;
    
    -- Chat conversations (where user is participant)
    DELETE FROM chat_conversations 
    WHERE user_id = user_uuid OR vendor_id = vendor_id_value;
    GET DIAGNOSTICS rows_affected = ROW_COUNT;
    RAISE NOTICE 'Deleted % chat conversations', rows_affected;

    -- Step 4: Delete cart data
    -- Get cart IDs first
    SELECT ARRAY_AGG(id) INTO cart_ids FROM carts WHERE user_id = user_uuid;
    
    IF cart_ids IS NOT NULL THEN
      DELETE FROM cart_items WHERE cart_id = ANY(cart_ids);
      GET DIAGNOSTICS rows_affected = ROW_COUNT;
      RAISE NOTICE 'Deleted % cart items', rows_affected;
    END IF;
    
    DELETE FROM carts WHERE user_id = user_uuid;
    GET DIAGNOSTICS rows_affected = ROW_COUNT;
    RAISE NOTICE 'Deleted % carts', rows_affected;

    -- Step 5: Delete wishlist and user activity
    DELETE FROM wishlist WHERE user_id = user_uuid;
    GET DIAGNOSTICS rows_affected = ROW_COUNT;
    RAISE NOTICE 'Deleted % wishlist items', rows_affected;
    
    DELETE FROM search_analytics WHERE user_id = user_uuid;
    GET DIAGNOSTICS rows_affected = ROW_COUNT;
    RAISE NOTICE 'Deleted % search analytics', rows_affected;

    -- Step 6: Delete payment methods
    DELETE FROM payment_methods WHERE user_id = user_uuid;
    GET DIAGNOSTICS rows_affected = ROW_COUNT;
    RAISE NOTICE 'Deleted % payment methods', rows_affected;
    
    DELETE FROM other_payment_methods WHERE user_id = user_uuid;
    GET DIAGNOSTICS rows_affected = ROW_COUNT;
    RAISE NOTICE 'Deleted % other payment methods', rows_affected;

    -- Step 7: Delete shipping addresses
    DELETE FROM shipping_addresses WHERE user_id = user_uuid;
    GET DIAGNOSTICS rows_affected = ROW_COUNT;
    RAISE NOTICE 'Deleted % shipping addresses', rows_affected;

    -- Step 8: Delete vendor-related data (if user was vendor before)
    IF vendor_id_value IS NOT NULL THEN
      DELETE FROM vendor_follows WHERE vendor_id = vendor_id_value;
      GET DIAGNOSTICS rows_affected = ROW_COUNT;
      RAISE NOTICE 'Deleted % vendor follows', rows_affected;
      
      DELETE FROM vendor_reviews WHERE vendor_id = vendor_id_value OR user_id = user_uuid;
      GET DIAGNOSTICS rows_affected = ROW_COUNT;
      RAISE NOTICE 'Deleted % vendor reviews', rows_affected;
    END IF;

    -- Step 9: Delete loyalty program data
    DELETE FROM loyalty_points WHERE user_id = user_uuid;
    GET DIAGNOSTICS rows_affected = ROW_COUNT;
    RAISE NOTICE 'Deleted % loyalty points', rows_affected;
    
    DELETE FROM loyalty_transactions WHERE user_id = user_uuid;
    GET DIAGNOSTICS rows_affected = ROW_COUNT;
    RAISE NOTICE 'Deleted % loyalty transactions', rows_affected;
    
    DELETE FROM user_badges WHERE user_id = user_uuid;
    GET DIAGNOSTICS rows_affected = ROW_COUNT;
    RAISE NOTICE 'Deleted % user badges', rows_affected;
    
    DELETE FROM loyalty_vouchers WHERE user_id = user_uuid;
    GET DIAGNOSTICS rows_affected = ROW_COUNT;
    RAISE NOTICE 'Deleted % loyalty vouchers', rows_affected;

    -- Step 10: Delete currency preferences
    DELETE FROM user_currency_preferences WHERE user_id = user_uuid;
    GET DIAGNOSTICS rows_affected = ROW_COUNT;
    RAISE NOTICE 'Deleted % currency preferences', rows_affected;

    -- Step 11: ANONYMIZE orders (keep for legal/tax compliance)
    -- Do NOT delete orders, just anonymize the customer information
    UPDATE orders 
    SET 
      customer_name = 'Deleted User',
      customer_email = 'deleted@user.com',
      customer_phone = NULL,
      updated_at = NOW()
    WHERE user_id = user_uuid;
    GET DIAGNOSTICS rows_affected = ROW_COUNT;
    RAISE NOTICE 'Anonymized % orders', rows_affected;
    
    -- Note: We keep order_items intact as they're linked to anonymized orders

    -- Step 12: Update profile to mark as deleted
    UPDATE profiles 
    SET 
      full_name = 'Deleted User',
      phone_number = NULL,
      image_path = NULL,
      is_deleted = true,
      updated_at = NOW()
    WHERE id = user_uuid;
    GET DIAGNOSTICS rows_affected = ROW_COUNT;
    RAISE NOTICE 'Updated % profile to deleted state', rows_affected;

    -- Step 13: Auth user deletion will be handled by application layer
    -- using Supabase Admin API (supabase.auth.admin.deleteUser)
    -- This cannot be done from SQL due to security restrictions

    -- Success response
    result := json_build_object(
      'success', true,
      'message', 'Account deleted successfully. Your personal information has been removed and order history has been anonymized.',
      'user_id', user_uuid
    );
    
    RETURN result;

  EXCEPTION WHEN OTHERS THEN
    -- Rollback happens automatically on exception
    RAISE NOTICE 'Error during account deletion: %', SQLERRM;
    RETURN json_build_object(
      'success', false,
      'error', 'deletion_failed',
      'message', 'Account deletion failed: ' || SQLERRM
    );
  END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION delete_user_account(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION is_active_vendor(UUID) TO authenticated;

-- Add helpful comments
COMMENT ON FUNCTION delete_user_account(UUID) IS 'Deletes user account data while anonymizing order history for legal compliance. Blocks deletion for active vendors.';
COMMENT ON FUNCTION is_active_vendor(UUID) IS 'Checks if a user has an active vendor account or products.';

-- =====================================================
-- MIGRATION NOTES
-- =====================================================
-- To apply this migration:
-- 1. Run this SQL in Supabase SQL Editor
-- 2. Test with a test user account first
-- 3. Verify data deletion in database
-- 4. Confirm order anonymization works correctly
-- 
-- To rollback (if needed before applying):
-- DROP FUNCTION IF EXISTS delete_user_account(UUID);
-- DROP FUNCTION IF EXISTS is_active_vendor(UUID);
-- =====================================================

