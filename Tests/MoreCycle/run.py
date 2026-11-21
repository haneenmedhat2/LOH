"""Exercise account APIs and state with mocked HTTP, without live mutations."""
from pathlib import Path
import subprocess, tempfile
root = Path(__file__).resolve().parents[2]
with tempfile.TemporaryDirectory(prefix='loh-account-tests-') as directory:
    temp = Path(directory)
    executable = temp / 'AccountTests'
    paths = ['LOH/Networking/HandelRequest/Endpoint.swift',
             'LOH/Networking/HandelRequest/Requestable.swift',
             'LOH/Networking/HandelRequest/RequestHeader.swift',
             'LOH/Networking/HandelRequest/Typealias.swift',
             'LOH/Networking/NetworkConstants.swift',
             'LOH/Networking/HandleResponse/ResponseDecoder.swift',
             'LOH/Networking/HandleResponse/ResponseError.swift',
             'LOH/Shared/Localization/Language.swift',
             'LOH/Networking/LOHAPI/APIClient.swift', 'LOH/Networking/Endpoints/AuthEndpoints.swift',
             'LOH/Networking/Endpoints/AccountEndpoints.swift',
             'LOH/Networking/Endpoints/NotificationEndpoints.swift',
             'LOH/Networking/Endpoints/PaymentEndpoints.swift',
             'LOH/Networking/Endpoints/SupportTicketEndpoints.swift',
             'LOH/Networking/LOHAPI/AuthService.swift',
             'LOH/Networking/LOHAPI/AuthSession.swift', 'LOH/Networking/LOHAPI/AccountService.swift',
             'LOH/Networking/LOHAPI/PaymentService.swift', 'LOH/Shared/Foundation/User.swift',
             'LOH/Networking/LOHAPI/NotificationService.swift',
             'LOH/Networking/LOHAPI/SupportTicketService.swift',
             'Tests/MoreCycle/SupportTicketTests.swift',
             'LOH/Networking/LOHAPI/AccountSettingsService.swift',
             'LOH/App/MoreCycle/AllMoreViews/Settings/Security/Model/AccountSecurityModel.swift',
             'LOH/App/NotificationView/Model/NotificationsListData.swift',
             'LOH/App/NotificationView/ViewModel/NotificationsViewModel.swift',
             'LOH/App/MoreCycle/Shared/Model/AccountValidation.swift',
             'LOH/App/MoreCycle/Shared/ViewModel/AccountRequestController.swift',
             'LOH/App/MoreCycle/MoreView/Model/MoreUserStats.swift',
             'LOH/App/MoreCycle/MoreView/Model/MoreCashbackBalance.swift',
             'LOH/App/MoreCycle/MoreView/ViewModel/MoreViewModel.swift',
             'LOH/Coordinator/TabBarCoordinator/MoreCoordinator/MoreAccountStore.swift',
             'Tests/MoreCycle/AccountModelTests.swift', 'Tests/MoreCycle/PaymentTests.swift',
             'Tests/MoreCycle/MoreStatsTests.swift',
             'Tests/MoreCycle/MoreCashbackTests.swift',
             'Tests/MoreCycle/ProfileBirthDateTests.swift',
             'Tests/MoreCycle/NotificationTests.swift',
             'Tests/MoreCycle/AccountSettingsTests.swift',
             'Tests/MoreCycle/AccountLifecycleTests.swift',
             'Tests/MoreCycle/FeatureViewModelTests.swift']
    features = root / 'LOH/App/MoreCycle/AllMoreViews'
    for feature in ['Profile', 'Payments', 'Tickets', 'Help/Join', 'Documents',
                    'Settings/Notifications', 'Settings/Language', 'Settings/ChangePassword', 'Settings/DeleteAccount']:
        for source in sorted((features / feature).rglob('*.swift')):
            if source.parent.name in ('Model', 'ViewModel'):
                paths.append(str(source.relative_to(root)))
    # Compile the actual feature code with a host UIImage stub for upload tests.
    sources = []
    for path in paths:
        source = root / path
        if 'import UIKit' in source.read_text():
            adapted = temp / source.name
            adapted.write_text(source.read_text().replace('import UIKit', 'import Foundation'))
            sources.append(str(adapted))
        else:
            sources.append(str(source))
    subprocess.run(['xcrun', 'swiftc', '-D', 'DEBUG', '-swift-version', '5', '-module-cache-path', str(temp/'modules'),
                    *sources, '-o', str(executable)], check=True)
    result = subprocess.run([str(executable)], capture_output=True, text=True)
    if result.returncode:
        print(result.stdout)
        print(result.stderr)
        result.check_returncode()
    output = result.stdout
    assert 'URL:: https://example.invalid/api/profile' in output
    assert 'URL:: https://example.invalid/api/user-stats' in output
    assert 'URL:: https://example.invalid/api/update-profile?_method=put' in output
    assert 'HTTP 200' in output and 'HTTP 422' in output
    assert 'Saved profile' in output and 'Profile rejected' in output
    assert '"Authorization" : "Bearer test"' in output and '[REDACTED]' not in output
    assert '"card_number" : "4242424242424242"' in output
    assert '"cvv" : "123"' in output
    assert 'URL:: https://example.invalid/api/add-payment-cards' in output
    assert 'URL:: https://example.invalid/api/payment-cards/42/set-default?_method=patch' in output
    for endpoint in ['notifications?filter=', 'count-notifications', 'notification-settings',
                     'switch-notify', 'delete-notification/', 'delete-notifications']:
        assert 'URL:: https://example.invalid/api/' + endpoint in output
    for endpoint in ['update-password?_method=patch', 'change-lang?lang=', 'security-privacy', 'privacy', 'terms', 'about', 'join-us',
                     'delete-account', 'sign-out']:
        assert 'URL:: https://example.invalid/api/' + endpoint in output
    assert '"old_password" : "current123"' in output
    print(output)
    print('PASS: profile request/response console logging, HTTP statuses, visible Authorization and add-card details')
