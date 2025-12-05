const express = require('express');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(express.json());

// Simple calculator functions
const calculator = {
  add: (a, b) => a + b,
  subtract: (a, b) => a - b,
  multiply: (a, b) => a * b,
  divide: (a, b) => {
    if (b === 0) throw new Error('Division by zero');
    return a / b;
  }
};

// Routes
app.get('/', (req, res) => {
  res.json({
    message: 'Welcome to Sample Node.js App',
    version: '1.0.0',
    endpoints: [
      'GET /',
      'GET /health',
      'POST /calculate'
    ]
  });
});

app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString()
  });
});

app.post('/calculate', (req, res) => {
  try {
    const { operation, a, b } = req.body;
    
    if (!operation || a === undefined || b === undefined) {
      return res.status(400).json({ error: 'Missing required parameters' });
    }

    if (!calculator[operation]) {
      return res.status(400).json({ error: 'Invalid operation' });
    }

    const result = calculator[operation](a, b);
    res.json({
      operation,
      a,
      b,
      result
    });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Start server only if not in test mode
if (process.env.NODE_ENV !== 'test') {
  app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
  });
}

module.exports = { app, calculator };

