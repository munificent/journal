/// Common regex patterns in languages.

const allCaps = r'\b[A-Z][A-Z0-9_]+\b';
const identifier = r'\b[a-zA-Z_][a-zA-Z0-9_]*\b';
const capsIdentifier = r'\b[A-Z_][a-zA-Z0-9_]*\b';
const dottedIdentifier = '$identifier(\\.$identifier)*';

/// Word boundary.
const b = '\\b';

/// Zero or more whitespace characters.
const s = '\\s*';

/// One or more whitespace characters.
const ss = '\\s+';
