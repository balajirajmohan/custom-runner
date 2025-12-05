# Sample Node.js Application

A simple Node.js application with Express and Jest for testing, designed to demonstrate GitHub Actions with self-hosted runners.

## Features

- Express.js REST API
- Calculator functions (add, subtract, multiply, divide)
- Jest unit tests
- Health check endpoint

## Installation

```bash
npm install
```

## Running the Application

```bash
npm start
```

The server will start on port 3000 (or the PORT environment variable).

## Running Tests

```bash
# Run tests
npm test

# Run tests with coverage
npm test:coverage
```

## API Endpoints

- `GET /` - Welcome message and API info
- `GET /health` - Health check endpoint
- `POST /calculate` - Perform calculations

### Calculate Example

```bash
curl -X POST http://localhost:3000/calculate \
  -H "Content-Type: application/json" \
  -d '{"operation": "add", "a": 5, "b": 3}'
```

Response:
```json
{
  "operation": "add",
  "a": 5,
  "b": 3,
  "result": 8
}
```

Supported operations: `add`, `subtract`, `multiply`, `divide`

