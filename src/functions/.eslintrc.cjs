module.exports = {
  root: true,
  env: { es2021: true, node: true },
  parser: '@typescript-eslint/parser',
  parserOptions: { project: ['tsconfig.json'] },
  plugins: ['@typescript-eslint'],
  extends: ['eslint:recommended', 'google'],
  rules: {
    'require-jsdoc': 'off',
    'max-len': 'off',
    'object-curly-spacing': ['error', 'always'],
  },
};
