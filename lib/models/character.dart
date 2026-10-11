class Character {
  String name;
  String rarity;
  String role;

  int level;
  int exp;

  int hp;
  int atk;
  int def;

  Character({
    required this.name,
    required this.rarity,
    required this.role,
    this.level = 1,
    this.exp = 0,
    this.hp = 500,
    this.atk = 50,
    this.def = 30,
  });

  // EXP required to reach the next level.
  int get expToNextLevel => 100;

  // Add EXP and process level-ups.
  void addExp(int amount) {
    if (amount <= 0) return;

    exp += amount;

    while (exp >= expToNextLevel) {
      exp -= expToNextLevel;
      level++;

      hp += 50;
      atk += 5;
      def += 3;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'rarity': rarity,
      'role': role,
      'level': level,
      'exp': exp,
      'hp': hp,
      'atk': atk,
      'def': def,
    };
  }

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      name: json['name'],
      rarity: json['rarity'],
      role: json['role'],
      level: json['level'] ?? 1,
      exp: json['exp'] ?? 0,
      hp: json['hp'] ?? 500,
      atk: json['atk'] ?? 50,
      def: json['def'] ?? 30,
    );
  }
}