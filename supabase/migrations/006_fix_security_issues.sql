    -- Migration: Fix Security Issues
    -- Fixes: function_search_path_mutable, extension_in_public, rls_policy_always_true

    -- ============================================================================
    -- NOTE: spatial_ref_sys RLS warning
    -- The spatial_ref_sys table is a PostGIS system table that we don't own.
    -- It's a read-only reference table for coordinate systems and is safe to ignore.
    -- Supabase manages this table and the warning is expected for PostGIS users.
    -- ============================================================================

    -- ============================================================================
    -- PART 1: Fix function search_path vulnerability
    -- Recreate all functions with explicit search_path set
    -- ============================================================================

    -- Fix generate_tracking_number function
    CREATE OR REPLACE FUNCTION generate_tracking_number()
    RETURNS TRIGGER 
    LANGUAGE plpgsql
    SET search_path = public
    AS $$
    BEGIN
        NEW.tracking_number := 'HKM-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0');
        RETURN NEW;
    END;
    $$;

    -- Fix get_user_role function
    CREATE OR REPLACE FUNCTION get_user_role()
    RETURNS TEXT 
    LANGUAGE plpgsql
    SECURITY DEFINER
    STABLE
    SET search_path = public
    AS $$
    BEGIN
        RETURN COALESCE(
            (SELECT role::TEXT FROM profiles WHERE id = auth.uid()),
            'citizen'
        );
    END;
    $$;

    -- Fix update_updated_at function
    CREATE OR REPLACE FUNCTION update_updated_at()
    RETURNS TRIGGER 
    LANGUAGE plpgsql
    SET search_path = public
    AS $$
    BEGIN
        NEW.updated_at = NOW();
        RETURN NEW;
    END;
    $$;

    -- Fix log_status_change function
    CREATE OR REPLACE FUNCTION log_status_change()
    RETURNS TRIGGER 
    LANGUAGE plpgsql
    SET search_path = public
    AS $$
    BEGIN
        IF OLD.status IS DISTINCT FROM NEW.status THEN
            INSERT INTO status_history (complaint_id, old_status, new_status, is_system_generated)
            VALUES (NEW.id, OLD.status, NEW.status, true);
        END IF;
        RETURN NEW;
    END;
    $$;

    -- Fix handle_new_user function
    CREATE OR REPLACE FUNCTION handle_new_user()
    RETURNS TRIGGER 
    LANGUAGE plpgsql
    SECURITY DEFINER
    SET search_path = public
    AS $$
    BEGIN
        INSERT INTO profiles (id, email, full_name, phone)
        VALUES (
            NEW.id, 
            NEW.email, 
            COALESCE(NEW.raw_user_meta_data->>'full_name', 'User'),
            NEW.raw_user_meta_data->>'phone'
        );
        RETURN NEW;
    EXCEPTION
        WHEN unique_violation THEN
            -- Profile already exists, ignore
            RETURN NEW;
        WHEN OTHERS THEN
            -- Log error but don't fail the signup
            RAISE WARNING 'Failed to create profile for user %: %', NEW.id, SQLERRM;
            RETURN NEW;
    END;
    $$;

    -- ============================================================================
    -- PART 3: Fix notifications_insert_system policy (too permissive)
    -- Replace WITH CHECK (true) with proper staff/system check
    -- ============================================================================

    -- Drop the overly permissive policy
    DROP POLICY IF EXISTS notifications_insert_system ON notifications;

    -- Create a more secure policy that only allows staff/admin to insert notifications
    CREATE POLICY notifications_insert_staff ON notifications
        FOR INSERT
        WITH CHECK (
            EXISTS (
                SELECT 1 FROM profiles 
                WHERE profiles.id = (SELECT auth.uid()) 
                AND profiles.role IN ('admin', 'super_admin', 'employee')
            )
        );

    -- Also allow the service role (backend) to insert notifications
    -- This is needed for system-generated notifications
    -- Note: service_role bypasses RLS by default, so this is mainly for documentation

    -- ============================================================================
    -- PART 4: Move PostGIS extension to a dedicated 'extensions' schema
    -- Note: This is complex and may require manual intervention
    -- ============================================================================

    -- Create extensions schema if it doesn't exist
    CREATE SCHEMA IF NOT EXISTS extensions;

    -- Grant usage on extensions schema
    GRANT USAGE ON SCHEMA extensions TO anon, authenticated, service_role;

    -- Note: Moving PostGIS after installation is complex and can break things.
    -- The safest approach is to:
    -- 1. Drop and recreate the extension in the new schema (if no data depends on it)
    -- 2. Or accept the warning for existing installations
    --
    -- If you want to move it (WARNING: may break location data):
    -- DROP EXTENSION IF EXISTS postgis CASCADE;
    -- CREATE EXTENSION postgis WITH SCHEMA extensions;
    --
    -- For now, we'll leave PostGIS in public schema as moving it could break
    -- existing location data. The warning is acceptable for existing databases.

    -- ============================================================================
    -- PART 5: Enable Leaked Password Protection (Auth setting)
    -- This must be done in the Supabase Dashboard, not via SQL:
    -- 
    -- 1. Go to your Supabase Dashboard
    -- 2. Navigate to Authentication > Settings
    -- 3. Scroll to "Security" section
    -- 4. Enable "Leaked password protection"
    -- 
    -- Or use the Supabase CLI:
    -- supabase auth config set --enable-leaked-password-protection true
    -- ============================================================================

    -- Add a comment as a reminder
    COMMENT ON SCHEMA public IS 'Standard public schema. Note: Enable Leaked Password Protection in Supabase Dashboard > Auth > Settings > Security';
