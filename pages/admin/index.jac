"""/admin - admin panel, admin role only. Route shell owned by Dev C (screens live in admin/)."""

import from ...components.shared.RoleGuard { RoleGuard }
import from ...admin.AdminApp { AdminApp }

def:pub AdminPage -> JsxPage {
    return <RoleGuard role="admin" next="/admin">
        <AdminApp />
    </RoleGuard>;
}
