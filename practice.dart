import 'dart:async';
import 'dart:convert';

/// -----------------------------
/// Abstract Repository
/// -----------------------------
abstract class Repository<T> {
  Future<List<T>> fetchAll();
  Future<T> fetchById(int id);
}

/// -----------------------------
/// User Model
/// -----------------------------
class User {
  final int id;
  final String name;
  final String email;

  User({
    required this.id,
    required this.name,
    required this.email,
  });

  /// Factory constructor for JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }

  @override
  String toString() => 'User(id: $id, name: $name, email: $email)';
}

/// -----------------------------
/// Fake API Service (Simulated Network)
/// -----------------------------
class FakeApiService {
  final List<Map<String, dynamic>> _database = [
    {'id': 1, 'name': 'Alice', 'email': 'alice@mail.com'},
    {'id': 2, 'name': 'Bob', 'email': 'bob@mail.com'},
    {'id': 3, 'name': 'Charlie', 'email': 'charlie@mail.com'},
  ];

  Future<String> getUsersJson() async {
    await Future.delayed(Duration(seconds: 2)); // simulate delay
    return jsonEncode(_database);
  }
}

/// -----------------------------
/// User Repository Implementation
/// -----------------------------
class UserRepository implements Repository<User> {
  final FakeApiService apiService;

  UserRepository(this.apiService);

  @override
  Future<List<User>> fetchAll() async {
    try {
      final jsonString = await apiService.getUsersJson();
      final List<dynamic> decoded = jsonDecode(jsonString);

      return decoded.map((e) => User.fromJson(e)).toList();
    } catch (e) {
      throw Exception("Failed to fetch users: $e");
    }
  }

  @override
  Future<User> fetchById(int id) async {
    final users = await fetchAll();
    return users.firstWhere(
      (user) => user.id == id,
      orElse: () => throw Exception("User not found"),
    );
  }
}

/// -----------------------------
/// Stream Example (Live Updates)
/// -----------------------------
class UserStreamService {
  final StreamController<User> _controller =
      StreamController<User>.broadcast();

  Stream<User> get userStream => _controller.stream;

  void addUser(User user) {
    _controller.add(user);
  }

  void dispose() {
    _controller.close();
  }
}

/// -----------------------------
/// MAIN FUNCTION
/// -----------------------------
Future<void> main() async {
  final apiService = FakeApiService();
  final repository = UserRepository(apiService);
  final userStreamService = UserStreamService();

  print("Fetching users from API...\n");

  try {
    // Async fetch
    final users = await repository.fetchAll();
    users.forEach(print);

    print("\nFetching user by ID (2):");
    final user = await repository.fetchById(2);
    print(user);

  } catch (e) {
    print("Error: $e");
  }

  /// Stream listening
  print("\nListening for new users...\n");

  userStreamService.userStream.listen((user) {
    print("New user added via stream: $user");
  });

  /// Add users to stream
  userStreamService.addUser(
    User(id: 4, name: "David", email: "david@mail.com"),
  );

  await Future.delayed(Duration(seconds: 1));

  userStreamService.addUser(
    User(id: 5, name: "Eva", email: "eva@mail.com"),
  );

  userStreamService.dispose();
}
