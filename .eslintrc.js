module.exports = {
  env: {
    node: true,
    es2021: true,
  },
  extends: [
    'eslint:recommended',
  ],
  parserOptions: {
    ecmaVersion: 2021,
    sourceType: 'commonjs',
  },
  rules: {
    'no-console': 'warn',
    'no-unused-vars': 'error',
    'no-undef': 'error',
    'semi': ['error', 'always'],
    'quotes': ['error', 'single'],
  },
  ignorePatterns: [
    'node_modules/',
    'dist/',
    'build/',
    'templates/',
    '*.min.js',
  ],
  overrides: [
    {
      files: ['.claude/**/*.js'],
      rules: {
        // Override ignore patterns for .claude directory
      }
    }
  ],
  globals: {
    console: 'readonly',
    process: 'readonly',
    Buffer: 'readonly',
    __dirname: 'readonly',
    __filename: 'readonly',
    module: 'readonly',
    require: 'readonly',
    exports: 'readonly',
    global: 'readonly',
  },
};