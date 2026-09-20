-- =============================================================================
-- Echoes Living Audio Archive - PostgreSQL Database Schema, Policies & Seeds
-- Derived from FLUTTER_IMPLEMENTATION 2.md
-- =============================================================================

-- 0. Clean up legacy scaffold tables if they exist
DROP TABLE IF EXISTS public.likes CASCADE;
DROP TABLE IF EXISTS public.echoes CASCADE;
DROP TABLE IF EXISTS public.echo_recordings CASCADE;
DROP TABLE IF EXISTS public.words CASCADE;
DROP TABLE IF EXISTS public.dialect_pins CASCADE;
DROP TABLE IF EXISTS public.languages CASCADE;

-- 1. Profiles Table (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT,
  display_name TEXT NOT NULL DEFAULT 'Dialect Custodian',
  avatar_url TEXT,
  role TEXT DEFAULT 'Explorer',
  native_dialect TEXT,
  contributions_count INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Ensure profiles has all columns even if it already existed
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS email TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS display_name TEXT NOT NULL DEFAULT 'Dialect Custodian';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS avatar_url TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'Explorer';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS native_dialect TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS contributions_count INT DEFAULT 0;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- 2. Languages Catalog Table
CREATE TABLE public.languages (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  native_script TEXT NOT NULL,
  iso_code TEXT NOT NULL,
  branch TEXT NOT NULL,
  region TEXT NOT NULL,
  country_emoji TEXT NOT NULL DEFAULT '🌐',
  summary TEXT NOT NULL,
  preserved_people_count INT DEFAULT 0,
  verified_audio_count INT DEFAULT 0,
  contributor_avatar_urls JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Words and Dialect Phrases Table
CREATE TABLE public.words (
  id TEXT PRIMARY KEY,
  language_id TEXT NOT NULL REFERENCES public.languages(id) ON DELETE CASCADE,
  english_word TEXT NOT NULL,
  native_script TEXT NOT NULL,
  transliteration TEXT NOT NULL,
  phonetic_ipa TEXT NOT NULL,
  category TEXT NOT NULL DEFAULT 'Greeting',
  cultural_etymology TEXT NOT NULL,
  origin_territory TEXT NOT NULL,
  available_recordings_count INT DEFAULT 1,
  sample_audio_url TEXT NOT NULL,
  duration_ms INT NOT NULL DEFAULT 3200,
  contributor_name TEXT NOT NULL,
  contributor_avatar_url TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Echo Recordings Table (User Community Submissions)
CREATE TABLE public.echo_recordings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  word_id TEXT NOT NULL REFERENCES public.words(id) ON DELETE CASCADE,
  language_id TEXT NOT NULL REFERENCES public.languages(id) ON DELETE CASCADE,
  contributor_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  contributor_name TEXT NOT NULL,
  contributor_avatar_url TEXT NOT NULL,
  audio_url TEXT NOT NULL,
  duration_ms INT NOT NULL,
  accent_territory TEXT NOT NULL,
  acoustic_fidelity TEXT DEFAULT 'Pristine',
  upvotes_count INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Dialect Map Pins Table
CREATE TABLE public.dialect_pins (
  id TEXT PRIMARY KEY,
  language_id TEXT NOT NULL REFERENCES public.languages(id) ON DELETE CASCADE,
  language_name TEXT NOT NULL,
  country_emoji TEXT NOT NULL DEFAULT '📍',
  top_percent NUMERIC(5, 4) NOT NULL,
  left_percent NUMERIC(5, 4) NOT NULL,
  echoes_count INT DEFAULT 0,
  is_featured BOOLEAN DEFAULT false
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_words_language_id ON public.words(language_id);
CREATE INDEX IF NOT EXISTS idx_recordings_word_id ON public.echo_recordings(word_id);
CREATE INDEX IF NOT EXISTS idx_pins_featured ON public.dialect_pins(is_featured);

-- Atomic Word Recording Counter RPC
CREATE OR REPLACE FUNCTION public.increment_word_recordings(p_word_id TEXT)
RETURNS VOID AS $$
BEGIN
  UPDATE public.words
  SET available_recordings_count = available_recordings_count + 1
  WHERE id = p_word_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Storage Bucket Setup for Lossless Archival Recordings
INSERT INTO storage.buckets (id, name, public)
VALUES ('echoes-audio', 'echoes-audio', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Row Level Security (RLS) Setup
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.languages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.words ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.echo_recordings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dialect_pins ENABLE ROW LEVEL SECURITY;

-- Storage Policies (Drop first to allow idempotent recreation)
DROP POLICY IF EXISTS "Public Audio Access" ON storage.objects;
CREATE POLICY "Public Audio Access"
ON storage.objects FOR SELECT
USING (bucket_id = 'echoes-audio');

DROP POLICY IF EXISTS "Allow Voice Audio Uploads" ON storage.objects;
CREATE POLICY "Allow Voice Audio Uploads"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'echoes-audio');

-- Table Policies
DROP POLICY IF EXISTS "Languages are viewable by everyone" ON public.languages;
CREATE POLICY "Languages are viewable by everyone"
ON public.languages FOR SELECT USING (true);

DROP POLICY IF EXISTS "Words are viewable by everyone" ON public.words;
CREATE POLICY "Words are viewable by everyone"
ON public.words FOR SELECT USING (true);

DROP POLICY IF EXISTS "Dialect pins viewable by everyone" ON public.dialect_pins;
CREATE POLICY "Dialect pins viewable by everyone"
ON public.dialect_pins FOR SELECT USING (true);

DROP POLICY IF EXISTS "Recordings are viewable by everyone" ON public.echo_recordings;
CREATE POLICY "Recordings are viewable by everyone"
ON public.echo_recordings FOR SELECT USING (true);

DROP POLICY IF EXISTS "Anyone can submit voice recordings" ON public.echo_recordings;
CREATE POLICY "Anyone can submit voice recordings"
ON public.echo_recordings FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Profiles viewable by everyone" ON public.profiles;
CREATE POLICY "Profiles viewable by everyone"
ON public.profiles FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
CREATE POLICY "Users can insert own profile"
ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile"
ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- =============================================================================
-- Seed Archival Catalog Data
-- =============================================================================

INSERT INTO public.languages (
  id, name, native_script, iso_code, branch, region, country_emoji,
  summary, preserved_people_count, verified_audio_count, contributor_avatar_urls
) VALUES
(
  'malayalam',
  'Malayalam',
  'മലയാളം (Kēraḷaṁ)',
  'mal',
  'Dravidian',
  'Kerala · South India',
  '🇮🇳',
  'A melodious Dravidian language spoken primarily in Kerala and surrounding regions, celebrated for its poetic tradition and rich vocal inflections.',
  128,
  342,
  '["https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=100", "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100", "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100"]'::jsonb
),
(
  'ainu',
  'Ainu',
  'アイヌ・イタㇰ',
  'ain',
  'Isolate',
  'Hokkaido · Northern Japan',
  '🇯🇵',
  'A critically endangered language isolate traditionally spoken by the indigenous Ainu people of northern Japan, characterized by rich oral epics (Yukar).',
  45,
  89,
  '["https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100"]'::jsonb
),
(
  'nahuatl',
  'Nahuatl',
  'Nāhuatl',
  'nah',
  'Uto-Aztecan',
  'Puebla · Central Mexico',
  '🇲🇽',
  'An indigenous language of central Mexico with deep historical and cultural resonance, spoken continuously since pre-Columbian Mesoamerica.',
  68,
  154,
  '["https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100"]'::jsonb
),
(
  'isixhosa',
  'isiXhosa',
  'isiXhosa',
  'xho',
  'Bantu',
  'Eastern Cape · South Africa',
  '🇿🇦',
  'A major Nguni Bantu language known for its rich acoustic palette and distinctive click consonants, celebrated across southern Africa.',
  92,
  210,
  '["https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100"]'::jsonb
),
(
  'javanese',
  'Javanese',
  'Basa Jawa',
  'jav',
  'Austronesian',
  'Central Java · Indonesia',
  '🇮🇩',
  'Spoken primarily on the island of Java, renowned for its elaborate speech registers reflecting politeness and social harmony.',
  76,
  165,
  '["https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100"]'::jsonb
);

INSERT INTO public.words (
  id, language_id, english_word, native_script, transliteration, phonetic_ipa,
  category, cultural_etymology, origin_territory, available_recordings_count,
  sample_audio_url, duration_ms, contributor_name, contributor_avatar_url
) VALUES
(
  'welcome',
  'malayalam',
  'Welcome',
  'സ്വാഗതം',
  'Swagatham',
  '/sʋɑːɡɐt̪ɐm/',
  'HONORIFIC GREETING',
  '“Swagatham” is delivered with folded hands (Namaskaram), welcoming not just the guest, but the divine spirit within them. In Kerala tradition, greeting an entrant is accompanied by an open veranda door and offering of clear well-water.',
  'Central Travancore accent',
  42,
  'https://cdn.freesound.org/previews/316/316844_4939433-lq.mp3',
  5000,
  'Anu · 28 yrs',
  'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=120'
),
(
  'mother',
  'malayalam',
  'Mother',
  'അമ്മ',
  'Amma',
  '/əm-mə/',
  'KINSHIP & ORIGIN',
  'One of the earliest and most universal phonetic utterances, carrying deep reverence in matrilineal Kerala heritage.',
  'Thrissur, Kerala',
  89,
  'https://cdn.freesound.org/previews/316/316844_4939433-lq.mp3',
  3000,
  'Ramanathan K.',
  'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=120'
),
(
  'home',
  'malayalam',
  'Home',
  'വീട്',
  'Veedu',
  '/ʋiːɖə̆/',
  'SPATIAL SANCTUARY',
  'Denotes both the physical dwelling and the ancestral homestead (Tharavadu) where generations gather.',
  'Kozhikode, Kerala',
  31,
  'https://cdn.freesound.org/previews/316/316844_4939433-lq.mp3',
  4000,
  'Devika S.',
  'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=120'
),
(
  'thank_you_nahuatl',
  'nahuatl',
  'Thank you',
  'Tlazohcamati',
  'Tlazohcamati',
  '/t͡ɬa.soh.kaˈma.ti/',
  'GRATITUDE',
  'Derived from roots expressing appreciation of divine abundance and mutual gift.',
  'Puebla, Mexico',
  14,
  'https://cdn.freesound.org/previews/316/316844_4939433-lq.mp3',
  4000,
  'Mateo',
  'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=120'
),
(
  'hello_ainu',
  'ainu',
  'Hello',
  'Irankarapte',
  'Irankarapte',
  '/iɾaŋkaɾapte/',
  'GREETING',
  'Literally translates to: "Let me gently touch your heart."',
  'Hokkaido, Japan',
  8,
  'https://cdn.freesound.org/previews/316/316844_4939433-lq.mp3',
  6000,
  'Kenji',
  'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=120'
),
(
  'greetings_xhosa',
  'isixhosa',
  'Greetings',
  'Molo',
  'Molo',
  '/móːlo/',
  'GREETING',
  'Singular greeting to acknowledge one person, deeply tied to the philosophy of Ubuntu.',
  'Cape Town, South Africa',
  22,
  'https://cdn.freesound.org/previews/316/316844_4939433-lq.mp3',
  3000,
  'Lindiwe',
  'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=120'
);

INSERT INTO public.dialect_pins (
  id, language_id, language_name, country_emoji, top_percent, left_percent, echoes_count, is_featured
) VALUES
(
  'pin_kerala',
  'malayalam',
  'MALAYALAM',
  '🇮🇳',
  0.5200,
  0.6400,
  128,
  true
),
(
  'pin_ainu',
  'ainu',
  'Ainu',
  '🇯🇵',
  0.3400,
  0.8400,
  45,
  false
),
(
  'pin_nahuatl',
  'nahuatl',
  'Nahuatl',
  '🇲🇽',
  0.4600,
  0.1800,
  68,
  false
),
(
  'pin_isixhosa',
  'isixhosa',
  'isiXhosa',
  '🇿🇦',
  0.7400,
  0.5200,
  92,
  false
),
(
  'pin_javanese',
  'javanese',
  'Javanese',
  '🇮🇩',
  0.6000,
  0.7600,
  76,
  false
);

INSERT INTO public.echo_recordings (
  word_id, language_id, contributor_name, contributor_avatar_url, audio_url,
  duration_ms, accent_territory, acoustic_fidelity, upvotes_count
) VALUES
(
  'welcome',
  'malayalam',
  'Anjali M.',
  'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=100',
  'https://cdn.freesound.org/previews/316/316844_4939433-lq.mp3',
  4500,
  'Thrissur Dialect',
  'Pristine',
  18
),
(
  'welcome',
  'malayalam',
  'Suresh V.',
  'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100',
  'https://cdn.freesound.org/previews/316/316844_4939433-lq.mp3',
  5200,
  'Malabar Northern Accent',
  'Studio Master',
  12
);
