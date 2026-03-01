import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart';

class OpenAppActionResult {
  final bool launched;
  final String assistantMessage;

  const OpenAppActionResult({
    required this.launched,
    required this.assistantMessage,
  });
}

class OpenAppService {
  static final RegExp _openActionPattern = RegExp(
    r'^\s*Action\s*:\s*open[\s_-]*app\s*$',
    caseSensitive: false,
    multiLine: true,
  );

  static final RegExp _appLinePattern = RegExp(
    r'^\s*App\s*:\s*(.+?)\s*$',
    caseSensitive: false,
    multiLine: true,
  );

  static Future<OpenAppActionResult?> handleAssistantReply(
    String reply,
  ) async {
    if (!_openActionPattern.hasMatch(reply)) return null;

    final appMatch = _appLinePattern.firstMatch(reply);
    if (appMatch == null) {
      return const OpenAppActionResult(
        launched: false,
        assistantMessage: "Tell me the app name clearly so I can open it.",
      );
    }

    final appName = appMatch.group(1)?.trim() ?? "";
    if (appName.isEmpty) {
      return const OpenAppActionResult(
        launched: false,
        assistantMessage: "Tell me the app name clearly so I can open it.",
      );
    }

    if (!Platform.isAndroid) {
      return OpenAppActionResult(
        launched: false,
        assistantMessage: "I can open apps only on Android right now.",
      );
    }

    final normalized = _normalize(appName);
    final appKey = _canonicalizeAppKey(normalized);
    final packageCandidates = _resolvePackageCandidates(appKey);
    for (final packageName in packageCandidates) {
      final launched = await _launchPackage(packageName);
      if (launched) {
        return OpenAppActionResult(
          launched: true,
          assistantMessage: "Opening $appName.",
        );
      }
    }

    final launchedSystemIntent = await _launchSystemIntent(appKey);
    if (launchedSystemIntent) {
      return OpenAppActionResult(
        launched: true,
        assistantMessage: "Opening $appName.",
      );
    }

    if (packageCandidates.isEmpty) {
      return OpenAppActionResult(
        launched: false,
        assistantMessage:
            "I could not map \"$appName\" yet. Tell me the exact app name.",
      );
    }

    return OpenAppActionResult(
      launched: false,
      assistantMessage: "I cannot open $appName here. It may not be installed.",
    );
  }

  static String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  static String _canonicalizeAppKey(String app) {
    var key = app;
    key = key.replaceFirst(RegExp(r'^(open|launch|start|use)+'), '');
    key = key.replaceFirst(RegExp(r'(app|apps|application|applications)$'), '');

    switch (key) {
      case 'watsapp':
      case 'whatsap':
      case 'whatsup':
      case 'ewhatsapp':
      case 'ewhatsap':
      case 'whatsappmessenger':
        return 'whatsapp';
      case 'googlemail':
      case 'gmailmail':
        return 'gmail';
      default:
        return key;
    }
  }

  static List<String> _resolvePackageCandidates(String app) {
    switch (app) {
      case 'whatsapp':
        return const [
          'com.whatsapp',
          'com.whatsapp.w4b',
        ];
      case 'gmail':
        return const [
          'com.google.android.gm',
        ];
      case 'videoplayer':
      case 'videoplayerapp':
      case 'videoplayerapps':
      case 'mediaplayer':
      case 'player':
      case 'video':
      case 'videos':
      case 'movieplayer':
        return const [
          'com.mxtech.videoplayer.ad',
          'org.videolan.vlc',
          'com.google.android.apps.photos',
        ];
      default:
        final packageName = _resolvePackageName(app);
        return packageName == null ? const [] : [packageName];
    }
  }

  static Future<bool> _launchPackage(String packageName) async {
    if (await _tryLaunch(
      AndroidIntent(
        action: 'android.intent.action.MAIN',
        category: 'android.intent.category.LAUNCHER',
        package: packageName,
      ),
    )) {
      return true;
    }

    if (await _tryLaunch(
      AndroidIntent(
        action: 'android.intent.action.MAIN',
        package: packageName,
      ),
    )) {
      return true;
    }

    if (await _tryLaunch(AndroidIntent(package: packageName))) {
      return true;
    }

    debugPrint("OpenAppService package launch failed: $packageName");
    return false;
  }

