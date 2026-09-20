-- =============================================================================
-- Migration: Create recordings table, indexes, and RLS policies
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.recordings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  storage_path TEXT NOT NULL,
  duration_seconds INTEGER,
  mime_type TEXT,
  file_size BIGINT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_recordings_user_id ON public.recordings(user_id);
CREATE INDEX IF NOT EXISTS idx_recordings_created_at ON public.recordings(created_at DESC);

-- Enable Row Level Security
ALTER TABLE public.recordings ENABLE ROW LEVEL SECURITY;

-- Database RLS Policies: Authenticated users manage their own recordings
DROP POLICY IF EXISTS "Users can select own recordings" ON public.recordings;
CREATE POLICY "Users can select own recordings"
ON public.recordings FOR SELECT
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own recordings" ON public.recordings;
CREATE POLICY "Users can insert own recordings"
ON public.recordings FOR INSERT
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own recordings" ON public.recordings;
CREATE POLICY "Users can update own recordings"
ON public.recordings FOR UPDATE
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own recordings" ON public.recordings;
CREATE POLICY "Users can delete own recordings"
ON public.recordings FOR DELETE
USING (auth.uid() = user_id);

-- Storage bucket setup: Ensure 'recordings' bucket exists as well
INSERT INTO storage.buckets (id, name, public)
VALUES ('recordings', 'recordings', false)
ON CONFLICT (id) DO NOTHING;

-- Storage policies for 'recordings' bucket
DROP POLICY IF EXISTS "Users can view own audio files in recordings bucket" ON storage.objects;
CREATE POLICY "Users can view own audio files in recordings bucket"
ON storage.objects FOR SELECT
USING (bucket_id = 'recordings' AND (storage.foldername(name))[1] = auth.uid()::text);

DROP POLICY IF EXISTS "Users can upload own audio files in recordings bucket" ON storage.objects;
CREATE POLICY "Users can upload own audio files in recordings bucket"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'recordings' AND (storage.foldername(name))[1] = auth.uid()::text);

DROP POLICY IF EXISTS "Users can delete own audio files in recordings bucket" ON storage.objects;
CREATE POLICY "Users can delete own audio files in recordings bucket"
ON storage.objects FOR DELETE
USING (bucket_id = 'recordings' AND (storage.foldername(name))[1] = auth.uid()::text);
