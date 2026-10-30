"""/admin - admin panel, admin role only. Route shell owned by Dev C (screens live in admin/)."""

import from ...components.shared.RoleGuard { RoleGuard }
import from ...components.shared.AccountBar { AccountBar }
import from ...admin.AdminApp { AdminApp }

def:pub AdminPage -> JsxPage {
    <RoleGuard role="admin" next="/admin">
        <AccountBar />
        <AdminApp />
    </RoleGuard>
}
