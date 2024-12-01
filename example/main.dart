import 'package:dart_server_plus/dart_server_plus.dart';

const bool sync = false;
const int port = 5555;
void main() async {
  try {
    Server server = Server();

    PostgresClient client = PostgresClient(host: 'localhost', database: 'test', userName: 'postgres', password: "Dharmesh@123");
    await client.connect();
    DartServerPlus orm = DartServerPlus(client: client, schemas: [userSchema], logging: true);
    await orm.sync(syncTable: sync);

    Router userRouter = Router(endPoint: '/users');

    userRouter.post("/insert", (req, res) async {
      var data = await orm.insert(
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

    userRouter.delete("/delete", (req, res) async {
      var data = await orm.delete(table: "users", returning: true, where: {'id': 1});
      return res.json({'data': data});
    });

    userRouter.patch("/update", (req, res) async {
      var data = await orm.update(table: "users", returning: true, data: {'verify': true});
      return res.json({'data': data});
    });

    userRouter.get("/all", (req, res) async {
      var data = await orm.findAncCountAll(table: "users");
      return res.json({'data': data});
    });

    server.registerRouters([userRouter]);

    server.get("/", (req, res) async {
      return res.write("Server are running fine.");
    });

    server.onError((error, res) {
      res.json({'error': error..toString()});
    });

    server.listen(
      port: port,
      callback: () {
        print("Server are listening on port $port");
      },
    );
  } catch (e) {
    print("Exception: ${e.toString()}");
  }
}

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
