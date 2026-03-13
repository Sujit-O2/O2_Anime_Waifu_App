import os

files = [
    r'e:\jagan\Flutter\anime_waifu\lib\screens\commands_page.dart',
    r'e:\jagan\Flutter\anime_waifu\lib\screens\image_pack_page.dart',
    r'e:\jagan\Flutter\anime_waifu\lib\screens\mini_games_page.dart',
    r'e:\jagan\Flutter\anime_waifu\lib\screens\music_player_page.dart',
    r'e:\jagan\Flutter\anime_waifu\lib\screens\theme_accent_page.dart',
]

for path in files:
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    content = content.replace("import '../main.dart' hide Container;", "import '../main.dart';")
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print('Fixed:', os.path.basename(path))
