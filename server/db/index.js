const mongoose = require('mongoose');

const connectionString = 'mongodb://db:27020/cinema∫';

mongoose.connect(connectionString, { useNewUrlParser: true }).catch((e) => {
  console.error('Connection error', e.message);
});

const db = mongoose.connection;

module.exports = db;
