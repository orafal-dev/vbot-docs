ALTER TABLE "scripts" ADD COLUMN "files" jsonb DEFAULT '[]'::jsonb NOT NULL;
