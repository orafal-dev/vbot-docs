import { highlight } from 'fumadocs-core/highlight';
import type { HTMLAttributes, ReactNode } from 'react';
import { cn } from '@/lib/cn';

type InlineCodeProps = HTMLAttributes<HTMLElement> & {
  children?: ReactNode;
};

const getText = (children: ReactNode): string | null => {
  if (typeof children === 'string' || typeof children === 'number') {
    return String(children);
  }

  if (Array.isArray(children)) {
    const parts = children.map((child) => getText(child));
    if (parts.every((part) => part !== null)) {
      return parts.join('');
    }
  }

  return null;
};

/**
 * Highlight PascalCase API calls / paths (e.g. Storage.ForCharacter(namespace)).
 * Leave plain identifiers and prose-like snippets unhighlighted.
 */
const shouldHighlightAsLua = (text: string): boolean => {
  const trimmed = text.trim();
  if (!trimmed || trimmed.length > 200) {
    return false;
  }

  if (/\{\:\w+\}$/.test(trimmed)) {
    return false;
  }

  // Module.Method(...), Module:Method(...), nested namespaces, optional args
  return /^[A-Za-z_][\w]*(?:[.:][A-Za-z_][\w]*)+(?:\([^)]*\))?$/.test(trimmed);
};

export const InlineCode = async ({
  children,
  className,
  ...props
}: InlineCodeProps) => {
  // Already highlighted by rehype-code / block code blocks
  if (
    typeof className === 'string' &&
    (className.includes('language-') || className.includes('shiki'))
  ) {
    return (
      <code className={className} {...props}>
        {children}
      </code>
    );
  }

  const text = getText(children);
  if (!text || !shouldHighlightAsLua(text)) {
    return (
      <code className={className} {...props}>
        {children}
      </code>
    );
  }

  const highlighted = await highlight(text, {
    lang: 'lua',
    structure: 'inline',
    defaultColor: false,
    themes: {
      light: 'github-light',
      dark: 'github-dark',
    },
  });

  return (
    <code
      className={cn(
        'shiki rounded-md bg-fd-secondary px-1.5 py-0.5 font-mono text-[0.875em] [&_span]:font-normal',
        className,
      )}
      {...props}
    >
      {highlighted}
    </code>
  );
};
