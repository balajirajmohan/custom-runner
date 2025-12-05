const { calculator } = require('./index');

describe('Calculator Functions', () => {
  describe('add', () => {
    test('should add two positive numbers', () => {
      expect(calculator.add(2, 3)).toBe(5);
    });

    test('should add negative numbers', () => {
      expect(calculator.add(-5, -3)).toBe(-8);
    });

    test('should add positive and negative numbers', () => {
      expect(calculator.add(10, -5)).toBe(5);
    });
  });

  describe('subtract', () => {
    test('should subtract two positive numbers', () => {
      expect(calculator.subtract(10, 3)).toBe(7);
    });

    test('should subtract negative numbers', () => {
      expect(calculator.subtract(-5, -3)).toBe(-2);
    });

    test('should handle negative results', () => {
      expect(calculator.subtract(3, 10)).toBe(-7);
    });
  });

  describe('multiply', () => {
    test('should multiply two positive numbers', () => {
      expect(calculator.multiply(4, 5)).toBe(20);
    });

    test('should multiply by zero', () => {
      expect(calculator.multiply(5, 0)).toBe(0);
    });

    test('should multiply negative numbers', () => {
      expect(calculator.multiply(-3, -4)).toBe(12);
    });
  });

  describe('divide', () => {
    test('should divide two positive numbers', () => {
      expect(calculator.divide(10, 2)).toBe(5);
    });

    test('should handle decimal results', () => {
      expect(calculator.divide(7, 2)).toBe(3.5);
    });

    test('should throw error when dividing by zero', () => {
      expect(() => calculator.divide(10, 0)).toThrow('Division by zero');
    });

    test('should divide negative numbers', () => {
      expect(calculator.divide(-10, 2)).toBe(-5);
    });
  });
});