  static Future<bool> _launchSystemIntent(String app) async {
    switch (app) {
      case 'settings':
      case 'setting':
      case 'systemsettings':
      case 'appsettings':
        return _launchIntent(action: 'android.settings.SETTINGS');
      case 'wifi':
      case 'wifisettings':
        return _launchIntent(action: 'android.settings.WIFI_SETTINGS');
      case 'bluetooth':
      case 'bluetoothsettings':
        return _launchIntent(action: 'android.settings.BLUETOOTH_SETTINGS');
      case 'location':
      case 'gps':
      case 'locationsettings':
        return _launchIntent(
            action: 'android.settings.LOCATION_SOURCE_SETTINGS');
      case 'security':
      case 'securitysettings':
        return _launchIntent(action: 'android.settings.SECURITY_SETTINGS');
      case 'display':
      case 'displaysettings':
        return _launchIntent(action: 'android.settings.DISPLAY_SETTINGS');
      case 'sound':
      case 'volume':
      case 'soundsettings':
        return _launchIntent(action: 'android.settings.SOUND_SETTINGS');
      case 'notification':
      case 'notifications':
      case 'notificationsettings':
        return _launchIntent(action: 'android.settings.NOTIFICATION_SETTINGS');
      case 'battery':
      case 'batterysettings':
        return _launchIntent(action: 'android.settings.BATTERY_SAVER_SETTINGS');
      case 'dateandtime':
      case 'timesettings':
        return _launchIntent(action: 'android.settings.DATE_SETTINGS');
      case 'tethering':
      case 'hotspot':
      case 'hotspotsettings':
        return _launchIntent(action: 'android.settings.TETHER_SETTINGS');
      case 'contacts':
      case 'contact':
      case 'people':
      case 'contactsapp':
        return _launchIntent(
          action: 'android.intent.action.MAIN',
          category: 'android.intent.category.APP_CONTACTS',
        );
      case 'phone':
      case 'dialer':
      case 'call':
      case 'calls':
      case 'phoneapp':
        return _launchIntent(action: 'android.intent.action.DIAL');
      case 'messages':
      case 'message':
      case 'sms':
      case 'textmessages':
      case 'messaging':
        return _launchIntent(
          action: 'android.intent.action.MAIN',
          category: 'android.intent.category.APP_MESSAGING',
        );
      case 'camera':
      case 'cameraapp':
        return _launchIntent(
          action: 'android.intent.action.MAIN',
          category: 'android.intent.category.APP_CAMERA',
        );
      case 'gallery':
      case 'photos':
      case 'galleryapp':
        return _launchIntent(
          action: 'android.intent.action.MAIN',
          category: 'android.intent.category.APP_GALLERY',
        );
      case 'browser':
      case 'internet':
      case 'webbrowser':
        return _launchIntent(
          action: 'android.intent.action.MAIN',
          category: 'android.intent.category.APP_BROWSER',
        );
      case 'calendar':
      case 'calendarapp':
        return _launchIntent(
          action: 'android.intent.action.MAIN',
          category: 'android.intent.category.APP_CALENDAR',
        );
      case 'email':
      case 'mail':
      case 'emailapp':
      case 'gmail':
        return _launchIntent(
          action: 'android.intent.action.MAIN',
          category: 'android.intent.category.APP_EMAIL',
        );
      case 'calculator':
      case 'calc':
        return _launchIntent(
          action: 'android.intent.action.MAIN',
          category: 'android.intent.category.APP_CALCULATOR',
        );
      case 'clock':
      case 'alarm':
      case 'alarmclock':
        return _launchIntent(action: 'android.intent.action.SHOW_ALARMS');
      case 'files':
      case 'filemanager':
      case 'fileexplorer':
      case 'myfiles':
        return _launchIntent(action: 'android.intent.action.OPEN_DOCUMENT_TREE');
      default:
        return false;
    }
  }

  static Future<bool> _launchIntent({
    required String action,
    String? category,
    String? data,
  }) async {
    return _tryLaunch(
      AndroidIntent(
        action: action,
        category: category,
        data: data,
      ),
    );
  }

  static Future<bool> _tryLaunch(AndroidIntent intent) async {
    try {
      await intent.launch();
      return true;
    } catch (e) {
      debugPrint("OpenAppService launch attempt failed: $e");
      return false;
    }
  }

