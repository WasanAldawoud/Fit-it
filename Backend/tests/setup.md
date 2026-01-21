# Test Setup Instructions

## Backend Testing Setup

To run the automated tests for the AI workflow, you need to set up Jest.

### 1. Install Jest
```bash
npm install --save-dev jest
```

### 2. Update package.json scripts
Add these scripts to your `package.json`:

```json
{
  "scripts": {
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage"
  }
}
```

### 3. Create Jest Configuration (Optional)
Create `jest.config.js` in the Backend root:

```javascript
module.exports = {
  testEnvironment: 'node',
  testMatch: ['**/tests/**/*.test.js'],
  collectCoverageFrom: [
    'Ai/**/*.js',
    'controllers/**/*.js',
    'routes/**/*.js',
    '!**/node_modules/**',
    '!**/tests/**'
  ],
  setupFilesAfterEnv: ['<rootDir>/tests/setup.js']
};
```

### 4. Create Test Setup File (Optional)
Create `Backend/tests/setup.js`:

```javascript
// Global test setup
process.env.NODE_ENV = 'test';

// Mock environment variables
process.env.OPENAI_API_KEY = 'test-key';
process.env.DATABASE_URL = 'postgresql://test:test@localhost:5432/test_db';
```

### 5. Run Tests
```bash
# Run all tests
npm test

# Run with coverage
npm run test:coverage

# Run in watch mode
npm run test:watch
```

## Frontend Testing Setup

Flutter tests are ready to run with the built-in test framework.

### Run Tests
```bash
cd frontendscreen

# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test
flutter test test/ai_chat_test.dart
```

## CI/CD Integration

### GitHub Actions Example
```yaml
name: Tests
on: [push, pull_request]

jobs:
  backend-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      - name: Install dependencies
        run: cd Backend && npm install
      - name: Run tests
        run: cd Backend && npm test

  frontend-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: flutter-actions/setup-flutter@v2
      - name: Run tests
        run: cd frontendscreen && flutter test
```

## Test Coverage Goals

Aim for:
- **Backend**: >80% coverage
- **Frontend**: >70% coverage for UI components

## Troubleshooting

### Backend Tests
- **ESM imports**: Ensure Jest config supports ES modules
- **Database mocks**: Check that all database calls are mocked
- **OpenAI mocks**: Verify API mocks return expected responses

### Frontend Tests
- **Widget not found**: Use `debugDumpApp()` to inspect widget tree
- **Async timing**: Use `pumpAndSettle()` for animations
- **Platform differences**: Test on multiple screen sizes

## Adding New Tests

1. **Backend**: Add to `Backend/tests/` directory
2. **Frontend**: Add to `frontendscreen/test/` directory
3. Follow naming convention: `*.test.js` or `*_test.dart`
4. Include both positive and negative test cases
5. Mock external dependencies
6. Test error scenarios
