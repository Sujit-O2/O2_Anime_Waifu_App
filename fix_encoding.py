import os
import codecs

directory = r'e:\jagan\Flutter\anime_waifu\lib\screens'

for filename in os.listdir(directory):
    if filename.endswith('.dart'):
        filepath = os.path.join(directory, filename)
        
        # Read as UTF-16LE first
        try:
            with open(filepath, 'r', encoding='utf-16le') as f:
                content = f.read()
            if "import " not in content:
                raise UnicodeError("Probably not UTF-16")
        except UnicodeError:
            with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()
                
        # Fix import hiding Container
        content = content.replace("import '../main.dart';", "import '../main.dart' hide Container;")
        content = content.replace("import \"../main.dart\";", "import '../main.dart' hide Container;")

        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f'Fixed encoding and imports for {filename}')
