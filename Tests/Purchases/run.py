from pathlib import Path
import subprocess, tempfile, re

root = Path(__file__).resolve().parents[2]
with tempfile.TemporaryDirectory(prefix='loh-purchases-tests-') as temp:
    executable = str(Path(temp) / 'PurchasesTests')
    sources = [
        'LOH/Networking/HandelRequest/Endpoint.swift',
        'LOH/Networking/HandelRequest/Requestable.swift',
        'LOH/Networking/HandelRequest/RequestHeader.swift',
        'LOH/Networking/HandelRequest/Typealias.swift',
        'LOH/Networking/NetworkConstants.swift',
        'LOH/Networking/HandleResponse/ResponseDecoder.swift',
        'LOH/Networking/HandleResponse/ResponseError.swift',
        'LOH/Shared/Localization/Language.swift',
        'LOH/Networking/LOHAPI/APIClient.swift',
        'LOH/Networking/Endpoints/PurchaseEndpoints.swift',
        'LOH/Networking/LOHAPI/PurchaseService.swift',
        'LOH/App/PurchasesCycle/Purchases/Model/PurchaseCoupon.swift',
        'LOH/App/PurchasesCycle/Purchases/ViewModel/PurchasesViewModel.swift',
        'LOH/App/PurchasesCycle/PurchaseDetails/Model/PurchaseDetailData.swift',
        'LOH/App/PurchasesCycle/PurchaseDetails/Model/PurchaseDetail.swift',
        'LOH/App/PurchasesCycle/PurchaseDetails/Model/PurchaseVoucherCode.swift',
        'LOH/App/PurchasesCycle/PurchaseDetails/ViewModel/PurchaseDetailViewModel.swift',
        'LOH/App/PurchasesCycle/PurchaseRating/Model/PurchaseRatingTag.swift',
        'LOH/App/PurchasesCycle/PurchaseRating/ViewModel/PurchaseRatingViewModel.swift',
        'LOH/App/PurchasesCycle/PurchaseCode/Model/PurchaseQRCode.swift',
        'Tests/Purchases/PurchasesTests.swift',
    ]
    subprocess.run(['xcrun', 'swiftc', '-swift-version', '5', '-module-cache-path', str(Path(temp) / 'modules'),
        *[str(root / p) for p in sources], '-o', executable], check=True)
    subprocess.run([executable], check=True)

source = '\n'.join(p.read_text() for p in (root/'LOH/App/PurchasesCycle').rglob('*.swift'))
keys = set(re.findall(r'homeText\("([^"]+)"\)', source))
keys |= {'purchaseTabReady', 'purchaseTabUsed', 'purchaseTabExpired', 'all', 'offerDetails',
         'usedDate', 'expiryDate', 'purchaseDate', 'orderNumber', 'purchasePrice', 'purchaseCodeMissing'}
for language in ['ar', 'en']:
    text = (root/f'LOH/Shared/Localization/Strings/{language}.lproj/Localizable.strings').read_text()
    available = set(re.findall(r'^"home\.([^"]+)"', text, re.M))
    assert keys <= available, (language, keys - available)
    assert '"purchases.openVoucher"' in text
print('PASS: Arabic and English purchase labels')
