ALTER TABLE "scripts" ADD COLUMN "tags" text[] DEFAULT '{}'::text[] NOT NULL;
CREATE INDEX "scripts_tags_idx" ON "scripts" USING gin ("tags");
