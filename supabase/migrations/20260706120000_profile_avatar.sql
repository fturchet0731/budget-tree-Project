-- Small profile picture picked from the user's device gallery, stored inline
-- as a base64 JPEG (the app resizes to ~256px / quality 70 before upload, so
-- rows stay small). Inline beats a storage bucket here: the existing profiles
-- RLS already covers who may read/write it, and no new infra is needed.
alter table public.profiles
  add column if not exists avatar_b64 text;

-- Guard rail so a hand-crafted request can't stuff megabytes into the row.
alter table public.profiles
  add constraint profiles_avatar_b64_len check (
    avatar_b64 is null or length(avatar_b64) <= 200000
  );
