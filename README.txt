CESAR MEDICAL AESTHETICS — SETUP GUIDE (beginner friendly)

FILES
 index.html          public website          admin.html   admin dashboard
 supabase-setup.sql  database + security     README.txt   this guide
Each HTML file is self-contained (CSS, JavaScript and logo are inside it): no extra folder is needed.

STEP 1  Go to supabase.com, sign in, click "New project", choose a name and a strong database password, create it.
STEP 2  In the left menu open "SQL Editor" > "New query".
STEP 3  Open supabase-setup.sql, copy everything, paste it, click "Run". It should say "Success".
STEP 4  Left menu "Authentication" > "Users" > "Add user" > "Create new user". Enter the admin email and password, tick "Auto Confirm User".
STEP 5  Make that user an administrator: in SQL Editor run
          insert into public.admins(user_id) select id from auth.users where email = 'YOUR-ADMIN-EMAIL';
        (The last lines of supabase-setup.sql contain this command.) This is the only way to create an admin; website visitors cannot do it.
        Also recommended: Authentication > Sign In / Providers > turn OFF "Allow new users to sign up".
STEP 6  Settings (gear) > "API Keys" (or "API"). Copy the "Project URL" and the "Publishable" (anon) key.
STEP 7  Open index.html and admin.html in a text editor. Find "CONFIGURATION" near the bottom. Paste the URL and key between the quotes in BOTH files.
        In index.html you can also fill PHONE, WHATSAPP (digits with country code), EMAIL, ADDRESS, HOURS. Empty ones stay hidden.
STEP 8  Check: NEVER paste a "secret" or "service_role" key anywhere. Only the publishable/anon key belongs in these files.
STEP 9  Open index.html in your browser, choose a service, fill the form, send. You should see "Request received".
STEP 10 Open admin.html, sign in with the admin account. The request appears in the table.
STEP 11 Click "View" > "Confirm". The status changes and stays after refreshing.
STEP 12 Switch EN / FR / ع on both pages (Arabic switches the page to right-to-left).
STEP 13 Click the ◐ button for light/dark mode on both pages.
STEP 14 Check both pages on a phone and a computer.
STEP 15 Create a GitHub account and a new public repository. Upload index.html, admin.html, supabase-setup.sql, README.txt.
STEP 16 Repository > Settings > Pages > Source: "Deploy from a branch", branch "main", folder "/ (root)", Save.
STEP 17 After a minute your site is at https://USERNAME.github.io/REPOSITORY/ and the dashboard at .../admin.html. In Supabase > Authentication > URL Configuration, set "Site URL" to that address (needed for password-reset emails).
STEP 18 TROUBLESHOOTING
 - "Online booking is not configured": URL/key missing in index.html.
 - "Could not save" on booking: SQL not run, wrong URL/key, or invalid phone/date. Press F12 > Console for details.
 - "Not an authorized administrator": step 5 not done, or wrong email.
 - Table empty / "Could not load": you are not in public.admins (RLS blocks everything else — this is intentional).
 - "Wrong email or password": the user was not created with Auto Confirm, or password mistyped.

LIMITS TO KNOW
 - A booking is a REQUEST. Availability is not checked; the clinic confirms or rejects it by hand.
 - Duplicate protection: same phone + date + service while pending/confirmed is refused. It is not full spam protection;
   add Supabase CAPTCHA/rate limits if you receive abuse.
 - Not tested against a live Supabase project: do steps 9-11 before going public.
