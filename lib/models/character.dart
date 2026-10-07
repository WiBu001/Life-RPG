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
      level: json['level'],
      exp: json['exp'],
      hp: json['hp'],
      atk: json['atk'],
      def: json['def'],
    );
  }
}