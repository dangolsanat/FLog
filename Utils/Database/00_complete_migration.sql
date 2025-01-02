-- 1. Run profiles first (including extensions)
\i '01_profiles.sql'

-- 2. Run food entries
\i '02_food_entries.sql'

-- 3. Run follows
\i '03_follows.sql'

-- 4. Set up storage
\i '04_storage.sql'

-- 5. Finally, set up functions and triggers
\i '05_functions.sql' 