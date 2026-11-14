// @ts-check
import js from "@eslint/js";
import tseslint from "typescript-eslint";

export default tseslint.config(
  { ignores: ["**/dist/**", "**/node_modules/**", "**/coverage/**"] },
  js.configs.recommended,
  ...tseslint.configs.recommended,
  {
    files: ["**/*.js"],
    languageOptions: { globals: { process: "readonly", console: "readonly" } },
  },
  {
    files: ["backend/src/**/*.ts"],
    languageOptions: { globals: { process: "readonly", console: "readonly" } },
  },
  {
    files: ["frontend/src/**/*.{ts,tsx}"],
    languageOptions: { globals: { document: "readonly", console: "readonly" } },
  },
);
