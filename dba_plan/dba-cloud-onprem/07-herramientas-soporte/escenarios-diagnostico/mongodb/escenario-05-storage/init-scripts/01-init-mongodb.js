// MongoDB initialization script for DBA training scenario

// Switch to training database
use('training_db');

// Create users collection
db.users.insertMany([
    {
        _id: ObjectId(),
        username: "john_doe",
        email: "john@example.com",
        profile: {
            firstName: "John",
            lastName: "Doe",
            age: 30
        },
        createdAt: new Date(),
        updatedAt: new Date()
    },
    {
        _id: ObjectId(),
        username: "jane_smith",
        email: "jane@example.com",
        profile: {
            firstName: "Jane",
            lastName: "Smith",
            age: 28
        },
        createdAt: new Date(),
        updatedAt: new Date()
    }
]);

// Create products collection
db.products.insertMany([
    {
        _id: ObjectId(),
        name: "Laptop Pro",
        price: 1299.99,
        category: "electronics",
        stock: 50,
        specifications: {
            cpu: "Intel i7",
            ram: "16GB",
            storage: "512GB SSD"
        },
        tags: ["laptop", "computer", "portable"],
        createdAt: new Date()
    },
    {
        _id: ObjectId(),
        name: "Wireless Mouse",
        price: 29.99,
        category: "accessories",
        stock: 200,
        specifications: {
            connectivity: "Bluetooth",
            battery: "AA"
        },
        tags: ["mouse", "wireless", "accessory"],
        createdAt: new Date()
    }
]);

// Create orders collection
db.orders.insertMany([
    {
        _id: ObjectId(),
        userId: ObjectId(),
        items: [
            {
                productId: ObjectId(),
                quantity: 1,
                price: 1299.99
            }
        ],
        totalAmount: 1299.99,
        status: "completed",
        shippingAddress: {
            street: "123 Main St",
            city: "Anytown",
            zipCode: "12345"
        },
        createdAt: new Date(),
        updatedAt: new Date()
    }
]);

// Create indexes
db.users.createIndex({ "username": 1 }, { unique: true });
db.users.createIndex({ "email": 1 }, { unique: true });
db.products.createIndex({ "category": 1 });
db.products.createIndex({ "price": 1 });
db.products.createIndex({ "tags": 1 });
db.orders.createIndex({ "userId": 1 });
db.orders.createIndex({ "status": 1 });
db.orders.createIndex({ "createdAt": 1 });

print("MongoDB initialization completed successfully");
