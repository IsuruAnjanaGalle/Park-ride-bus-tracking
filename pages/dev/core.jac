"""/dev/core - Dev A's core console: one button per walker, the JSON it returns, MOCK toggle, Reset."""

import from ...dev.CoreConsole { CoreConsole }

def:pub CoreConsolePage -> JsxPage {
    return <CoreConsole />;
}
