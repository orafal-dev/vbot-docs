ALTER TABLE "scripts" ADD COLUMN "screenshots" jsonb DEFAULT '[]'::jsonb NOT NULL;
