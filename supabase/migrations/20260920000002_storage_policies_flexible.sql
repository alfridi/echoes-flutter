-- Update storage policies to support both recordings/{user_id}/... and {user_id}/...

DROP POLICY IF EXISTS "Users can view own audio files in recordings bucket" ON storage.objects;
CREATE POLICY "Users can view own audio files in recordings bucket"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'recordings' AND (
    (storage.foldername(name))[1] = auth.uid()::text
    OR ((storage.foldername(name))[1] = 'recordings' AND (storage.foldername(name))[2] = auth.uid()::text)
  )
);

DROP POLICY IF EXISTS "Users can upload own audio files in recordings bucket" ON storage.objects;
CREATE POLICY "Users can upload own audio files in recordings bucket"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'recordings' AND (
    (storage.foldername(name))[1] = auth.uid()::text
    OR ((storage.foldername(name))[1] = 'recordings' AND (storage.foldername(name))[2] = auth.uid()::text)
  )
);

DROP POLICY IF EXISTS "Users can delete own audio files in recordings bucket" ON storage.objects;
CREATE POLICY "Users can delete own audio files in recordings bucket"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'recordings' AND (
    (storage.foldername(name))[1] = auth.uid()::text
    OR ((storage.foldername(name))[1] = 'recordings' AND (storage.foldername(name))[2] = auth.uid()::text)
  )
);
