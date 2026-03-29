import 'dart:io';

void main() {
  final file = File('assets/template/zero_two_email_template.html');
  var content = file.readAsStringSync();
  
  // Replace base64 image
  final imgUrl = 'https://i.ibb.co/5xnnZ59t/6226495638011489047-121.jpg';
  final regex = RegExp(r'src="data:image\/[^"]+"');
  if (regex.hasMatch(content)) {
    content = content.replaceFirst(regex, 'src="$imgUrl"');
    print('✅ Image URL replaced successfully.');
  } else {
    print('⚠️ Base64 image not found.');
  }

  // Mobile css fix
  if (content.contains('.meta-cell      { display: block !important; margin-bottom: 8px !important; }')) {
    content = content.replaceAll(
        '.meta-cell      { display: block !important; margin-bottom: 8px !important; }',
        '.meta-cell      { display: block !important; width: 100% !important; margin-bottom: 12px !important; text-align: center !important; }'
    );
     print('✅ CSS Media queries updated.');
  }

  // Fix the alignment of each chip table cell
  content = content.replaceAll(
    '<td class="meta-cell" style="padding-right:8px; padding-bottom:0;">',
    '<td class="meta-cell" align="center" style="padding-bottom:12px; width: 100%;">'
  );
  content = content.replaceAll(
    '<td class="meta-cell" style="padding-bottom:0;">',
    '<td class="meta-cell" align="center" style="padding-bottom:0; width: 100%;">'
  );
  
  file.writeAsStringSync(content);
  print('🎉 Template modifications complete!');
}
