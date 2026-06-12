# Contributing to Salesforce Enterprise Monorepo

We want to make contributing to this project as easy and transparent as possible, whether it's:

- Reporting a bug
- Discussing the current state of the code
- Submitting a fix
- Proposing new features

## Our Development Process

We use a standard branching flow:
- `main`: Reflects the latest production-ready release code.
- `dev`: Active integration branch where features are merged.
- `feature/*`: Development branches for individual features/bugfixes.

## How to Contribute

1. **Fork the Repository**: Create a personal copy of this repository on GitHub.
2. **Clone the Fork**: Clone your fork locally.
3. **Create a Branch**: Create a branch off `dev` (e.g., `git checkout -b feature/cool-new-component dev`).
4. **Make Changes**: Implement your changes and write unit tests.
5. **Format & Lint**: Run Prettier and ESLint to verify style guide compliance:
   ```bash
   npm run prettier
   npm run lint
   ```
6. **Commit**: Keep commits small and write meaningful commit messages.
7. **Push & Pull Request**: Push your branch to GitHub and open a Pull Request against the `dev` branch of this repository.

## Pull Request Guidelines

- Ensure your code compiles and passes all local tests:
  ```bash
  npm run test
  ```
- Reference any related issue numbers in the PR description.
- Wait for a maintainer to review and approve your changes before merging.

## Style Guide
- **Apex**: Follow standard naming conventions (PascalCase for classes, camelCase for variables/methods). Use bulkified triggers and proper trigger frameworks.
- **LWC**: Write modular components with proper public properties and events.
- **Formatting**: Always format your code using `npm run prettier` before pushing.