  // Switch map with 200+ commonly used app names.
  static String? _resolvePackageName(String app) {
    switch (app) {
      case 'whatsapp':
        return 'com.whatsapp';
      case 'whatsappbusiness':
        return 'com.whatsapp.w4b';
      case 'telegram':
        return 'org.telegram.messenger';
      case 'telegramx':
        return 'org.thunderdog.challegram';
      case 'signal':
        return 'org.thoughtcrime.securesms';
      case 'messenger':
        return 'com.facebook.orca';
      case 'facebook':
        return 'com.facebook.katana';
      case 'facebooklite':
        return 'com.facebook.lite';
      case 'instagram':
        return 'com.instagram.android';
      case 'threads':
        return 'com.instagram.barcelona';
      case 'twitter':
      case 'x':
        return 'com.twitter.android';
      case 'snapchat':
        return 'com.snapchat.android';
      case 'reddit':
        return 'com.reddit.frontpage';
      case 'pinterest':
        return 'com.pinterest';
      case 'tumblr':
        return 'com.tumblr';
      case 'linkedin':
        return 'com.linkedin.android';
      case 'discord':
        return 'com.discord';
      case 'skype':
        return 'com.skype.raider';
      case 'imo':
        return 'com.imo.android.imoim';
      case 'viber':
        return 'com.viber.voip';
      case 'line':
        return 'jp.naver.line.android';
      case 'kakaotalk':
        return 'com.kakao.talk';
      case 'wechat':
        return 'com.tencent.mm';
      case 'vk':
        return 'com.vkontakte.android';
      case 'quora':
        return 'com.quora.android';
      case 'sharechat':
        return 'in.mohalla.sharechat';
      case 'moj':
        return 'com.sharechat.moj';
      case 'chingari':
        return 'io.chingari.app';
      case 'tiktok':
        return 'com.zhiliaoapp.musically';
      case 'triller':
        return 'co.triller.droid';
      case 'clubhouse':
        return 'com.clubhouse.app';
      case 'koo':
        return 'com.koo.app';
      case 'hike':
        return 'com.bsb.hike';
      case 'kik':
        return 'kik.android';
      case 'truthsocial':
        return 'com.truthsocial.android.app';
      case 'mastodon':
        return 'org.joinmastodon.android';
      case 'bluesky':
        return 'xyz.blueskyweb.app';
      case 'gmail':
        return 'com.google.android.gm';
      case 'outlook':
        return 'com.microsoft.office.outlook';
      case 'yahoomail':
        return 'com.yahoo.mobile.client.android.mail';
      case 'protonmail':
        return 'ch.protonmail.android';
      case 'sparkmail':
        return 'com.readdle.spark';
      case 'slack':
        return 'com.Slack';
      case 'teams':
        return 'com.microsoft.teams';
      case 'zoom':
        return 'us.zoom.videomeetings';
      case 'googlemeet':
        return 'com.google.android.apps.meetings';
      case 'webex':
        return 'com.cisco.webex.meetings';
      case 'notion':
        return 'notion.id';
      case 'evernote':
        return 'com.evernote';
      case 'todoist':
        return 'com.todoist';
      case 'trello':
        return 'com.trello';
      case 'asana':
        return 'com.asana.app';
      case 'clickup':
        return 'co.clickup.app';
      case 'monday':
        return 'com.monday.container';
      case 'googledrive':
        return 'com.google.android.apps.docs';
      case 'googledocs':
        return 'com.google.android.apps.docs.editors.docs';
      case 'googlesheets':
        return 'com.google.android.apps.docs.editors.sheets';
      case 'googleslides':
        return 'com.google.android.apps.docs.editors.slides';
      case 'googlekeep':
      case 'keepnotes':
        return 'com.google.android.keep';
      case 'googlecalendar':
        return 'com.google.android.calendar';
      case 'onedrive':
        return 'com.microsoft.skydrive';
      case 'word':
        return 'com.microsoft.office.word';
      case 'excel':
        return 'com.microsoft.office.excel';
      case 'powerpoint':
        return 'com.microsoft.office.powerpoint';
      case 'office':
        return 'com.microsoft.office.officehubrow';
      case 'adobereader':
        return 'com.adobe.reader';
      case 'canva':
        return 'com.canva.editor';
      case 'figma':
        return 'com.figma.mirror';
      case 'miro':
        return 'com.realtimeboard';
      case 'wpsoffice':
        return 'cn.wps.moffice_eng';
      case 'chatgpt':
        return 'com.openai.chatgpt';
      case 'gemini':
        return 'com.google.android.apps.bard';
      case 'copilot':
        return 'com.microsoft.copilot';
      case 'perplexity':
        return 'ai.perplexity.app.android';
      case 'grammarly':
        return 'com.grammarly.android.keyboard';
      case 'dropbox':
        return 'com.dropbox.android';
      case 'box':
        return 'com.box.android';
      case 'simplenote':
        return 'com.automattic.simplenote';
      case 'xodo':
        return 'com.xodo.pdf.reader';
      case 'camscanner':
        return 'com.intsig.camscanner';
      case 'jira':
        return 'com.atlassian.android.jira.core';
      case 'confluence':
        return 'com.atlassian.confluence';
      case 'github':
        return 'com.github.android';
      case 'gitlab':
        return 'com.gitlab.android';
      case 'stackoverflow':
        return 'com.stackexchange.marvin';
      case 'medium':
        return 'com.medium.reader';
      case 'chrome':
        return 'com.android.chrome';
      case 'chromebeta':
        return 'com.chrome.beta';
      case 'firefox':
        return 'org.mozilla.firefox';
      case 'firefoxfocus':
        return 'org.mozilla.focus';
      case 'edge':
        return 'com.microsoft.emmx';
      case 'opera':
        return 'com.opera.browser';
      case 'operamini':
        return 'com.opera.mini.native';
      case 'brave':
        return 'com.brave.browser';
      case 'duckduckgo':
        return 'com.duckduckgo.mobile.android';
      case 'samsunginternet':
        return 'com.sec.android.app.sbrowser';
      case 'vivaldi':
        return 'com.vivaldi.browser';
      case 'torbrowser':
        return 'org.torproject.torbrowser';
      case 'ucbrowser':
        return 'com.UCMobile.intl';
      case 'kiwibrowser':
        return 'com.kiwibrowser.browser';
      case 'arcsearch':
        return 'company.thebrowser.arc';
      case 'youtube':
        return 'com.google.android.youtube';
      case 'youtubemusic':
        return 'com.google.android.apps.youtube.music';
      case 'netflix':
        return 'com.netflix.mediaclient';
      case 'primevideo':
        return 'com.amazon.avod.thirdpartyclient';
      case 'disneyplus':
        return 'com.disney.disneyplus';
      case 'hotstar':
        return 'in.startv.hotstar';
      case 'jiocinema':
        return 'com.jio.media.ondemand';
      case 'sonyliv':
        return 'com.sonyliv';
      case 'zee5':
        return 'com.graymatrix.did';
      case 'voot':
        return 'com.tv.v18.viola';
      case 'mxplayer':
        return 'com.mxtech.videoplayer.ad';
      case 'vlc':
        return 'org.videolan.vlc';
      case 'spotify':
        return 'com.spotify.music';
      case 'applemusic':
        return 'com.apple.android.music';
      case 'amazonmusic':
        return 'com.amazon.mp3';
      case 'wynk':
        return 'com.bsbportal.music';
      case 'gaana':
        return 'com.gaana';
      case 'jiosaavn':
        return 'com.jio.media.jiobeats';
      case 'soundcloud':
        return 'com.soundcloud.android';
      case 'shazam':
        return 'com.shazam.android';
      case 'tidal':
        return 'com.aspiro.tidal';
      case 'deezer':
        return 'deezer.android.app';
      case 'pandora':
        return 'com.pandora.android';
      case 'audible':
        return 'com.audible.application';
      case 'pocketfm':
        return 'com.radio.pocketfm';
      case 'iheartradio':
        return 'com.clearchannel.iheartradio.controller';
      case 'stitcher':
        return 'com.stitcher.app';
      case 'podcastaddict':
        return 'com.bambuna.podcastaddict';
      case 'twitch':
        return 'tv.twitch.android.app';
      case 'crunchyroll':
        return 'com.crunchyroll.crunchyroid';
      case 'bilibili':
        return 'tv.danmaku.bili';
      case 'imdb':
        return 'com.imdb.mobile';
      case 'letterboxd':
        return 'com.letterboxd.letterboxd';
      case 'googlephotos':
        return 'com.google.android.apps.photos';
      case 'snapseed':
        return 'com.niksoftware.snapseed';
      case 'picsart':
        return 'com.picsart.studio';
      case 'lightroom':
        return 'com.adobe.lrmobile';
      case 'vsco':
        return 'com.vsco.cam';
      case 'inshot':
        return 'com.camerasideas.instashot';
      case 'capcut':
        return 'com.lemon.lvoverseas';
      case 'kinemaster':
        return 'com.nexstreaming.app.kinemasterfree';
      case 'filmora':
        return 'com.wondershare.filmorago';
      case 'remini':
        return 'com.bigwinepot.nwdn.international';
      case 'b612':
        return 'com.linecorp.b612.android';
      case 'beautyplus':
        return 'com.commsource.beautyplus';
      case 'facetune':
        return 'com.lightricks.facetune.free';
      case 'meitu':
        return 'com.mt.mtxx.mtxx';
      case 'pixlr':
        return 'com.pixlr.express';
      case 'adobeexpress':
        return 'com.adobe.spark.post';
      case 'amazon':
        return 'com.amazon.mShop.android.shopping';
      case 'flipkart':
        return 'com.flipkart.android';
      case 'myntra':
        return 'com.myntra.android';
      case 'meesho':
        return 'com.meesho.supply';
      case 'ajio':
        return 'com.ril.ajio';
      case 'nykaa':
        return 'com.fsn.nykaa';
      case 'jiomart':
        return 'com.jpl.jiomart';
      case 'snapdeal':
        return 'com.snapdeal.main';
      case 'ebay':
        return 'com.ebay.mobile';
      case 'etsy':
        return 'com.etsy.android';
      case 'aliexpress':
        return 'com.alibaba.aliexpresshd';
      case 'temu':
        return 'com.einnovation.temu';
      case 'shein':
        return 'com.zzkko';
      case 'walmart':
        return 'com.walmart.android';
      case 'target':
        return 'com.target.ui';
      case 'bestbuy':
        return 'com.bestbuy.android';
      case 'costco':
        return 'com.costco.app.android';
      case 'ikea':
        return 'com.ingka.ikea.app';
      case 'homedepot':
        return 'com.thehomedepot.hdphone';
      case 'tatacliq':
        return 'com.tul.tatacliq';
      case 'firstcry':
        return 'com.firstcry.firstcry';
      case 'pepperfry':
        return 'com.pepperfry';
      case 'decathlon':
        return 'com.decathlon.app';
      case 'zara':
        return 'com.inditex.zara';
      case 'hm':
        return 'com.hm.goe';
      case 'zomato':
        return 'com.application.zomato';
      case 'swiggy':
        return 'in.swiggy.android';
      case 'doordash':
        return 'com.dd.doordash';
      case 'grubhub':
        return 'com.grubhub.android';
      case 'ubereats':
        return 'com.ubercab.eats';
      case 'blinkit':
        return 'com.grofers.customerapp';
      case 'zepto':
        return 'com.zeptoconsumerapp';
      case 'bigbasket':
        return 'com.bigbasket.mobileapp';
      case 'instacart':
        return 'com.instacart.client';
      case 'dunzo':
        return 'com.dunzo.user';
      case 'starbucks':
        return 'com.starbucks.mobilecard';
      case 'mcdelivery':
        return 'com.mcdonalds.app';
      case 'dominos':
        return 'com.Dominos';
      case 'pizzahut':
        return 'com.pizzahut.uk';
      case 'uber':
        return 'com.ubercab';
      case 'ola':
        return 'com.olacabs.customer';
      case 'rapido':
        return 'com.rapido.passenger';
      case 'indrive':
        return 'sinet.startup.inDriver';
      case 'lyft':
        return 'me.lyft.android';
      case 'googlemaps':
      case 'maps':
        return 'com.google.android.apps.maps';
      case 'waze':
        return 'com.waze';
      case 'airbnb':
        return 'com.airbnb.android';
      case 'booking':
        return 'com.booking';
      case 'agoda':
        return 'com.agoda.mobile.consumer';
      case 'makemytrip':
        return 'com.makemytrip';
      case 'goibibo':
        return 'com.goibibo';
      case 'easemytrip':
        return 'com.easemytrip.android';
      case 'tripadvisor':
        return 'com.tripadvisor.tripadvisor';
      case 'skyscanner':
        return 'net.skyscanner.android.main';
      case 'ixigo':
        return 'com.ixigo';
      case 'yatra':
        return 'com.yatra.base';
      case 'cleartrip':
        return 'com.cleartrip.android';
      case 'irctc':
        return 'cris.org.in.prs.ima';
      case 'redbus':
        return 'in.redbus.android';
      case 'abhibus':
        return 'com.abhibus';
      case 'confirmtkt':
        return 'com.confirmtkt.lite';
      case 'whereismytrain':
        return 'com.whereismytrain.android';
      case 'googlepay':
      case 'gpay':
        return 'com.google.android.apps.nbu.paisa.user';
      case 'phonepe':
        return 'com.phonepe.app';
      case 'paytm':
        return 'net.one97.paytm';
      case 'paypal':
        return 'com.paypal.android.p2pmobile';
      case 'venmo':
        return 'com.venmo';
      case 'cashapp':
        return 'com.squareup.cash';
      case 'revolut':
        return 'com.revolut.revolut';
      case 'wise':
        return 'com.transferwise.android';
      case 'cred':
        return 'com.dreamplug.androidapp';
      case 'groww':
        return 'com.nextbillion.groww';
      case 'zerodha':
      case 'kite':
        return 'com.zerodha.kite3';
      case 'upstox':
        return 'in.upstox.pro';
      case 'angelone':
        return 'com.msf.angelmobile';
      case 'coinbase':
        return 'com.coinbase.android';
      case 'binance':
        return 'com.binance.dev';
      case 'kraken':
        return 'com.kraken.invest.app';
      case 'robinhood':
        return 'com.robinhood.android';
      case 'etrade':
        return 'com.etrade.mobilepro.activity';
      case 'moneycontrol':
        return 'com.divum.MoneyControl';
      case 'etmoney':
        return 'com.etmoney';
      case 'yono':
        return 'com.sbi.lotusintouch';
      case 'hdfcbank':
        return 'com.snapwork.hdfc';
      case 'iciciimobile':
        return 'com.csam.icici.bank.imobile';
      case 'axismobile':
        return 'com.axis.mobile';
      case 'kotakbank':
        return 'com.kotak.bank.mobile';
      case 'bobworld':
        return 'com.csam.bob';
      case 'pnbone':
        return 'com.pnbindia.pnb';
      case 'canaraai1':
        return 'com.canarabank.mobility';
      case 'idfcfirst':
        return 'com.idfcfirstbank.optimus';
      case 'chase':
        return 'com.chase.sig.android';
      case 'bankofamerica':
        return 'com.infonow.bofa';
      case 'wellsfargo':
        return 'com.wf.wellsfargomobile';
      case 'capitalone':
        return 'com.konylabs.capitalone';
      case 'americanexpress':
        return 'com.americanexpress.android.acctsvcs.us';
      case 'chime':
        return 'com.onedebit.chime';
      case 'bhim':
        return 'in.org.npci.upiapp';
      case 'freecharge':
        return 'com.freecharge.android';
      case 'mobikwik':
        return 'com.mobikwik_new';
      case 'slice':
        return 'com.sliceit.android';
      case 'famapp':
        return 'in.trinkerr.vself';
      case 'googlenews':
        return 'com.google.android.apps.magazines';
      case 'inshorts':
        return 'com.nis.app';
      case 'dailyhunt':
        return 'com.eterno';
      case 'bbcnews':
        return 'bbc.mobile.news.ww';
      case 'cnn':
        return 'com.cnn.mobile.android.phone';
      case 'nytimes':
        return 'com.nytimes.android';
      case 'theguardian':
        return 'com.guardian';
      case 'wsj':
        return 'android.wsj.com';
      case 'feedly':
        return 'com.devhd.feedly';
      case 'flipboard':
        return 'flipboard.app';
      case 'kindle':
        return 'com.amazon.kindle';
      case 'goodreads':
        return 'com.goodreads';
      case 'cricbuzz':
        return 'com.cricbuzz.android';
      case 'espn':
        return 'com.espn.score_center';
      case 'fancode':
        return 'com.dreamsports.fancode';
      case 'nba':
        return 'com.nbaimd.gametime.nba2011';
      case 'nfl':
        return 'com.gotv.nflgamecenter.us.lite';
      case 'sofascore':
        return 'com.sofascore.results';
      case 'onefootball':
        return 'de.motain.iliga';
      case 'fotmob':
        return 'com.mobilefootie.wc2010';
      case 'strava':
        return 'com.strava';
      case 'nikerunclub':
        return 'com.nike.plusgps';
      case 'adidasrunning':
        return 'com.runtastic.android';
      case 'fitbit':
        return 'com.fitbit.FitbitMobile';
      case 'samsunghealth':
        return 'com.sec.android.app.shealth';
      case 'myfitnesspal':
        return 'com.myfitnesspal.android';
      case 'healthifyme':
        return 'com.healthifyme.basic';
      case 'practo':
        return 'com.practo.fabric';
      case 'apollopharmacy':
        return 'com.apollo.pharmacy';
      case 'netmeds':
        return 'com.NetmedsMarketplace.Netmeds';
      case 'pharmeasy':
        return 'com.phonegap.rxpal';
      case 'roblox':
        return 'com.roblox.client';
      case 'minecraft':
        return 'com.mojang.minecraftpe';
      case 'clashofclans':
        return 'com.supercell.clashofclans';
      case 'clashroyale':
        return 'com.supercell.clashroyale';
      case 'brawlstars':
        return 'com.supercell.brawlstars';
      case 'bgmi':
        return 'com.pubg.imobile';
      case 'pubgmobile':
        return 'com.tencent.ig';
      case 'codmobile':
        return 'com.activision.callofduty.shooter';
      case 'freefire':
        return 'com.dts.freefireth';
      case 'freefiremax':
        return 'com.dts.freefiremax';
      case 'amongus':
        return 'com.innersloth.spacemafia';
      case 'candycrush':
        return 'com.king.candycrushsaga';
      case 'subwaysurfers':
        return 'com.kiloo.subwaysurf';
      case 'ludoking':
        return 'com.ludo.king';
      case 'eightballpool':
        return 'com.miniclip.eightballpool';
      case 'pokemongo':
        return 'com.nianticlabs.pokemongo';
      case 'genshinimpact':
        return 'com.miHoYo.GenshinImpact';
      case 'asphalt9':
        return 'com.gameloft.android.ANMP.GloftA9HM';
      case 'dream11':
        return 'com.app.dream11Pro';
      case 'mpl':
        return 'com.mpl.androidapp';
      case 'winzo':
        return 'com.winzo.winzogames';
      case 'chesscom':
        return 'com.chess';
      case 'steam':
        return 'com.valvesoftware.android.steam.community';
      case 'epicgames':
        return 'com.epicgames.portal';
      case 'xbox':
        return 'com.microsoft.xboxone.smartglass';
      case 'playstation':
        return 'com.scee.psxandroid';
      case 'riotmobile':
        return 'com.riotgames.mobile.leagueconnect';
      case 'fortnite':
        return 'com.epicgames.fortnite';
      case 'truecaller':
        return 'com.truecaller';
      case 'myjio':
        return 'com.jio.myjio';
      case 'airtelthanks':
        return 'com.myairtelapp';
      case 'viselfcare':
        return 'com.mventus.selfcare.activity';
      case 'filesbygoogle':
      case 'googlefiles':
        return 'com.google.android.apps.nbu.files';
      case 'calculator':
        return 'com.google.android.calculator';
      case 'clock':
        return 'com.google.android.deskclock';
      case 'contacts':
        return 'com.google.android.contacts';
      case 'messages':
        return 'com.google.android.apps.messaging';
      case 'phone':
        return 'com.google.android.dialer';
      case 'camera':
        return 'com.google.android.GoogleCamera';
      case 'gallery':
        return 'com.google.android.apps.photos';
      case 'settings':
        return 'com.android.settings';
      case 'playstore':
        return 'com.android.vending';
      case 'youtubekids':
        return 'com.google.android.apps.youtube.kids';
      case 'familylink':
        return 'com.google.android.apps.kids.familylink';
      case 'linkedinlearning':
        return 'com.linkedin.android.learning';
      case 'udemy':
        return 'com.udemy.android';
      case 'coursera':
        return 'org.coursera.android';
      case 'khanacademy':
        return 'org.khanacademy.android';
      case 'duolingo':
        return 'com.duolingo';
      case 'byjus':
        return 'com.byjus.thelearningapp';
      case 'unacademy':
        return 'com.unacademyapp';
      default:
        return null;
    }
  }
}
