-- FSRS-5 schema additions for vocabulary_entries.
-- Safe to run multiple times.

alter table public.vocabulary_entries
  add column if not exists difficulty real default 5.0;

create index if not exists vocabulary_entries_due_at_idx
  on public.vocabulary_entries (user_id, due_at);
