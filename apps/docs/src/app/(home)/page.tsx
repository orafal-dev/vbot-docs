import Link from 'next/link';

export default function HomePage() {
  return (
    <div className="flex flex-col justify-center text-center flex-1 px-6">
      <h1 className="text-3xl font-bold mb-3">ValidusBot Scripting Docs</h1>
      <p className="text-fd-muted-foreground mb-6 max-w-lg mx-auto">
        Comprehensive documentation for writing Lua scripts in ValidusBot for Tibia —
        runtime rules, guides, examples, and full API reference.
      </p>
      <div className="flex gap-4 justify-center flex-wrap">
        <Link
          href="/docs"
          className="inline-flex items-center rounded-lg bg-fd-primary px-4 py-2 text-sm font-medium text-fd-primary-foreground"
        >
          Get started
        </Link>
        <Link
          href="/docs/api-reference"
          className="inline-flex items-center rounded-lg border px-4 py-2 text-sm font-medium"
        >
          API Reference
        </Link>
      </div>
    </div>
  );
}
