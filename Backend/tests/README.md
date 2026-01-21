# AI Workflow Tests

This directory contains automated tests for the AI fitness coach workflow.

## Setup

1. Install Jest (if not already installed):
```bash
npm install --save-dev jest
```

2. Update package.json scripts:
```json
{
  "scripts": {
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage"
  }
}
```

## Running Tests

### Run all tests:
```bash
npm test
```

### Run with coverage:
```bash
npm run test:coverage
```

### Run specific test file:
```bash
npx jest aiWorkflow.test.js
```

### Run tests in watch mode:
```bash
npm run test:watch
```

## Test Structure

### aiWorkflow.test.js
- **Information Extraction**: Tests for parsing user goals, workout styles, and days from messages
- **Conversation State Management**: Tests for state transitions and data persistence
- **Plan Parsing**: Tests for parsing AI-generated workout plans
- **API Endpoints**: Tests for chat and approval endpoints
- **Error Handling**: Tests for various error scenarios
- **Integration Flow**: Tests for complete conversation workflows

## Test Coverage

The tests cover:
- ✅ Information extraction from user messages
- ✅ State management and transitions
- ✅ Plan parsing and validation
- ✅ Database operations (with mocks)
- ✅ API error handling
- ✅ Complete happy path flows
- ✅ Edge cases and error scenarios

## Mocking

Tests use Jest mocks for:
- OpenAI API client
- Database operations
- HTTP requests (for integration tests)

## Adding New Tests

When adding new functionality to the AI workflow:

1. Add unit tests for new functions
2. Add integration tests for new flows
3. Update existing tests if behavior changes
4. Ensure all new code has test coverage

## CI/CD Integration

These tests can be integrated into your CI/CD pipeline:

```yaml
# Example GitHub Actions
- name: Run Backend Tests
  run: |
    cd Backend
    npm test -- --coverage --watchAll=false
```

## Troubleshooting

### Common Issues:
1. **Mock not working**: Ensure mocks are properly imported before the modules they mock
2. **Database tests failing**: Check that database mocks are correctly set up
3. **Async tests timing out**: Increase timeout or check for unhandled promises

### Debug Mode:
```bash
DEBUG=jest npx jest --verbose
