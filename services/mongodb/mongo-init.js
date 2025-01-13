// Create database
db = db.getSiblingDB(process.env.MONGO_DATABASE || 'iomt_db');

// Create users
db.createUser({
  user: process.env.MONGO_APP_USERNAME || 'iomt_user',
  pwd: process.env.MONGO_APP_PASSWORD || 'iomt_password',
  roles: [
    { role: 'readWrite', db: process.env.MONGO_DATABASE || 'iomt_db' }
  ]
});

db.createUser({
  user: process.env.MONGO_READONLY_USERNAME || 'iomt_readonly',
  pwd: process.env.MONGO_READONLY_PASSWORD || 'iomt_readonly_password',
  roles: [
    { role: 'read', db: process.env.MONGO_DATABASE || 'iomt_db' }
  ]
});

// Create collections with validation
db.createCollection('devices', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['serial', 'name', 'type'],
      properties: {
        serial: {
          bsonType: 'string',
          description: 'must be a string and is required'
        },
        name: {
          bsonType: 'string',
          description: 'must be a string and is required'
        },
        type: {
          bsonType: 'string',
          description: 'must be a string and is required'
        }
      }
    }
  }
});

db.createCollection('device_templates', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['name', 'variables'],
      properties: {
        name: {
          bsonType: 'string',
          description: 'must be a string and is required'
        },
        variables: {
          bsonType: 'array',
          description: 'must be an array and is required'
        }
      }
    }
  }
});

db.createCollection('medical_variables', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['code', 'name', 'dataType'],
      properties: {
        code: {
          bsonType: 'string',
          description: 'must be a string and is required'
        },
        name: {
          bsonType: 'string',
          description: 'must be a string and is required'
        },
        dataType: {
          enum: ['integer', 'float', 'string', 'boolean', 'date'],
          description: 'must be one of the allowed types and is required'
        }
      }
    }
  }
});

// Create indexes
db.devices.createIndex({ "serial": 1 }, { unique: true });
db.devices.createIndex({ "type": 1 });
db.devices.createIndex({ "createdAt": 1 });

db.device_templates.createIndex({ "name": 1 }, { unique: true });
db.device_templates.createIndex({ "createdAt": 1 });

db.medical_variables.createIndex({ "code": 1 }, { unique: true });
db.medical_variables.createIndex({ "dataType": 1 });

// Insert initial data
db.medical_variables.insertMany([
  {
    code: "heart_rate",
    name: "Heart Rate",
    dataType: "integer",
    unit: "bpm",
    normalRange: { min: 60, max: 100 }
  },
  {
    code: "blood_pressure",
    name: "Blood Pressure",
    dataType: "string",
    unit: "mmHg"
  },
  {
    code: "temperature",
    name: "Body Temperature",
    dataType: "float",
    unit: "°C",
    normalRange: { min: 36.1, max: 37.2 }
  }
]); 