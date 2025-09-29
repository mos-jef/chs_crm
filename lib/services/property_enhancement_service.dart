// lib/services/property_enhancement_service.dart
import 'package:chs_crm/models/property_file.dart';

class PropertyEnhancementService {
  /// Enhance a property with Zillow URL and county information
  static PropertyFile enhanceProperty(PropertyFile property) {
    final zillowUrl = _generateZillowUrl(property);
    final county = _getCountyFromZip(property.zipCode);

    // Create enhanced property with Zillow URL
    final enhancedProperty = property.copyWith(
      zillowUrl: zillowUrl,
      updatedAt: DateTime.now(),
    );

    // Add county as a note if we found one
    if (county != null) {
      final countyNote = Note(
        subject: 'County',
        content: '$county County, Oregon',
        createdAt: DateTime.now(),
      );

      // Check if county note already exists
      final hasCountyNote = enhancedProperty.notes.any(
        (note) => note.subject == 'County',
      );

      if (!hasCountyNote) {
        return enhancedProperty.copyWith(
          notes: [...enhancedProperty.notes, countyNote],
          updatedAt: DateTime.now(),
        );
      }
    }

    return enhancedProperty;
  }

  /// Generate Zillow URL from property address components
  static String? _generateZillowUrl(PropertyFile property) {
    if (property.address.isEmpty ||
        property.city.isEmpty ||
        property.state.isEmpty ||
        property.zipCode.isEmpty) {
      return null;
    }

    // Clean and format address components
    final cleanAddress = property.address
        .replaceAll(
            RegExp(r'[^\w\s]'), '') // Remove special chars except spaces
        .replaceAll(RegExp(r'\s+'), '-'); // Replace spaces with hyphens

    final cleanCity = property.city
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), '-');

    final cleanState = property.state.toUpperCase();
    final cleanZip = property.zipCode;

    return 'https://www.zillow.com/homes/$cleanAddress-$cleanCity-$cleanState-$cleanZip\_rb/';
  }

  /// Get county from Oregon ZIP code
  static String? _getCountyFromZip(String zipCode) {
    return _oregonZipToCounty[zipCode];
  }

  /// Oregon ZIP code to county mapping (deduplicated, one county per ZIP)
  static const Map<String, String> _oregonZipToCounty = {
    // Baker County
    '97814': 'Baker', '97833': 'Baker', '97834': 'Baker',
    '97840': 'Baker', '97870': 'Baker', '97877': 'Baker',
    '97884': 'Baker', '97907': 'Baker',

    // Benton County
    '97324': 'Benton', '97326': 'Benton', '97330': 'Benton',
    '97331': 'Benton', '97333': 'Benton', '97339': 'Benton',
    '97370': 'Benton', '97456': 'Benton',

    // Clackamas County
    '97004': 'Clackamas', '97009': 'Clackamas', '97013': 'Clackamas',
    '97015': 'Clackamas', '97017': 'Clackamas', '97022': 'Clackamas',
    '97023': 'Clackamas', '97027': 'Clackamas', '97028': 'Clackamas',
    '97034': 'Clackamas', '97035': 'Clackamas', '97038': 'Clackamas',
    '97042': 'Clackamas', '97045': 'Clackamas', '97049': 'Clackamas',
    '97055': 'Clackamas', '97067': 'Clackamas', '97068': 'Clackamas',
    '97070': 'Clackamas', '97086': 'Clackamas', '97089': 'Clackamas',
    '97222': 'Clackamas', '97267': 'Clackamas',

    // Clatsop County
    '97103': 'Clatsop', '97110': 'Clatsop', '97121': 'Clatsop',
    '97138': 'Clatsop', '97146': 'Clatsop',

    // Columbia County
    '97016': 'Columbia', '97018': 'Columbia', '97048': 'Columbia',
    '97051': 'Columbia', '97056': 'Columbia',

    // Coos County
    '97411': 'Coos', '97414': 'Coos', '97420': 'Coos',
    '97423': 'Coos', '97449': 'Coos', '97458': 'Coos',
    '97459': 'Coos', '97466': 'Coos',

    // Crook County
    '97751': 'Crook', '97752': 'Crook', '97753': 'Crook',
    '97754': 'Crook',

    // Curry County
    '97406': 'Curry', '97415': 'Curry', '97444': 'Curry',
    '97450': 'Curry', '97465': 'Curry',

    // Deschutes County
    '97701': 'Deschutes', '97702': 'Deschutes', '97703': 'Deschutes',
    '97707': 'Deschutes', '97739': 'Deschutes', '97759': 'Deschutes',

    // Douglas County
    '97417': 'Douglas', '97429': 'Douglas', '97435': 'Douglas',
    '97436': 'Douglas', '97441': 'Douglas', '97442': 'Douglas',
    '97443': 'Douglas', '97447': 'Douglas', '97457': 'Douglas',
    '97462': 'Douglas', '97467': 'Douglas', '97469': 'Douglas',
    '97470': 'Douglas', '97471': 'Douglas', '97479': 'Douglas',
    '97486': 'Douglas', '97495': 'Douglas',
    '97496': 'Douglas', '97499': 'Douglas',

    // Gilliam County
    '97812': 'Gilliam', '97823': 'Gilliam', '97861': 'Gilliam',

    // Grant County
    '97820': 'Grant', '97825': 'Grant', '97845': 'Grant',
    '97848': 'Grant', '97856': 'Grant', '97864': 'Grant',
    '97865': 'Grant', '97869': 'Grant', '97873': 'Grant',

    // Harney County
    '97720': 'Harney', '97738': 'Harney', '97758': 'Harney',
    '97904': 'Harney',

    // Hood River County
    '97014': 'Hood River', '97031': 'Hood River',
    '97041': 'Hood River',
    

    // Jackson County
    '97501': 'Jackson', '97502': 'Jackson', '97503': 'Jackson',
    '97504': 'Jackson', '97520': 'Jackson', '97522': 'Jackson',
    '97524': 'Jackson', '97525': 'Jackson', '97530': 'Jackson',
    '97535': 'Jackson', '97536': 'Jackson', '97537': 'Jackson',
    '97539': 'Jackson', '97540': 'Jackson',

    // Jefferson County
    '97730': 'Jefferson', '97734': 'Jefferson',
    '97741': 'Jefferson', '97760': 'Jefferson',

    // Josephine County
    '97523': 'Josephine', '97526': 'Josephine', '97527': 'Josephine',
    '97531': 'Josephine', '97532': 'Josephine', '97534': 'Josephine',
    '97538': 'Josephine', '97543': 'Josephine', '97544': 'Josephine',

    // Klamath County
    '97601': 'Klamath', '97603': 'Klamath', '97621': 'Klamath',
    '97623': 'Klamath', '97624': 'Klamath', '97625': 'Klamath',
    '97627': 'Klamath', '97632': 'Klamath', '97633': 'Klamath',
    '97634': 'Klamath', '97639': 'Klamath',

    // Lake County
    '97630': 'Lake', '97635': 'Lake', '97636': 'Lake',
    '97638': 'Lake', '97640': 'Lake',

    // Lane County
    '97401': 'Lane', '97402': 'Lane', '97403': 'Lane',
    '97404': 'Lane', '97405': 'Lane', '97408': 'Lane',
    '97412': 'Lane', '97413': 'Lane', '97419': 'Lane',
    '97424': 'Lane', '97426': 'Lane', '97430': 'Lane',
    '97431': 'Lane', '97434': 'Lane', '97437': 'Lane',
    '97438': 'Lane', '97439': 'Lane', '97446': 'Lane',
    '97448': 'Lane', '97451': 'Lane', '97452': 'Lane',
    '97453': 'Lane', '97454': 'Lane', '97455': 'Lane',
    '97461': 'Lane', '97463': 'Lane', '97477': 'Lane',
    '97478': 'Lane', '97480': 'Lane', '97487': 'Lane',
    '97488': 'Lane', '97489': 'Lane', '97490': 'Lane',
    '97492': 'Lane', '97493': 'Lane',

    // Lincoln County
    '97341': 'Lincoln', '97343': 'Lincoln', '97364': 'Lincoln',
    '97365': 'Lincoln', '97366': 'Lincoln', '97367': 'Lincoln',
    '97368': 'Lincoln', '97376': 'Lincoln', '97388': 'Lincoln',
    '97391': 'Lincoln', '97394': 'Lincoln', '97498': 'Lincoln',

    // Linn County
    '97321': 'Linn', '97322': 'Linn', '97327': 'Linn',
    '97348': 'Linn', '97355': 'Linn', '97358': 'Linn',
    '97360': 'Linn', '97374': 'Linn', '97377': 'Linn',
    '97386': 'Linn', '97389': 'Linn',

    // Malheur County
    '97901': 'Malheur', '97906': 'Malheur', '97909': 'Malheur',
    '97910': 'Malheur', '97911': 'Malheur', '97913': 'Malheur',
    '97914': 'Malheur', '97918': 'Malheur',

    // Marion County
    '97002': 'Marion', '97020': 'Marion', '97026': 'Marion',
    '97032': 'Marion', '97071': 'Marion',
    '97137': 'Marion', '97301': 'Marion', '97302': 'Marion',
    '97303': 'Marion', '97305': 'Marion', '97306': 'Marion',
    '97310': 'Marion', '97311': 'Marion', '97312': 'Marion',
    '97314': 'Marion', '97317': 'Marion', '97325': 'Marion',
    '97350': 'Marion', '97352': 'Marion', '97362': 'Marion',
    '97375': 'Marion', '97381': 'Marion', '97383': 'Marion',
    '97385': 'Marion', '97392': 'Marion',

    // Morrow County
    '97818': 'Morrow', '97836': 'Morrow',
    '97843': 'Morrow', '97844': 'Morrow',

    // Multnomah County
    '97019': 'Multnomah', '97024': 'Multnomah', '97030': 'Multnomah',
    '97060': 'Multnomah', '97080': 'Multnomah',
    '97201': 'Multnomah', '97202': 'Multnomah', '97203': 'Multnomah',
    '97204': 'Multnomah', '97205': 'Multnomah', '97206': 'Multnomah',
    '97209': 'Multnomah', '97210': 'Multnomah', '97211': 'Multnomah',
    '97212': 'Multnomah', '97213': 'Multnomah', '97214': 'Multnomah',
    '97215': 'Multnomah', '97216': 'Multnomah', '97217': 'Multnomah',
    '97218': 'Multnomah', '97219': 'Multnomah', '97220': 'Multnomah',
    '97221': 'Multnomah', '97227': 'Multnomah', '97230': 'Multnomah',
    '97231': 'Multnomah', '97232': 'Multnomah', '97233': 'Multnomah',
    '97236': 'Multnomah', '97239': 'Multnomah', '97250': 'Multnomah',
    '97251': 'Multnomah', '97252': 'Multnomah', '97253': 'Multnomah',
    '97254': 'Multnomah', '97256': 'Multnomah', '97258': 'Multnomah',
    '97266': 'Multnomah',

    // Polk County
    '97304': 'Polk', '97338': 'Polk', '97344': 'Polk',
    '97347': 'Polk', '97351': 'Polk', '97361': 'Polk',
    '97371': 'Polk', 

    // Sherman County
    '97029': 'Sherman', '97039': 'Sherman', '97065': 'Sherman',

    // Tillamook County
    '97112': 'Tillamook', '97122': 'Tillamook', '97131': 'Tillamook',
    '97136': 'Tillamook', '97141': 'Tillamook', '97143': 'Tillamook',
    '97144': 'Tillamook',

    // Umatilla County
    '97801': 'Umatilla', '97810': 'Umatilla', '97813': 'Umatilla',
    '97826': 'Umatilla', '97835': 'Umatilla', '97838': 'Umatilla',
    '97862': 'Umatilla', '97875': 'Umatilla', '97882': 'Umatilla',
    '97886': 'Umatilla',

    // Union County
    '97824': 'Union', '97827': 'Union', '97841': 'Union',
    '97850': 'Union', '97867': 'Union', '97883': 'Union',

    // Wallowa County
    '97828': 'Wallowa', '97842': 'Wallowa', '97846': 'Wallowa',
    '97857': 'Wallowa', '97885': 'Wallowa',

    // Wasco County
    '97021': 'Wasco', '97037': 'Wasco', '97040': 'Wasco',
    '97058': 'Wasco', '97063': 'Wasco',

    // Washington County
    '97003': 'Washington', '97005': 'Washington', '97006': 'Washington',
    '97007': 'Washington', '97008': 'Washington', '97062': 'Washington',
    '97077': 'Washington', '97078': 'Washington', '97079': 'Washington',
    '97106': 'Washington', '97109': 'Washington', '97113': 'Washington',
    '97116': 'Washington', '97119': 'Washington', '97123': 'Washington',
    '97124': 'Washington', '97125': 'Washington', '97129': 'Washington',
    '97133': 'Washington', '97140': 'Washington',
    '97223': 'Washington', '97224': 'Washington', '97225': 'Washington',
    '97229': 'Washington',

    // Wheeler County
    '97750': 'Wheeler', '97830': 'Wheeler', '97874': 'Wheeler',

    // Yamhill County
    '97101': 'Yamhill', '97111': 'Yamhill', '97114': 'Yamhill',
    '97115': 'Yamhill', '97127': 'Yamhill', '97128': 'Yamhill',
    '97132': 'Yamhill', '97148': 'Yamhill',
    '97378': 'Yamhill', '97396': 'Yamhill',
  };


  /// Batch enhance multiple properties
  static List<PropertyFile> batchEnhanceProperties(
      List<PropertyFile> properties) {
    return properties.map((property) => enhanceProperty(property)).toList();
  }

  /// Check if property needs enhancement
  static bool needsEnhancement(PropertyFile property) {
    final needsZillow =
        property.zillowUrl == null || property.zillowUrl!.isEmpty;
    final needsCounty = !property.notes.any((note) => note.subject == 'County');
    return needsZillow || needsCounty;
  }
}
