import test from 'node:test';
import assert from 'node:assert/strict';

// Optional integration test. It is skipped by default so the normal unit-test
// suite does not require MongoDB or backend dependencies to be preloaded.
test('ProductVariant can be read from MongoDB', { skip: process.env.RUN_DB_TESTS !== '1' }, async () => {
  const { default: dotenv } = await import('dotenv');
  dotenv.config();
  assert.ok(process.env.MONGO_URI, 'MONGO_URI is required for DB integration tests');

  const { default: mongoose } = await import('mongoose');
  const { default: ProductVariant } = await import('../models/productVariant.model.js');

  await mongoose.connect(process.env.MONGO_URI);
  try {
    const doc = await ProductVariant.findOne().lean();
    assert.ok(doc, 'Expected at least one ProductVariant document');
    assert.ok(doc._id, 'ProductVariant document should have an _id');
  } finally {
    await mongoose.disconnect();
  }
});
