# dart_server_plus

<br />

dart_server_plus is a sophisticated Object-Relational Mapping (DartServerPlus) library for Dart, aimed at simplifying server-side development and database management. It offers a robust set of features to facilitate the creation and management of servers, connections to databases, and handling of various data operations. With support for both MySQL and PostgreSQL databases, dart_server_plus enables you to build efficient and scalable applications with minimal effort.

<br />

### Key Features
dart_server_plus provides a suite of features that simplify server-side programming and database interactions:

* Server Creation and Management: Quickly set up and configure servers to handle incoming HTTP requests.

* Schema Definition: Define and enforce data structures with various types and constraints.

* Database Connectivity: Connect seamlessly to MySQL and PostgreSQL databases with secure authentication.

* CRUD Operations: Simplify the creation, retrieval, updating, and deletion of records.
Advanced Querying: Support for complex queries, including pagination, ordering, and filtering.

* Relationship Management: Handle related data with ease through nested queries and include options.

* Logging: Optional logging for monitoring SQL queries and debugging issues.


<br />


### Installation

#### To integrate dart_server_plus into your Dart project, follow these steps:

Add Dependency:
Open your pubspec.yaml file and add dart_server_plus under dependencies:
```
dependencies:
  dart_server_plus: ^1.0.0
```  

<br />


### Getting Started

#### Creating a Server
Creating a server with dart_server_plus involves setting up an instance of the Server class and configuring it to listen for incoming connections. Here is a basic example:

```
import 'package:dart_server_plus/dart_server_plus.dart';

void main() {
  // Instantiate the server
  Server server = Server();

  // Start listening on a specified port
  server.listen(
    port: 8080,
    callback: () {
      print("Server is listening on port 8080");
    },
  );
}
```

In this example, the server listens on port 8080. You can customize the port number or other configurations as needed.

<br />

#### Defining a Schema

Schemas define the structure of your database tables, including the fields, data types, and constraints. Here is how you can define a schema for a users table:

```
Schema userSchema = Schema(
  table: "users",
  fields: {
    "id": {
      "type": DataType.SERIAL(),
      "primaryKey": true,
    },
    "username": {
      "type": DataType.STRING(50),
      "unique": true,
      "allowNull": false,
    },
    "first_name": DataType.STRING(50),
    "last_name": DataType.STRING(50),
    "gender": DataType.STRING(10),
    "email": {
      "type": DataType.STRING(100),
      "unique": true,
      "allowNull": false,
    },
    "verify": {
      "type": DataType.BOOLEAN(),
      "default": "FALSE",
      "allowNull": false,
    }
  },
);
```

This schema defines the structure for the users table, specifying the types and constraints for each field. For example, username is a required field with a unique constraint.

<br />

#### Connecting to a Database

To connect to a PostgreSQL or MySQL database, you need to configure the database client with your credentials and connection details. Here’s an example for PostgreSQL:

```
PostgresClient client = PostgresClient(
  host: 'localhost',
  database: 'test',
  userName: 'postgres',
  password: '123456'
);
await client.connect();
```

Replace the placeholder values with your actual database host, database name, username, and password.

<br />

#### Initializing the DartServerPlus

Once you have defined your schema and established a database connection, you can initialize the DartServerPlus and synchronize the database schema:
```
DartServerPlus dartServerPlus = DartServerPlus(client: client, schemas: [userSchema], logging: true);
await dartServerPlus.sync(syncTable: true);
```
This code initializes the DartServerPlus with the database client and schema, and synchronizes the schema with the database. The syncTable parameter ensures that existing tables are updated or recreated as necessary.


Registering Routes and Performing CRUD Operations
With dart_server_plus, you can easily set up routes to handle different types of HTTP requests. Below are examples for performing various CRUD operations.


Inserting a New Record

To handle a POST request for inserting a new record:
```
userRouter.post("/insert", (req, res) async {
  var data = await DartServerPlus.insert(
    table: "users",
    returning: true,
    data: {
      "username": "test",
      "first_name": "Test",
      "last_name": "User",
      "email": "test@mailinator.com",
      "gender": "male",
      "verify": false,
    },
  );
  return res.json({'data': data});
});
```

This route inserts a new user record into the users table and returns the inserted data.

<br />

#### Deleting a Record

To handle a DELETE request for removing a record:

```
userRouter.delete("/delete", (req, res) async {
  var data = await DartServerPlus.delete(
    table: "users",
    returning: true,
    where: {'id': 1}
  );
  return res.json({'data': data});
});
```

This route deletes a user record with the specified id and returns the result of the deletion.

<br />

#### Updating an Existing Record

To handle a PATCH request for updating an existing record:

```
userRouter.patch("/update", (req, res) async {
  var data = await DartServerPlus.update(
    table: "users",
    returning: true,
    data: {'verify': true}
  );
  return res.json({'data': data});
});
```

This route updates the verify field for user records and returns the updated data.

<br />

#### Fetching Records
To handle a GET request for retrieving all records:

```
userRouter.get("/all", (req, res) async {
  var data = await DartServerPlus.findAll(table: "users");
  return res.json({'data': data});
});
```

This route retrieves all user records from the users table and returns them in the response.

<br />

#### Advanced Query Capabilities

dart_server_plus offers a range of advanced querying capabilities to meet complex data retrieval needs.

Counting Records<br />
To count the number of records in a table:

```
var data = await DartServerPlus.count(table: "users");
```
This query returns the total number of records in the users table.

<br />

#### Fetching Specific Fields

To retrieve only specific fields from a table:

```
var data = await DartServerPlus.findAll(
  table: "users",
  fields: ['id', 'first_name', 'last_name']
);
```

This query fetches only the id, first_name, and last_name fields from the users table.

<br />

#### Pagination and Ordering

To apply pagination and ordering to your queries:

```
var data = await DartServerPlus.findAncCountAll(
  table: "users",
  limit: 10,
  offset: 0,
  order: {'id': false}
);
```

This query retrieves records with pagination (10 records per page) and orders them by id in descending order.

<br />

#### Filtering Results
To apply filters to your queries:

```
var data = await DartServerPlus.findAncCountAll(
  table: "users",
  where: {
    Op.lte: {'id': 10},
    'gender': 'male'
  }
);
```

This query filters records to include only those with id less than or equal to 10 and gender equal to male.

<br />

#### Including Related Tables
To include related tables in your queries:

```
var data = await DartServerPlus.findAncCountAll(
  table: "users",
  include: [{'table': 'address'}]
);
```

This query includes data from the address table related to the users table.

<br />

### Performance Considerations
When working with large datasets, consider the following tips to optimize performance:

* Indexing: Ensure that your database tables have appropriate indexes on frequently queried fields to speed up search operations.

* Pagination: Use pagination to limit the amount of data retrieved in a single query, improving performance and reducing memory usage.

* Query Optimization: Analyze and optimize your SQL queries to ensure they execute efficiently.

* Connection Pooling: Use connection pooling to manage database connections efficiently, reducing the overhead of establishing new connections.